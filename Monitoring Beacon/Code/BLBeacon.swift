//
//  BLBeacon.swift
//  Monitoring Beacon
//
//  Created by IHsan HUsnul on 14/02/19.
//  Copyright © 2019 IHsan HUsnul. All rights reserved.
//

import Foundation

class BLBeacon {
    var regionIdentifier: String = ""
    var UUID: UUID?
    var major: Int = 0
    var minor: Int = 0
    var state: String?
    var detectedTime: Date?
    var proximity: Int = 0
    var accuracy: Double = 0.0
    
    init(regionIdentifier: String,
         UUID: UUID?,
         major: Int,
         minor: Int,
         state: String?,
         detectedTime: Date?,
         proximity: Int,
         accuracy: Double) {
        
        self.UUID = UUID
        self.major = major
        self.minor = minor
        self.detectedTime = detectedTime
        self.regionIdentifier = regionIdentifier
        self.proximity = proximity
        self.accuracy = accuracy
    }
}
