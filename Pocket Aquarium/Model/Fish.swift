//
//  Fish.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 12/10/18. Revised By Liwen on 26/10/18
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class Fish: NSObject {
    var fishId : String
    var fishIcon : UIImageView
    var fishIconName : String
    var fishName : String
    var fishType : String
    var fishMinTemp : Int
    var fishMaxTemp : Int
    var fishMinpH : Double
    var fishMaxpH : Double
    // firebase db autokey as image URL key 
    var fishPhoto : [String]
    var fishRating : Int
    var fishNumber : Int
    var iconURL : String?
    var iconKey: String?
    
    var ref : DatabaseReference?
    private var storageRef = Storage.storage().reference().child("images")
    
    init(id:String, icon:UIImageView, iconName: String, name:String, type:String, minTemp:Int, maxTemp:Int, minpH:Double, maxpH:Double, photo:[String], rating: Int, number:Int){
        self.fishId = id
        self.fishIcon = icon
        self.fishIconName = iconName
        self.fishName = name
        self.fishType = type
        self.fishMinTemp = minTemp
        self.fishMaxTemp = maxTemp
        self.fishMinpH = minpH
        self.fishMaxpH = maxpH
        self.fishPhoto = photo
        self.fishRating = rating
        self.fishNumber = number
       }
    
    //download from firebase 
    init? (snapshot : DataSnapshot, uid : String ){
        guard
            let fishData = snapshot.value as? [String: AnyObject],
            let fishIconName = fishData["fishIconName"] as! String?,
            let fishId = fishData["fishId"] as! String?,
            let maxTemp = fishData["fishMaxTemp"] as! Int?,
            let minTemp = fishData["fishMinTemp"] as! Int?,
            let maxpH = fishData["fishMaxpH"] as! Double?,
            let minpH = fishData["fishMinpH"] as! Double?,
            let name = fishData["fishName"] as! String?,
            let fishTotalNo = fishData["fishNumber"] as! Int?,
            let type = fishData["fishType"] as! String?,
            let rating = fishData["fishRating"] as! Int? else {
                return nil
        }
    
        self.ref = snapshot.ref
        self.fishId = snapshot.key
        self.fishRating = rating
        self.fishMinpH = minpH
        self.fishMaxpH = maxpH
        self.fishMinTemp = minTemp
        self.fishMaxTemp = maxTemp
        self.fishNumber = fishTotalNo
        self.fishRating = rating
        self.fishType = type
        self.fishIconName = fishIconName
        self.fishName = name
    
        var fishIconImg = UIImageView()
        let fishPhoto = fishData["pictureURL"] as! [String: AnyObject]?
        var photo: [String]
        
        if fishPhoto != nil{
            photo = Array((fishPhoto?.keys)!) as! [String]
        }else{
            photo = ["photo"]
        }
        
        self.fishPhoto = photo
        
        //if the fish icon is import photo from user
        if fishIconName == "fish" {
            //if has iconURL node in this fish json
            if fishData["iconURL"] != nil{
                let icon = fishData["iconURL"] as! NSDictionary
                for(key,url) in icon{
                    let imageKey = key as! String
                    self.iconKey = imageKey
                    let downloadURL = url  as? String
                    self.iconURL = downloadURL

                    if ImageManager.localFileExists(fileName: imageKey) {
                        fishIconImg.image = ImageManager.retrieveImageData(fileName: imageKey)
                    }
                    else{
                        //download in memory if not exist in the memory
                        let thisImageRef = self.storageRef.child("\(uid)/\(imageKey)")
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
            }
        }else{
             fishIconImg.image = UIImage(named: "\(fishIconName)")
        }
        self.fishIcon = fishIconImg
    }
    //MARK: upload to firebase
    func toFishMemberObject() -> Any{
        if self.fishIconName == "fish"{
            return [
                "fishId" : self.fishId,
                "fishIconName" : self.fishIconName,
                "fishName" : self.fishName,
                "fishType" : self.fishType,
                "fishMinTemp" : self.fishMinTemp,
                "fishMaxTemp" : self.fishMaxTemp,
                "fishMinpH" : self.fishMinpH,
                "fishMaxpH" : self.fishMaxpH,
                "fishRating" : self.fishRating,
                "fishNumber" : self.fishNumber,
                "iconURL" : [ self.iconKey : self.iconURL]
                ]  as  [String : Any]
        }
        else{
            return [
                "fishId" : self.fishId,
                "fishIconName" : self.fishIconName,
                "fishName" : self.fishName,
                "fishType" : self.fishType,
                "fishMinTemp" : self.fishMinTemp,
                "fishMaxTemp" : self.fishMaxTemp,
                "fishMinpH" : self.fishMinpH,
                "fishMaxpH" : self.fishMaxpH,
                "fishRating" : self.fishRating,
                "fishNumber" : self.fishNumber
                ]  as  [String : Any]
        }
        
    }
}


