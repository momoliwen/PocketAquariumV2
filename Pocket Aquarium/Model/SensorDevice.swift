//
//  SensorDevice.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

//for sensor, lighting and pumping
class Device {
    var name : String
    var icon : UIImage
    var state : String
    
    init(name: String, icon : UIImage, state: String) {
        self.name = name
        self.icon = icon
        self.state = state 
    }
}

class SensorDevice: NSObject {
    var sensorId : String
    var pin  : Int
    var name : String
    
    init(id: String, name: String, pin :Int) {
        self.sensorId = id
        self.name = name
        self.pin = pin
    }

    init?(snapshot : DataSnapshot){
        self.sensorId  = snapshot.key
        guard
            let sensorData = snapshot.value as? [String: Any],
            let name = sensorData["sensorName"] as! String? ,
            let pin = sensorData["sensorPin"] as! Int? else{
                return nil
            }
        self.name = name
        self.pin = pin
    }
    
}

