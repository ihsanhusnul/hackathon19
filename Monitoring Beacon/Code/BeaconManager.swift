//
//  BeaconManager.swift
//  Monitoring Beacon
//
//  Created by IHsan HUsnul on 14/02/19.
//  Copyright © 2019 IHsan HUsnul. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

protocol BeaconManagerDelegate: class {
    func onDetected(beacons: [BLBeacon])
    func onEnter(beacons: [BLBeacon])
    func onExit(beacons: [BLBeacon])
}

class BeaconManager: NSObject {
    static var shared: BeaconManager = BeaconManager()
    fileprivate var delegate: BeaconManagerDelegate?
    fileprivate var hasBeaconsDetected: Bool = false
    
    lazy var defaultRegion: CLBeaconRegion = self.createDefaultRegion()
    var detectedBeacons: [BLBeacon] = []
    
    
    lazy var locationManager: CLLocationManager = {
        var manager: CLLocationManager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    fileprivate var beacons: [CLBeacon] = []
    
    private override init() {
        
    }
    
    func start(delegate: BeaconManagerDelegate) {
        self.delegate = delegate
        
        locationManager.requestAlwaysAuthorization()
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startMonitoring(for: defaultRegion)
            
        default:
            print("location not allowed!")
        }
    }
    
    func stop() {
        locationManager.stopMonitoring(for: defaultRegion)
        locationManager.startMonitoring(for: defaultRegion)
    }
    
    func createDefaultRegion() -> CLBeaconRegion {
        let defaultUUID: UUID = UUID(uuidString: "97B6ED29-4357-4F9A-8443-365394261E15")!
        let region: CLBeaconRegion = CLBeaconRegion(proximityUUID: defaultUUID,
                                                    identifier: "")
        region.notifyEntryStateOnDisplay = true
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    @objc func requestStateDelayed(region: CLRegion) {
        locationManager.requestState(for: region)
    }
    
    func checkDetected(beacons: [CLBeacon], inRegion: CLBeaconRegion) {
        for beacon in beacons {
            detectedBeacons.append(
                BLBeacon(regionIdentifier: inRegion.identifier,
                         UUID: beacon.proximityUUID,
                         major: beacon.major.intValue,
                         minor: beacon.minor.intValue,
                         state: nil,
                         detectedTime: Date(),
                         proximity: beacon.proximity.rawValue,
                         accuracy: beacon.accuracy
                )
            )
        }
        
        if !detectedBeacons.isEmpty && !hasBeaconsDetected {
            hasBeaconsDetected = true
            delegate?.onDetected(beacons: detectedBeacons)
        }
    }
}

extension BeaconManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("start!")
        
        //perform(#selector(requestStateDelayed(region:)), with: region, afterDelay: 1)
        requestStateDelayed(region: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        checkDetected(beacons: beacons, inRegion: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let _region = region as? CLBeaconRegion else { return }
        
        switch state {
        case .inside:
            print("inside")
            manager.startRangingBeacons(in: _region)
            
        case .outside:
            print("outside")
            //manager.stopMonitoring(for: _region)
            //manager.stopRangingBeacons(in: region)
            
        default:
            print("unknown")
        }
    }
}
