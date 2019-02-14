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

let MitraIDS: [String] = ["4008756"]

protocol BeaconManagerDelegate: class {
    func onDetected(beacons: [BLBeacon])
    func onEnter(beacons: [BLBeacon])
    func onExit(beacons: [BLBeacon])
}

class BeaconManager: NSObject {
    static var shared: BeaconManager = BeaconManager()
    fileprivate var delegate: BeaconManagerDelegate?
    
    fileprivate var hasBeaconsDetected: Bool = false
    fileprivate var hasExited: Bool = false
    fileprivate var tryRangingReached: Int = 0
    
    var detectedBeacons: [BLBeacon] = []
    
    
    lazy var locationManager: CLLocationManager = {
        var manager: CLLocationManager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    fileprivate var beacons: [CLBeacon] = []
    
    private override init() { }
    
    func start(delegate: BeaconManagerDelegate) {
        self.delegate = delegate
        
        locationManager.requestAlwaysAuthorization()
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            loadBeacons()
            
        default:
            print("location not allowed!")
        }
    }
    
    func reset() {
        hasBeaconsDetected = false
        detectedBeacons = []
        
        for mitraID in MitraIDS {
            let beaconRegion = createBeaconRegionBy(identifier: mitraID)
            locationManager.stopMonitoring(for: beaconRegion)
            locationManager.stopRangingBeacons(in: beaconRegion)
        }
    }
    
    func loadBeacons() {
        for mitraID in MitraIDS {
            let beaconRegion = createBeaconRegionBy(identifier: mitraID)
            locationManager.startMonitoring(for: beaconRegion)
            locationManager.startRangingBeacons(in: beaconRegion)
        }
    }
    
    func createBeaconRegionBy(identifier: String) -> CLBeaconRegion {
        let defaultUUID: UUID = UUID(uuidString: "97B6ED29-4357-4F9A-8443-365394261E15")!
        let region: CLBeaconRegion = CLBeaconRegion(proximityUUID: defaultUUID,
                                                    identifier: identifier)
        region.notifyEntryStateOnDisplay = true
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    @objc func requestStateDelayed(region: CLBeaconRegion) {
        locationManager.requestState(for: region)
    }
    
    func checkDetected(beacons: [CLBeacon], inRegion: CLBeaconRegion) {
        for beacon in beacons {
            detectedBeacons.append(
                BLBeacon(regionIdentifier: inRegion.identifier,
                         UUID: beacon.proximityUUID,
                         major: beacon.major.int16Value,
                         minor: beacon.minor.int16Value,
                         state: nil,
                         detectedTime: Date(),
                         proximity: beacon.proximity.rawValue,
                         accuracy: beacon.accuracy
                )
            )
            locationManager.stopRangingBeacons(in: inRegion)
        }
        
        if !detectedBeacons.isEmpty && !hasBeaconsDetected {
            if hasExited {
                delegate?.onEnter(beacons: detectedBeacons)
            } else {
                delegate?.onDetected(beacons: detectedBeacons)
            }
            
            hasBeaconsDetected = true
        }
    }
    
    func checkBeaconsFor(region: CLBeaconRegion, isEntered: Bool) {
        let regionBeacons = detectedBeacons.filter { $0.UUID == region.proximityUUID }
        
        if isEntered {
            hasExited = false
            delegate?.onEnter(beacons: regionBeacons)
        } else {
            hasExited = true
            delegate?.onExit(beacons: regionBeacons)
        }
    }
}

extension BeaconManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion")
        
        checkBeaconsFor(region: (region as! CLBeaconRegion), isEntered: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion")
        
        checkBeaconsFor(region: (region as! CLBeaconRegion), isEntered: true)
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("start!")
        
        perform(#selector(requestStateDelayed(region:)), with: region, afterDelay: 2)
//        requestStateDelayed(region: (region as! CLBeaconRegion))
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("didRangeBeacons: \(region.identifier)")
        checkDetected(beacons: beacons, inRegion: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let _region = region as? CLBeaconRegion else { return }
        
        print("\n \((region as! CLBeaconRegion))")
        
        switch state {
        case .inside:
            print("inside")
            manager.startRangingBeacons(in: _region)
            
        case .outside, .unknown:
            if state == .outside {
                print("outside")
            } else {
                print("unknown")
            }
            
//            tryRangingReached += 1
//            if tryRangingReached > 2, state == .outside {
            if state == .outside {
                checkBeaconsFor(region: (region as! CLBeaconRegion), isEntered: false)
            }
//            else {
//                manager.startRangingBeacons(in: _region)
//            }
        }
    }
}
