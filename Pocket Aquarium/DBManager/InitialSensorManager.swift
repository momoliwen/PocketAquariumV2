//
//  InitialSensorManager.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 2/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class InitialSensorManager{
    
    static var sensorsRef = Database.database().reference().child("sensors")
    
    //MARK: firebase observe the sensor
    static func observeSensors(completion: @escaping(SensorDevice) -> Void){
            self.sensorsRef.observe(.childAdded, with: {(snapshot)-> Void in
            print(snapshot)
                if let thisSensor = SensorDevice(snapshot: snapshot){
                    completion(thisSensor)
                }
                else{
                    print("observe error")
                }
        })
    }
}
