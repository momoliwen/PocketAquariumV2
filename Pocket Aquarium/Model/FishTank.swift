//
//  FishTank.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 15/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class FishTank: NSObject {
    
    var ref : DatabaseReference?
    var key : String?
    
    var tankId : String
    var tankName : String
    //temp range
    var desiredMinTemp : Int
    var desiredMaxTemp : Int
    //fish number configuration
    var fishMaxNumber: Int? = 0
    var fishList = [Fish]()
    //Hp range
    var desiredMinpH : Double
    var desiredMaxpH : Double
    //create date
    var createdDate: String
    var state: String = "UnKnown"
    
    //current hp color & temp
    var currentColor: UIColor? = UIColor.lightGray.withAlphaComponent(0.8)
    var currentTemp : Int? = 0
    var currentpH : Double? = 0.0

    //devices in use
    var sensorId : String?
    var lightingState : String = "Off"
    var pumpingState : String = "Off"
    
    init(id: String, name:String, today : String, minTemp:Int, maxTemp : Int, minHp: Double, maxHp : Double){
        self.tankId = id
        self.key = id
        self.createdDate = today
        self.tankName = name
        self.desiredMinTemp = minTemp
        self.desiredMaxTemp = maxTemp
        self.desiredMaxpH = maxHp
        self.desiredMinpH  = minHp
        self.ref = nil
    }
    
    //calculate current state value
    func calculateCurrentState(currentTemp : Int){
        if currentTemp <  desiredMinTemp &&
            currentTemp > desiredMaxTemp {
            self.state = "Temp lower"
        }
        if currentTemp == desiredMinTemp ||
            currentTemp == desiredMaxTemp {
            self.state = "Temp Warning"
        }
        if currentTemp < desiredMaxTemp &&
            currentTemp > desiredMinTemp {
            self.state = "Suitable"
        }
    }
    
    //MARK: uploade to firebase
    init?(snapshot : DataSnapshot){
        guard
            let tankData = snapshot.value as? [String: AnyObject],
            let tankName = tankData["tankName"] as! String?,
            let createDate = tankData["createDate"] as! String?,
            let desiredMinTemp = tankData["minTemp"] as! Int?,
            let desiredMaxTemp = tankData["maxTemp"] as! Int?,
            let desiredMinpH = tankData["minpH"] as! Double?,
            let desiredMaxpH = tankData["maxpH"] as! Double?,
            let maxFishNum = tankData["maxFishNum"] as! Int?,
            let sensorId = tankData["sensorId"] as! String?,
            let light = tankData["lightingState"] as! String?,
            let pump = tankData["pumpingState"] as! String? else {
                return nil
        }
        
        self.ref = snapshot.ref
        self.tankId = snapshot.key
        self.tankName = tankName
        self.createdDate = createDate
        self.desiredMinTemp = desiredMinTemp
        self.desiredMaxTemp = desiredMaxTemp
        self.desiredMinpH = desiredMinpH
        self.desiredMaxpH = desiredMaxpH
        self.fishMaxNumber = maxFishNum
        self.sensorId = sensorId
        self.lightingState = light
        self.pumpingState = pump
    }
}
