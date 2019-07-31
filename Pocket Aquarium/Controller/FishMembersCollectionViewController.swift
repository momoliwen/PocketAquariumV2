//
//  FIshMembersCollectionViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 27/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

//private let reuseIdentifier = "Cell"

class FishMembersCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    let fishTypeHeadView = "fishTypeHeader"
    let fishMemberCell = "fishMemberCollectionCell"
    
    var thisTank : FishTank?{
        didSet{
            if let tank = thisTank {
                tankMinTemp = thisTank?.desiredMinTemp
                tankMaxTemp = thisTank?.desiredMaxTemp
                tankMinpH  = thisTank?.desiredMinpH
                tankMaxpH = thisTank?.desiredMaxpH
                //set firebase reference for this tank
                self.currentTankRef = userRef.child("tanks").child("\(tank.tankId)")
                self.fishMembersRef = currentTankRef!.child("fishMembers")
            }
        }
    }
    var tankMinTemp,tankMaxTemp : Int?
    var tankMinpH, tankMaxpH: Double?
    
    private let itemsPerRow : CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    
    //firebase reference
    var userId = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userId!)
    lazy var fishRef = userRef.child("fishes")
    var currentTankRef : DatabaseReference?
    var fishMembersRef : DatabaseReference?
    var fishRefHandler: DatabaseHandle?
    
    var saltFishList = [Fish]() {
        didSet{
            let saltDict = ["Saltwater": ["typeImage": #imageLiteral(resourceName: "SaltWaterType@") , "title": "Saltwater Fish" , "fishList": saltFishList]]
            self.categoryList?[0] = saltDict
        }
    }
    
    var freshFishList  = [Fish](){
        didSet{
            let freshDict = ["Freshwater": ["typeImage": #imageLiteral(resourceName: "FreshWaterType") , "title": "Freshwater Fish" , "fishList": freshFishList]]
            self.categoryList?[1] = freshDict
         }
    }
    
    var plantsFish = [Fish](){
        didSet{
            let plantDict = ["Plants": ["typeImage": #imageLiteral(resourceName: "SeaPlants") , "title": "Plants" , "fishList": plantsFish]]
            self.categoryList?[2] = plantDict
        }
    }
    
    //fish item on firebase
    var fishMemberDict : [String : String]?
    struct FishCategoy {
        var typeImage : UIImage
        var title : String
        var fishList : [Fish]
    }
    var categoryList : [[String:Any]]?
    var selectedIndexPath : IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categoryList = [[:],[:],[:]]
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressOnCell(gestureReconizer:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(longPressGesture)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeSaltFishValue()
        observeFreshFishValue()
        observePlantsValue()
       
       
    }
    
    //firebase download saltwater fish
    func observeSaltFishValue(){
        let fishQuery = fishRef.queryOrdered(byChild: "fishType").queryEqual(toValue: "Saltwater")
        fishQuery.observeSingleEvent(of: .value, with: { (snapshot)-> Void in
            print(snapshot)
            for child in snapshot.children {
                print(child)
                if let thisFish = Fish(snapshot: child as! DataSnapshot , uid: self.userId!){
                    self.saltFishList.append(thisFish)
                }
            }
            print("saltfishList count is : \(self.saltFishList.count)")
            
            var value = self.categoryList?[0]["Saltwater"] as? [String : Any]
            value?["fishList"] = self.saltFishList
            self.collectionView?.reloadData()
            self.collectionView?.reloadSections([0])
        })
    }
    
    //firebase download freshwater fish
    func observeFreshFishValue(){
        let fishQuery = fishRef.queryOrdered(byChild: "fishType").queryEqual(toValue: "Freshwater")
        fishQuery.observeSingleEvent(of: .value, with: { (snapshot)-> Void in
            print(snapshot)
            for child in snapshot.children {
                print(child)
                if let thisFish = Fish(snapshot: child as! DataSnapshot , uid: self.userId!){
                    
                    self.freshFishList.append(thisFish)
                }
            }
            print("saltfishList count is : \(self.freshFishList.count)")
            
            var value = self.categoryList?[1]["Freshwater"] as? [String : Any]
            value?["fishList"] = self.freshFishList
            self.collectionView?.reloadData()
            self.collectionView?.reloadSections([1])
        })
    }
    
    //firebase download fish of plants
    func observePlantsValue(){
        let fishQuery = fishRef.queryOrdered(byChild: "fishType").queryEqual(toValue: "Plants")
        fishQuery.observeSingleEvent(of: .value, with: { (snapshot)-> Void in
            print(snapshot)
            for child in snapshot.children {
                print(child)
                if let thisFish = Fish(snapshot: child as! DataSnapshot , uid: self.userId!){
                    self.plantsFish.append(thisFish)
                }
            }
            print("saltfishList count is : \(self.plantsFish.count)")
            
            var value = self.categoryList?[2]["Plants"] as? [String : Any]
            value?["fishList"] = self.plantsFish
            self.collectionView?.reloadData()
            self.collectionView?.reloadSections([2])
        })
    }
    
    //MARK: UIcollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * ( self.itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    // MARK: UICollectionViewDataSource
    //section number
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let dataSource = categoryList{
              return dataSource.count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let thisFishTypeList = categoryList?[section]
        for (key, value) in thisFishTypeList ?? [:]{
            let saltFist = value  as? [String:Any]
            for (key,value) in saltFist ?? [:] {
                if key == "fishList" {
                    let thisList = value as? [Fish]
                    return thisList?.count ?? 0
                    print("\(thisList?.count)")
                }
            }
        }
        return 0
    }
    
    //configure fish member cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.fishMemberCell, for: indexPath) as! AddFishToTankCollectionViewCell
            print("Start cell for row at..")
        let thisFishTypeList = categoryList?[indexPath.section]
        for (key, value) in thisFishTypeList ?? [:]{
             let fishDict = value  as? [String:Any]
            for (key,value) in fishDict ?? [:] {
                let fishList = value as? [Fish]
                if let fish = fishList?[indexPath.item]{
                    cell.fishIconImage.roundedImageView()
                    cell.fishIconImage.image = fish.fishIcon.image
                    cell.fishNameLabel.text  = fish.fishName
                    cell.desiredTempLabel.text = "\(fish.fishMinTemp)℃ - \(fish.fishMaxTemp)℃"
                    cell.desiredpH.text = "\(fish.fishMinpH) - \(fish.fishMaxpH)"
                    //cell.alpha = CGFloat(0.2)
                    self.calculateOptimalMatch(minTemp: fish.fishMinTemp, maxTemp: fish.fishMaxTemp, minPh: fish.fishMinpH, maxPh: fish.fishMaxpH, tempLabel: cell.desiredTempLabel, phLabel: cell.desiredpH)
                    return cell
                }
            }
        }
        return cell
    }
    
    //MARK: calculat the range of temp and ph value
    func calculateOptimalMatch(minTemp:Int, maxTemp:Int, minPh:Double, maxPh : Double, tempLabel : UILabel, phLabel : UILabel){
        if minTemp < self.tankMinTemp ?? 0 ||
            maxTemp > self.tankMaxTemp ?? 0 {
            tempLabel.textColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        } else{
             tempLabel.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        }
        if minPh < self.tankMinpH ?? 0 ||
            maxPh > self.tankMaxpH ?? 0 {
            phLabel.textColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        } else{
            phLabel.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        }

    }
    
    //Section view header
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "fishTypeHeader", for: indexPath) as! FishCollectionReusableHeaderView
        
        let thisCategory = self.categoryList?[indexPath.section]
            print(thisCategory)
            let values = thisCategory
        for (key,value) in values ?? [:] {
                let thisDict = value as? [String : Any]
                for(thisKey, thisValue) in thisDict ?? [:]{
                    if thisKey == "typeImage"{
                         headerView.categoryImageView.image = thisValue as? UIImage
                    }
                    if thisKey == "title"{
                        headerView.categoryLabel.text = thisValue as? String
                    }
                     print("configure header view ok")
                }
            }
         return headerView
    }
    
    //long press on cell --> Reference
    @objc func longPressOnCell(gestureReconizer : UILongPressGestureRecognizer){
        if gestureReconizer.state != UIGestureRecognizerState.ended{
            return
        }
        
        let pressPoint = gestureReconizer.location(in: self.collectionView)
        let selectIndexPath = self.collectionView?.indexPathForItem(at: pressPoint)
        if let indexPath = selectIndexPath {
            var cell = self.collectionView?.cellForItem(at: indexPath)
            print(indexPath.row)
            self.selectedIndexPath = indexPath
            self.addToTanksAlertAction()
        }else{
            print("could not find index path")
        }
    }
    
    //MARK: add fish to tank action after long press the fish cell
    func addToTanksAlertAction(){
        let alert = UIAlertController(title: "Add Fish to the fishtank",
                                      message: "Enter the fish number you have put in",
                                      preferredStyle: .alert)
        
        alert.addTextField { textFishNumber in
            textFishNumber.placeholder =
            "Fish number should be greater than 0"
        }
       
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            let fishNumberField = alert.textFields![0]
            guard let fishNumber = fishNumberField.text else{
                self.displayErrorMessage(message: "Input Error", title: "Input Error")
                return
            }
            if let number = Int(fishNumber) {
                if let index = self.selectedIndexPath {
                    if let fish = self.findTheFishInList(indexPath: index), number > 0 {
                        fish.fishNumber = number
                        
                        let cell = self.collectionView?.cellForItem(at: index) as! AddFishToTankCollectionViewCell
                        cell.hasFishNumberLabel.text = "\(number)"
                        
                        let thisFishRef = self.fishMembersRef?.child("\(fish.fishId)")
                         print("save to the fishmembers node  ...")
                         thisFishRef!.setValue(fish.toFishMemberObject())
                         self.autoDismissAlert(message:  "Completed to add \(number) of \(fish.fishName)", title: "Success")
                        }
                    else{
                        self.displayErrorMessage(message: "Input number should greater than 0", title: "Error")
                    }
                }
            }else{
                self.displayErrorMessage(message: "Input error", title: "You are only allowed to enter the number")
            }

        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    

    
    //MARK: error handler
    func displayErrorMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK - find the fish in list by fish type 
    func findTheFishInList(indexPath : IndexPath) -> Fish?{
        let thisFishTypeList = categoryList?[indexPath.section]
        for (key, value) in thisFishTypeList ?? [:]{
            let fishDict = value  as? [String:Any]
            for (key,value) in fishDict ?? [:] {
                if key == "fishList" {
                    let thisFishList = value as? [Fish]
                    let thisFish = thisFishList?[indexPath.item]
                    return thisFish
                }
            }
        }
        return nil
    }
}
