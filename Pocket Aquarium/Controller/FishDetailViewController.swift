//
//  FishDetialViewController.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 19/10/18. Revised By Liwen Liang 28/10/2018
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Cosmos
import Firebase

protocol ShowFishDelegate {
    func showDelegate (selected: Fish)
}

class FishDetailViewController: UIViewController {
    
    @IBOutlet weak var fishImageView: UIImageView!
    @IBOutlet weak var fishNameLabel: UILabel!
    @IBOutlet weak var fishTypeLabel: UILabel!
    @IBOutlet weak var fishRatingStar: CosmosView!
    @IBOutlet weak var fishMinpHLabel: UILabel!
    @IBOutlet weak var fishMinTempLabel: UILabel!
    @IBOutlet weak var fishMaxpHLabel: UILabel!
    @IBOutlet weak var fishMaxTempLabel: UILabel!
    
    var selectedFish: Fish?
    var showDelegate : ShowFishDelegate?
    var currentnImageIndex:NSInteger = 0
    
    //DB Reference
    let userID = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userID!)
    lazy var fishRef = userRef.child("fishes")
    private var storageRef = Storage.storage().reference().child("images")
    
    //DB reference handler
    private var fishesRefHandler : DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadDetailFromList()
        
        fishImageView.isUserInteractionEnabled = true
        let rightswipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeImage))
        rightswipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.right
        let leftswipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeImage))
        leftswipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.left
        fishImageView.addGestureRecognizer(rightswipeGestureRecognizer)
        fishImageView.addGestureRecognizer(leftswipeGestureRecognizer)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.cosmosTapped))
        fishRatingStar.addGestureRecognizer(tapGestureRecognizer)
        fishRatingStar.isUserInteractionEnabled = true
        
        getFish()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getFish()
    }
    
    //MARK: swipe picture gesture action on picture photos
    @objc func swipeImage(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer{
            switch swipeGesture.direction{
            case UISwipeGestureRecognizerDirection.left:
                print("User swiped left")
                
                if currentnImageIndex < (selectedFish?.fishPhoto.count)! - 1 {
                    currentnImageIndex = currentnImageIndex + 1
                }
                
                if currentnImageIndex < (selectedFish?.fishPhoto.count)!  {
                    let key = selectedFish?.fishPhoto[currentnImageIndex]
                    if ImageManager.localFileExists(fileName: key!) {
                        self.fishImageView.image = ImageManager.retrieveImageData(fileName: key!)
                    }
                    else{
                        //download in memory if not exist in the memory
                        let thisImageRef = self.storageRef.child("\(self.userID!)/\(key!)")
                        print(thisImageRef)
                        thisImageRef.getData(maxSize: 5 * 1024 * 1024 , completion: {(data,error) in
                            if error != nil {
                                print("\(error)")
                            }else{
                                ImageManager.saveLocalData(fileName: key!, imageData: data!)
                                self.fishImageView.image = UIImage(data: data!)!
                                
                            }
                        })
                    }
                    
                }
            case UISwipeGestureRecognizerDirection.right:
                print("User swiped right")
                
                // --currentnImageIndex
                if currentnImageIndex > 0{
                    currentnImageIndex = currentnImageIndex - 1
                }
                if currentnImageIndex >= 0{
                    let key = selectedFish?.fishPhoto[currentnImageIndex]
                    if ImageManager.localFileExists(fileName: key!) {
                        self.fishImageView.image = ImageManager.retrieveImageData(fileName: key!)
                    }
                    else{
                        //download in memory if not exist in the memory
                        let thisImageRef = self.storageRef.child("\(self.userID!)/\(key)")
                        print(thisImageRef)
                        thisImageRef.getData(maxSize: 5 * 1024 * 1024 , completion: {(data,error) in
                            if error != nil {
                                print("\(error)")
                            }else{
                                ImageManager.saveLocalData(fileName: key!, imageData: data!)
                                self.fishImageView.image = UIImage(data: data!)!
                                
                            }
                        })
                    }
                }
            default:
                break
                
            }
        }
    }
    

    //After user tap the star the action sheet will be shown
    @objc func cosmosTapped() {
        let alert = UIAlertController(title: "Edit the aggressive rating \n\n", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        //needa customized the alert message
        var cosmos = CosmosView()
        cosmos.rating = Double(selectedFish!.fishRating)
        cosmos.frame = CGRect(x: CGFloat(80.0), y: CGFloat(55.0), width: CGFloat(100), height: CGFloat(10))
        alert.view.addSubview(cosmos)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { editRating in
            
            self.selectedFish?.fishRating = Int(cosmos.rating)
         
            self.fishRef.child(self.selectedFish!.fishId).updateChildValues(["fishRating" : self.selectedFish?.fishRating])
            
            //if from the tank fish list, it will update corresponding reference
             if let thisRef = self.selectedFish!.ref {
                thisRef.updateChildValues(["fishRating" : self.selectedFish?.fishRating])
            }
            //update the fish in tank
            print("\(self.selectedFish?.ref)")
            self.displayFinishMessage(message: "Fish Updated!", title: "")
            self.fishRatingStar.rating = cosmos.rating
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }


    //MARK:finish adding the fish dimiss the controller
    func displayFinishMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: {action in
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    

    //MARK: show the fish detail from the tank fish list screen,reload the fish data from fishes node
    func reloadDetailFromList(){
        if selectedFish != nil{
            self.fishRef.child("\(selectedFish!.fishId)").observeSingleEvent(of: .value, with: {(snapshot) in
                print(snapshot)
                if let thisFish = Fish(snapshot: snapshot, uid: self.userID!){
                    print("\(thisFish.fishPhoto)")
                    self.selectedFish = thisFish
                }
            })
        }
    }
    
    //MARK: - Firebase observation: Retrieve fish data
    private func getFish(){
        if selectedFish != nil{
        fishesRefHandler = self.userRef.child("fishes").queryOrdered(byChild: "fishId").queryEqual(toValue: self.selectedFish!.fishId).observe(.childAdded, with: {(snapshot)-> Void in
            
            let thisFish = Fish(snapshot: snapshot, uid: self.userID!)
            
            self.fishNameLabel.text = thisFish!.fishName
            self.fishTypeLabel.text = thisFish!.fishType
            self.fishRatingStar.rating = Double(thisFish!.fishRating)
            self.fishRatingStar.settings.updateOnTouch = false
            self.fishMinpHLabel.text = String(thisFish!.fishMinpH)
            self.fishMaxpHLabel.text = String(thisFish!.fishMaxpH)
            self.fishMinTempLabel.text = "\(String(thisFish!.fishMinTemp)) ℃"
            self.fishMaxTempLabel.text = "\(String(thisFish!.fishMaxTemp)) ℃"
            
            let key = self.selectedFish?.fishPhoto[0]
            if (key != "photo"){
                if ImageManager.localFileExists(fileName: key!) {
                    self.fishImageView.image = ImageManager.retrieveImageData(fileName: key!)
                }
                else{
                    //download in memory if not exist in the memory
                    let thisImageRef = self.storageRef.child("\(self.userID!)/\(key!)")
                    print(thisImageRef)
                    thisImageRef.getData(maxSize: 5 * 1024 * 1024 , completion: {(data,error) in
                        if error != nil {
                            print("\(error)")
                        }else{
                            ImageManager.saveLocalData(fileName: key!, imageData: data!)
                            self.fishImageView.image = UIImage(data: data!)!
                            }
                        })
                    }
            }else {
                self.fishImageView.image = UIImage(named: "noImage")
            }
            })
            
        }
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editFish"){
            let nav = segue.destination as! UINavigationController
            var editVC = nav.topViewController as! SetEnvironmentViewController
            editVC.selectedFish = selectedFish
        }
    }
}
