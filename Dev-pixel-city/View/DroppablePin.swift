//
//  DroppablePin.swift
//  Dev-pixel-city
//
//  Created by Mac User on 5/13/19.
//  Copyright © 2019 Hammerhead96. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
