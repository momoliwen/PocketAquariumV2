//
//  FishRepositoryViewController.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class FishRepositoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, ShowFishDelegate{

    @IBOutlet weak var fishTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //data source
    var fishList : NSMutableArray
    var searchList : NSMutableArray
    var filterList : NSMutableArray
    var searchText: String?
    var selectedFish : Fish?
    
    //DB Reference
    private var fishRef = Database.database().reference().child("fishes")
    private var storageRef = Storage.storage().reference().child("images")
    
    //DB reference handler
    private var fishesRefHandler : DatabaseHandle?
    @IBAction func typeSegment(_ sender: UISegmentedControl) {
        let type = sender.selectedSegmentIndex
        if type == 0
        {
            observeFish()
        } else if type == 1 {
            observeFishByType(type: "Saltwater")
        } else if type == 2 {
            observeFishByType(type: "Freshwater")
        }else {
            observeFishByType(type: "Plants")
        }
    }
    
    //initializer
    required init?(coder aDecoder: NSCoder) {
        self.fishList = NSMutableArray()
        self.filterList = NSMutableArray()
        self.searchList = NSMutableArray()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fishTableView.delegate = self
        fishTableView.dataSource = self
        searchBar.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeFish()
    }
    
    //MARK: - Firebase observation: Retrieve fish data
    private func observeFish(){
        
        self.fishList.removeAllObjects()
        self.filterList.removeAllObjects()
        
        var firstFilter = NSMutableArray()
        var secondFilter = NSMutableArray()
        
        fishesRefHandler = self.fishRef.observe(.childAdded, with: {(snapshot)-> Void in
            print(snapshot)
            
            let fishData = snapshot.value as! Dictionary<String,AnyObject>
            let fishId = snapshot.key
            if let fishName = fishData["fishName"] as! String?,
                let fishIconName = fishData["fishIconName"] as! String?,
                let fishType = fishData["fishType"] as! String?,
                let fishMaxTemp = fishData["fishMaxTemp"] as! Int?,
                let fishMinTemp = fishData["fishMinTemp"] as! Int?,
                let fishMaxpH = fishData["fishMaxpH"] as! Double?,
                let fishMinpH = fishData["fishMinpH"] as! Double?,
                let fishNumber = fishData["fishNumber"] as! Int?,
                let fishRating = fishData["fishRating"] as! Int?,
                let fishPhoto = fishData["pictureURL"] as! [String: AnyObject]?{
                    var fishIconImg = UIImageView()
                    let photo = Array(fishPhoto.values)
            
                    //if the fish icon is import photo from user
                    if(fishIconName == "fish"){
                        let userID = Auth.auth().currentUser!.uid
                        print(userID)
                        let icon = fishData["iconURL"] as! NSDictionary
                        
                        for(key,url) in icon{
                            let imageKey = key as! String
                            let downloadURL = url  as! String
                            
                            //if local file exists, retrieve from local file
                            if ImageManager.localFileExists(fileName: imageKey) {
                                fishIconImg.image = ImageManager.retrieveImageData(fileName: imageKey)
                            }
                            else{
                                //download in memory if not exist in the memory
                                let thisImageRef = self.storageRef.child("\(userID)/\(imageKey)")
                                print(thisImageRef)
                                thisImageRef.getData(maxSize: 5 * 1024 * 1024 , completion: {(data,error) in
                                    if error != nil {
                                        print("\(error)")
                                    }else{
                                        ImageManager.saveLocalData(fileName: imageKey, imageData: data!)
                                        fishIconImg.image = UIImage(data: data!)!
                                    }
                                })
                            }
                       }
                    }else {
                        fishIconImg.image = UIImage(named: "fishIconName")
                    }

                    let thisFish = Fish(id: fishId, icon: fishIconImg, iconName: fishIconName, name: fishName, type: fishType, minTemp: fishMinTemp, maxTemp: fishMaxTemp, minpH: fishMinpH, maxpH: fishMaxpH, photo: photo as! [String], rating: fishRating, number: fishNumber)
                    self.fishList.add(thisFish)
                
                    self.filterList.add(thisFish)
                
                    print("new fish append success")
                
                    self.fishTableView.reloadData()
                }
        })
    }

    //MARK: - Firebase observation: Retrieve fish data by filtering the type
    func observeFishByType(type: String){
        self.fishList.removeAllObjects()
        self.filterList.removeAllObjects()
        
        var firstFilter = NSMutableArray()
        var secondFilter = NSMutableArray()
        
        fishesRefHandler = self.fishRef.observe(.childAdded, with: {(snapshot)-> Void in
            print(snapshot)
            
            let fishData = snapshot.value as! Dictionary<String,AnyObject>
            let fishId = snapshot.key
            if let fishName = fishData["fishName"] as! String?,
                let fishIconName = fishData["fishIconName"] as! String?,
                let fishType = fishData["fishType"] as! String?,
                let fishMaxTemp = fishData["fishMaxTemp"] as! Int?,
                let fishMinTemp = fishData["fishMinTemp"] as! Int?,
                let fishMaxpH = fishData["fishMaxpH"] as! Double?,
                let fishMinpH = fishData["fishMinpH"] as! Double?,
                let fishNumber = fishData["fishNumber"] as! Int?,
                let fishRating = fishData["fishRating"] as! Int?,
                let fishPhoto = fishData["pictureURL"] as! [String: AnyObject]?{
                var fishIconImg = UIImageView()
                let photo = Array(fishPhoto.values)
                
                //if the fish icon is import photo from user
                if(fishIconName == "fish"){
                    let userID = Auth.auth().currentUser!.uid
                    print(userID)
                    let icon = fishData["iconURL"] as! NSDictionary
                    
                    for(key,url) in icon{
                        let imageKey = key as! String
                        let downloadURL = url  as! String
                        
                        //if local file exists, retrieve from local file
                        if ImageManager.localFileExists(fileName: imageKey) {
                            fishIconImg.image = ImageManager.retrieveImageData(fileName: imageKey)
                        }
                        else{
                            //download in memory if not exist in the memory
                            let thisImageRef = self.storageRef.child("\(userID)/\(imageKey)")
                            print(thisImageRef)
                            thisImageRef.getData(maxSize: 5 * 1024 * 1024 , completion: {(data,error) in
                                if error != nil {
                                    print("\(error)")
                                }else{
                                    ImageManager.saveLocalData(fileName: imageKey, imageData: data!)
                                    fishIconImg.image = UIImage(data: data!)!
                                }
                            })
                        }
                    }
                }else {
                    fishIconImg.image = UIImage(named: "fishIconName")
                }
                
                let thisFish = Fish(id: fishId, icon: fishIconImg, iconName: fishIconName, name: fishName, type: fishType, minTemp: fishMinTemp, maxTemp: fishMaxTemp, minpH: fishMinpH, maxpH: fishMaxpH, photo: photo as! [String], rating: fishRating, number: fishNumber)
                
                
                self.fishList.add(thisFish)
                firstFilter.add(thisFish)
                print("new fish append success")

                if fishType.contains(type){
                    secondFilter.add(thisFish)
                }
                
                if (secondFilter.count > 0)
                {
                    self.filterList = secondFilter
                }
                
                
                self.fishTableView.reloadData()
            }
        })
    }

    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchBar.text, searchText.count > 0 {
            
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: table View datasource and delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
 
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filterList != nil {
            return filterList.count
        }
        else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FishTableViewCell", for: indexPath) as! FishTableViewCell
        let fishObject = self.filterList[indexPath.row] as! Fish
        let fishIconName = fishObject.fishIconName
        cell.fishIcon.image = UIImage(named: fishIconName)
        cell.fishName.text = fishObject.fishName
        cell.fishNumber.text = "Total: \(fishObject.fishNumber)"
        cell.fishDescription.text = fishObject.fishType
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedFish = self.filterList[indexPath.row] as! Fish
        performSegue(withIdentifier: "showDetails", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let controller: FishDetailViewController = segue.destination as! FishDetailViewController
            controller.showDelegate = self as ShowFishDelegate
            controller.selectedFish = selectedFish!
        }
    }
    
    func showDelegate(selected: Fish) {
        self.selectedFish = selected
    }
}
