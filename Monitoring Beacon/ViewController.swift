//
//  ViewController.swift
//  Monitoring Beacon
//
//  Created by IHsan HUsnul on 08/02/19.
//  Copyright © 2019 IHsan HUsnul. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import UserNotifications
import NotificationCenter


let kListMajorsLocalPush: String = "list_majors_local_push"


class ViewController: UITableViewController {
    var beacons: [BLBeacon] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BeaconManager.shared.start(delegate: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beacons.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beacon = beacons[indexPath.row]
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(beacon.major) in \(beacon.accuracy) meter"
        return cell
    }
    
    @IBAction func didTapClear(_ sender: Any?) {
        UserDefaults.standard.set(nil, forKey: kListMajorsLocalPush)
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        BeaconManager.shared.reset()
    }
    
    private func localPushNotif(mitraID: String, distance: Double) {
        let distanceInMeter = String(format: "%.2f", distance)
        
        let content = UNMutableNotificationContent()
        content.title = "Hi, Kami dari Warung \(mitraID)"
        content.body = "Jangan lupa untuk mengunjungi mitra bukalapak \(distanceInMeter) meter dari anda"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "\(mitraID)",
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        UIApplication.shared.applicationIconBadgeNumber += 1
    }
    
    func localAlert(mitraID: String, distance: Double) {
        let urlString = "https://m.bukalapak.com/mitra-terdekat/agents/\(mitraID)"
        let distanceInMeter = String(format: "%.2f", distance)
        
        let control = UIAlertController(title: "Hi, Kami dari Warung \(mitraID)",
            message: "Jangan lupa untuk mengunjungi mitra bukalapak \(distanceInMeter) meter dari anda",
            preferredStyle: .alert)
        
        control.addAction(
            UIAlertAction(title: "Visit", style: .default, handler: { (_) in
                UIApplication.shared.open(URL(string: urlString)!,
                                          options: [:],
                                          completionHandler: nil)
            })
        )
        
        control.addAction(
            UIAlertAction(title: "Dismiss", style: .destructive, handler: { (_) in
                control.dismiss(animated: true, completion: nil)
            })
        )
        present(control, animated: true, completion: nil)
    }
    
    func setTableWith(beacons: [BLBeacon]) {
        self.beacons = beacons
        tableView.reloadData()
    }
}


extension ViewController {
    func alert(title: String, message: String) {
        let control = UIAlertController(title: title,
                                        message: message,
                                        preferredStyle: .alert)
        control.addAction(
            UIAlertAction(title: "OK", style: .default, handler: { (_) in
                control.dismiss(animated: true, completion: nil)
            })
        )
        present(control, animated: true, completion: nil)
    }
    
    func showPushNotifIfNotYet() {
        var IDS: [String] = []
        if let array = UserDefaults.standard.array(forKey: kListMajorsLocalPush) as? [String] {
            IDS = array
        }
        
        for beacon in beacons {
            if !IDS.contains(beacon.regionIdentifier) {
                localPushNotif(mitraID: beacon.regionIdentifier,
                                   distance: beacon.accuracy)
                
                localAlert(mitraID: beacon.regionIdentifier,
                           distance: beacon.accuracy)
                
                IDS.append(beacon.regionIdentifier)
            }
        }
        
        UserDefaults.standard.set(IDS, forKey: kListMajorsLocalPush)
    }
}

extension ViewController: BeaconManagerDelegate {
    func onDetected(beacons: [BLBeacon]) {
        setTableWith(beacons: beacons)
        
        showPushNotifIfNotYet()
        
        print("onDetected")
        print(beacons)
    }
    
    func onEnter(beacons: [BLBeacon]) {
        print("onEnter")
        print(beacons)
        
        let majors = beacons.map {"\($0.major)"}
        alert(title: "onEnter", message: majors.joined(separator: ", "))
    }
    
    func onExit(beacons: [BLBeacon]) {
        print("onExit")
        print(beacons)
        
        let majors = beacons.map {"\($0.major)"}
        alert(title: "onExit", message: majors.joined(separator: ", "))
    }
}





