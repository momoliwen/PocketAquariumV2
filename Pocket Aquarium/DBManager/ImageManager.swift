//
//  ImageManager.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 14/10/18. Liwen revised 25/10/2018
//  Copyright © 2018 Monash University. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class ImageManager {
    static var storageRef = Storage.storage().reference().child("images")
    
    // static var tanksRef = Database.database().reference().child("tanks")
    static var imageDownloadURL : String?
    
    //save a list of image
    static func saveFishAndPhotos (images : [UIImage]?, thisFishRef : DatabaseReference, values: [String : Any], uid: String) -> [String]? {
        guard let imageArray = images else {
            print("images nil")
            return nil
        }
        var photoKeyList = [String]()
        
        for image in imageArray {
            var imageData = Data()
            imageData = UIImageJPEGRepresentation(image, 0.5)!
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpg"
            
            //1. create an unique id in db
            let imageRef = thisFishRef.child("pictureURL").childByAutoId()
            let imageKey = imageRef.key
            photoKeyList.append("\(imageKey!)")
            
            //2. create a new storage reference, save the key as storage key
            let newImageStorageRef = self.storageRef.child("\(uid)/\(imageKey!)")
            //3. save the image to storage
            newImageStorageRef.putData(imageData, metadata: metadata, completion: { (metaData, error) in
          
                newImageStorageRef.downloadURL {(url,error) -> () in
                    guard let thisURL = url else {
                        return
                            print("url nil")
                    }
                    
                    self.imageDownloadURL = thisURL.absoluteString
                    
                   var imageItem = [
                       "\(imageKey!)" : imageDownloadURL
                   ]
                    //update the child node value
                    thisFishRef.child("pictureURL").updateChildValues(imageItem, withCompletionBlock: { (err,ref) in
                        if err != nil {
                        print(err)
                        return
                    }
                    print("save photo to realtime and storage successfully... ")
                })
                    thisFishRef.updateChildValues(values)
                    //thisFishRef.child("pictureURL").updateChildValues(imageItem)
                   
                }
            })
            print("save photo successfully... ")
            self.saveLocalData(fileName: "\(imageKey!)", imageData: imageData)
        }
        return photoKeyList
    }
    

    static func savePhoto(image : UIImage?, thisTankRef : DatabaseReference){
        guard let thisImage = image else {
            print("image nil")
            return
        }
        guard let userID = Auth.auth().currentUser?.uid else{
            print("userid nil")
            return
        }
        
        var imageData = Data()
        imageData = UIImageJPEGRepresentation(image!, 0.8)!
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        //1. create an unique id
        let imageRef = thisTankRef.child("pictureURL").childByAutoId()
        let fileName = imageRef.key
        //2. create a new storage reference, save the key as storage key
        let newImageStorageRef = self.storageRef.child("\(userID)/\(fileName!)")
        //3. save the image to storage
        newImageStorageRef.putData(imageData, metadata: metadata) { (metaData, error) in
            newImageStorageRef.downloadURL { (url,error) -> () in
                guard let thisURL = url else {
                    return
                        print("url nil")
                }
                self.imageDownloadURL = thisURL.absoluteString
                var imageItem = [
                    "\(fileName!)" : imageDownloadURL
                ]
                //update the child node value 
                thisTankRef.child("pictureURL").updateChildValues(imageItem)
                print("save photo successfully")
            }
        }
        //may not be needed to save to local data
        self.saveLocalData(fileName: "\(fileName!)", imageData: imageData)
    }
    
    //new version for saving fish icon
    static func saveFishIcon(image : UIImage?, thisFishRef : DatabaseReference, values: [String : Any], uid : String){
        guard let thisImage = image else {
            print("image nil")
            return
        }
        
        var imageData = Data()
        imageData = UIImageJPEGRepresentation(image!, 0.3)!
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        //1. create an unique id
        let importIconRef = thisFishRef.child("iconURL").childByAutoId()
        let iconKey = importIconRef.key
        print(iconKey)
        
        //2. create a new storage reference
        let newImageStorageRef = self.storageRef.child("\(uid)/\(iconKey!)")
        //3. save the image to storage
        newImageStorageRef.putData(imageData, metadata: metadata) { (metaData, error) in
            newImageStorageRef.downloadURL { (url,error) -> () in
                guard let thisURL = url else {
                    return
                        print("url nil")
                }
                self.imageDownloadURL = thisURL.absoluteString
                var iconItem = [
                    "\(iconKey!)" : imageDownloadURL
                ]

                //update the child node value
                thisFishRef.child("iconURL").updateChildValues(iconItem, withCompletionBlock: { (err,ref) in
                    if err != nil {
                        print(err)
                        return
                    }
                    print("save icon image to realtime and storage successfully... ")
                })
                
                thisFishRef.updateChildValues(values)
                print("update new fish node  successfully")
            }
        }
        self.saveLocalData(fileName: "\(iconKey!)", imageData: imageData)
    }
    
    //new version for save fish icon
    static func saveFishIconBoth(image : UIImage?, thisFishRef : DatabaseReference, thisFishInTankRef : DatabaseReference, values: [String : Any], uid : String){
        guard let thisImage = image else {
            print("image nil")
            return
        }
        
        var imageData = Data()
        imageData = UIImageJPEGRepresentation(image!, 0.3)!
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        //1. create an unique id
        let importIconRef = thisFishRef.child("iconURL").childByAutoId()
        let iconKey = importIconRef.key
        print(iconKey)
        
        //2. create a new storage reference
        let newImageStorageRef = self.storageRef.child("\(uid)/\(iconKey!)")
        //3. save the image to storage
        newImageStorageRef.putData(imageData, metadata: metadata) { (metaData, error) in
            newImageStorageRef.downloadURL { (url,error) -> () in
                guard let thisURL = url else {
                    return
                        print("url nil")
                }
                self.imageDownloadURL = thisURL.absoluteString
                var iconItem = [
                    "\(iconKey!)" : imageDownloadURL
                ]
                
                //update the child node value
                thisFishRef.child("iconURL").updateChildValues(iconItem, withCompletionBlock: { (err,ref) in
                    if err != nil {
                        return
                    }
                    print("save icon image to realtime and storage successfully... ")
                })
                
    
                thisFishRef.updateChildValues(values)
                
                //update the child node value
                thisFishInTankRef.child("iconURL").updateChildValues(iconItem, withCompletionBlock: { (err,ref) in
                    if err != nil {
                        return
                    }
                    print("save icon image to realtime and storage successfully... ")
                })
                
                thisFishInTankRef.updateChildValues(values)
                print("update fish and fish in tank node  successfully")
            }
        }
        self.saveLocalData(fileName: "\(iconKey!)", imageData: imageData)
    }
    
    
    static func saveIcon(image : UIImage?, thisFishRef : DatabaseReference){
        guard let thisImage = image else {
            print("image nil")
            return
        }
        guard let userID = Auth.auth().currentUser?.uid else{
            print("userid nil")
            return
        }
        
        var imageData = Data()
        imageData = UIImageJPEGRepresentation(image!, 0.8)!
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        //1. create an unique id
        let imageRef = thisFishRef.child("iconURL").childByAutoId()
        let fileName = imageRef.key
        print(fileName)
        
        //2. create a new storage reference
        let newImageStorageRef = self.storageRef.child("\(userID)/\(fileName!)")
        //3. save the image to storage
        newImageStorageRef.putData(imageData, metadata: metadata) { (metaData, error) in
            newImageStorageRef.downloadURL { (url,error) -> () in
                guard let thisURL = url else {
                    return
                        print("url nil")
                }
                self.imageDownloadURL = thisURL.absoluteString
                var imageItem = [
                    "\(fileName!)" : imageDownloadURL
                ]
                thisFishRef.child("iconURL").updateChildValues(imageItem)
                print("save photo successfully")
            }
        }
        self.saveLocalData(fileName: "\(fileName!)", imageData: imageData)
    }
    // from local
    static func retrieveImageData(fileName: String) -> UIImage?{
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var image:UIImage?
        
        if let pathComponent = url.appendingPathComponent(fileName){
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            let fileData = fileManager.contents(atPath: filePath)
            if fileData != nil {
                image = UIImage(data: fileData!)
            }
        }
        return image
    }
    
    //check local file exist
    static func localFileExists(fileName : String) -> Bool {
        var localFileExists = false
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(fileName){
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            //localFileExists = true
            localFileExists = fileManager.fileExists(atPath: filePath)
        }
        return localFileExists
    }
    
    static func saveLocalData(fileName:String, imageData  : Data){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(fileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            fileManager.createFile(atPath: filePath, contents: imageData, attributes: nil)
        }
    }
    
    //MARK: find ImageStorages
    static func getImageStorage (thisTankRef : DatabaseReference) -> [String]? {
        var imageStorageRefs = [String]()
        thisTankRef.queryOrdered(byChild: "pictureURL").observeSingleEvent(of: .value){ (snapshot) in
            print(snapshot)
            let imageFileName = snapshot.value as! String
            imageStorageRefs.append(imageFileName)
            print(imageFileName)
        }
        return imageStorageRefs
        print("get image storage reference name success")
    }
    
    //MARK: delete Image Storages
    static func deleteImageStorage(imageStorages : [String]?){
        if imageStorages != nil {
            for imageFileName in imageStorages! {
                print(imageFileName)
                if let userID = Auth.auth().currentUser?.uid {
                    
                    let deleteRef = self.storageRef.child(userID).child(imageFileName)
                    deleteRef.delete(completion: {error in
                        if error != nil{
                            print(error?.localizedDescription)
                        }
                        else{
                            print("delete this image storage successfully")
                        }
                    })
                }
            }
        }
    }
}


