//
//  CurrentFishListViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 28/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class CurrentFishListViewController: UITableViewController, UISearchResultsUpdating {
    
    //firebase reference
    var userId = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userId!)
    lazy var userFishRef = self.userRef.child("fishes")

    var fishList : [Fish]? {
        didSet{
            if let thisList = fishList {
                self.filterList = thisList
            }
        }
    }
    var selectFish : Fish?
    var fishMemberCell = "fishInTankCell"
    var totalCell = "totalFishMemberCell"
    var filterList = [Fish]()
    var selectIndex : IndexPath?
    
    var editFishNubmerDelegate : EditFishTankDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if selectFish != nil{
             observeFishChanged()
        }
    }
    
    func configureSearchController(){
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search fish"
        navigationItem.searchController = searchController
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return filterList.count
        }
        else{
            return 1
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            let fishCell = tableView.dequeueReusableCell(withIdentifier: fishMemberCell, for: indexPath) as! FishInTankTableViewCell
            let thisFish = filterList[indexPath.row]
            fishCell.fishIconImage.image = thisFish.fishIcon.image
            fishCell.fishIconImage.roundedImageView()
            fishCell.fishNameLabel.text = thisFish.fishName
            fishCell.fishTempRangeLabel.text = "Temp Range : \(thisFish.fishMinTemp)℃ - \(thisFish.fishMaxTemp)℃"
            fishCell.fishPhRangeLabel.text = "pH Range : \(thisFish.fishMinpH) - \(thisFish.fishMaxpH)"
            fishCell.aggressiveCosmosView.rating = Double(thisFish.fishRating)
            fishCell.aggressiveCosmosView.settings.updateOnTouch = false
            fishCell.fishNumberLabel.text = "\(thisFish.fishNumber)"
            return fishCell
        }
        else{
            let totalCell = tableView.dequeueReusableCell(withIdentifier: self.totalCell, for: indexPath) as! FishInTankTotalTableViewCell
            totalCell.fishTotalLabel.text = "\(self.filterList.count)"
            return totalCell
        }
    }
    

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0{
            return true
        }
        else{
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
               return 100
        }
        else{
            return 40
        }
     
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "FISH MEMBERS"
        }
        else{
            return "TOTAL FISH MEMBER"
        }
    }
    
    //Mark: configure table view header format
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 {
            let header = view as! UITableViewHeaderFooterView
            header.textLabel?.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
            header.textLabel?.font = UIFont(name: "Helvetica", size: 17)
            header.textLabel?.text = "FISH MEMBERS"
        }
        else{
            let header = view as! UITableViewHeaderFooterView
            header.textLabel?.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
            header.textLabel?.font = UIFont(name: "Helvetica", size: 17)
            header.textLabel?.text = "TOTAL FISH MEMBER"
        }
       
    }
    

    
    //MARK: -- delete fish from the tank
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let thisFish = self.filterList[indexPath.row]
            alertDeleteFishFromTank(index: indexPath, fish: thisFish)
            //self.fishList!.removeAll()
            //self.observeFishMembersInTank()
            //self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    //MARK: alert to delete the fish from the tank as well as change the fish number to 0
    func alertDeleteFishFromTank(index : IndexPath, fish: Fish){
        let alertController = UIAlertController(title: "Warning", message: "Do you really want to delete this fish from the tank? ", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "YES", style: .default) { (action:UIAlertAction) in
            let thisFishRef = fish.ref!
            print(thisFishRef)
            self.filterList.remove(at: index.row)
            self.tableView.deleteRows(at: [index], with: .fade)
            
             //update total cell
            let totalPath = IndexPath(row: 0, section: 1)
            self.tableView.reloadRows(at: [totalPath], with: .none)
        
            if let index = self.fishList?.index(where: {
                $0.fishId == fish.fishId
            }).flatMap({
                IndexPath(row: $0, section: 0)
            }){
                print("\(index)")
                self.fishList?.remove(at: index.row)
            }
            //1. firebase remove from tank . fishes
            thisFishRef.removeValue()
            print("firebase remove this fish from the tank ok")
            
            //2. firebase fish repository fish number change to 0
            self.userFishRef.child("\(fish.fishId)").updateChildValues([
                "fishNumber" :  0
                ])
        }
        let cancel = UIAlertAction(title: "NO", style: .cancel) { (action:UIAlertAction) in
            print("you have cancled this fish node")
        }
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Search updating delegate
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased(), searchText.count > 0 else{
            self.filterList = self.fishList!
            tableView.reloadData()
            return
        }
        
        self.filterList = fishList!.filter({(thisFish : Fish) -> Bool in
            return thisFish.fishName.lowercased().contains(searchText)
        })
        tableView.reloadData()
    }
    
    //MARK: - observe select fish value change, if change, replace the once one
    func observeFishChanged(){
        self.selectFish?.ref?.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
            print(snapshot)
            if let fish = Fish(snapshot: snapshot, uid: self.userId!){
                self.selectFish = fish
                self.tableView.reloadData()
            }
        })
    }
 
    //Redownload
    func observeFishMembersInTank(){
        let tankRef = userRef.child("tanks")
        let fishesRef = tankRef.child("fishMembers")
        fishesRef.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
            print(snapshot)
            for child in snapshot.children{
                if let thisFish = Fish(snapshot: child as! DataSnapshot, uid: self.userId!){
                    self.fishList?.append(thisFish)
                    print("reload fish ")
                }
            }
            self.filterList = self.fishList ?? [Fish]()
            //self.tableView.reloadData()
        })
    }

    //MARK: select fish cell to see detail
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            //self.selectIndex =  indexPath
            self.selectFish = filterList[indexPath.row]
            performSegue(withIdentifier: "seeDetailFromFishList", sender: self)
        }
    }
    
    //MARK: left swift the table cell can edit the fish number
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {
            (contestualAction, view, actionperformed : (Bool)-> ()) in
            self.editFishNumberAlert(theIndexPath: indexPath)
            actionperformed(true)
        }
        edit.image = #imageLiteral(resourceName: "editIcon")
        edit.backgroundColor = #colorLiteral(red: 0.9764705882, green: 0.8392156863, blue: 0.2862745098, alpha: 1)
        return UISwipeActionsConfiguration(actions: [edit])
    }
    
    //MARK: -Edit table view cell for the number
    func editFishNumberAlert(theIndexPath : IndexPath){
        let alert = UIAlertController(title: "Edit Fish number",
                                      message: "Enter the fish number you want edit",
                                      preferredStyle: .alert)
        alert.addTextField {
            textNumber in
            textNumber.placeholder = "Please enter a positive number"
        }
        let edit = UIAlertAction(title: "Edit", style: .default, handler: { (action) in
            let newNumber = alert.textFields![0]
            guard let newFishNumber = newNumber.text else{
                self.displayErrorMessage(message: "Input Error", title: "Invalid Input")
                return
            }
            if let theNumber = Int(newFishNumber), theNumber > 0 {
                let fish = self.filterList[theIndexPath.row]
                fish.fishNumber = theNumber
                //update table cell
                let fishTableCell = self.tableView.cellForRow(at: theIndexPath) as! FishInTankTableViewCell
                fishTableCell.fishNumberLabel.text = "\(theNumber)"
                
                //update collection view cell in tank detail
                if let tankDelegate = self.editFishNubmerDelegate {
                    tankDelegate.editFishNumberInList(thisFish: fish)
                }
                
                //update source fish list
                if let index = self.fishList!.index(where:{
                    $0.fishId == fish.fishId
                }).flatMap({
                    IndexPath(row: $0, section: 0)
                }){
                    let originalFish = self.fishList![index.row]
                    originalFish.fishNumber = fish.fishNumber
                }
                
                //update firebase of tank
                fish.ref!.updateChildValues([
                    "fishNumber" : theNumber
                ])
                
                //update fish repository
                self.userFishRef.child("\(fish.fishId)").updateChildValues([
                     "fishNumber" : theNumber
                ])
                
            
                //display success message
                self.autoDismissSuccessEditAlert(message: "Completed to edit the number of \(fish.fishName) to \(theNumber)", title: "Success")
    
            }
            else{
                self.displayErrorMessage(message: "Input Error", title: "Invalid Input")
                return
            }
        })
        let cancel = UIAlertAction(title: "NO", style: .cancel) { (action:UIAlertAction) in
            print("you have cancled this fish node")
        }
        alert.addAction(edit)
        alert.addAction(cancel)
        self.present(alert,animated: true, completion: nil)
    }
    
    //MARK: audo dismiss alert controller
    func autoDismissSuccessEditAlert(message:String, title:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert,animated: true, completion: nil)
        //change to desired number of seconds
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: error handler
    func displayErrorMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Navigation- go to see detail
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seeDetailFromFishList" {
            let destinationVc = segue.destination as! FishDetailViewController
            /*
            guard let cell = sender as? FishInTankTableViewCell,
            let indexPath = tableView.indexPath(for: cell) else{
                return
            }
            let indexRow = indexPath.row
            let fish = self.filterList[indexRow]*/
            destinationVc.selectedFish = self.selectFish!
        }
    }
}
