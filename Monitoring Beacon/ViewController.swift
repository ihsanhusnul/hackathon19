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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "refresh",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapRefresh))
        
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
        
        BeaconManager.shared.stop()
        BeaconManager.shared.start(delegate: self)
    }
    
    private func localPushNotif(mitraID: Int, distance: Double) {
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
    
    func localAlert(mitraID: Int, distance: Double) {
        let urlString = "https://m.bukalapak.com/mitra-terdekat/agents/\(mitraID)"
        let distanceInMeter = String(format: "%.2f", distance)
        
        let control = UIAlertController(title: "Hi, Kami dari Warung \(mitraID)",
            message: "Jangan lupa untuk mengunjungi mitra bukalapak \(distanceInMeter) meter dari anda",
            preferredStyle: .alert)
        control.addAction(
            UIAlertAction(title: "Visit", style: .default, handler: { (_) in
                UIApplication().open(URL(string: urlString)!,
                                     options: [:],
                                     completionHandler: nil)
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
    @objc func didTapRefresh() {
        
    }
    
    func showPushNotifIfNotYet() {
        var majors: [Int] = []
        if let array = UserDefaults.standard.array(forKey: kListMajorsLocalPush) as? [Int] {
            majors = array
        }
        
        for beacon in beacons {
            if !majors.contains(beacon.major) {
                localPushNotif(mitraID: beacon.major,
                                   distance: beacon.accuracy)
                
                alertLocal(mitraID: beacon.major,
                           distance: beacon.accuracy)
                
                majors.append(beacon.major)
            }
        }
        
        UserDefaults.standard.set(majors, forKey: kListMajorsLocalPush)
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
    }
    
    func onExit(beacons: [BLBeacon]) {
        print("onExit")
        print(beacons)
    }
}



