//
//  GeoLocation.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 1/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import CoreLocation

class GeoLocation: NSObject {
    var identifier : String
    var radius : CLLocationDistance
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
    }
}
