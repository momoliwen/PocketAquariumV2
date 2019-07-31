//
//  RealTimeValues.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 15/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class RealTimeValues: NSObject {
    
    let key : String?
    let ref : DatabaseReference?

    // realtime as node
    var currentDate : String
    
    //temp value
    var currentTemp : Int
    var currentPh : Double
    
    //color value
    var currentRed : Int
    var currentBlue : Int
    var currentGreen : Int

    //For tank ID
    var sensorId : String = ""
    
    init(currentTemp : Int, currentPh: Double, currentRed : Int, currentBlue : Int, currentGreen : Int, currentDate: String){
        self.key = currentDate
        self.currentTemp = currentTemp
        self.currentRed = currentRed
        self.currentBlue = currentBlue
        self.currentGreen = currentGreen
        self.currentDate = currentDate
        self.currentPh = currentPh
        self.ref = nil
    }
    
    //reference
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let phValue = value["pH"] as? Double,
            let tempValue = value["temp"] as? Int,
            let rValue = value["red"] as? Int,
            let gValue = value["green"] as? Int,
            let bValue = value["blue"] as? Int,
            let dateTime = value["date"] as? String,
            let sensorId = value["sensorId"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.currentRed = rValue
        self.currentBlue = bValue
        self.currentGreen = gValue
        self.currentTemp = tempValue
        self.currentDate = dateTime
        self.currentPh = phValue
        self.sensorId = sensorId
    }
}
