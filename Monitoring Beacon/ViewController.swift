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
    
    private func localPushNotif(notifID: String, title: String, body: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = category
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "notification-warung \(Int.random(in: 0 ..< 100))",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        UIApplication.shared.applicationIconBadgeNumber += 1
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
            //!IDS.contains(beacon.regionIdentifier) {
            if true {
                let title = "Hi, Kami dari Warung \(beacon.regionIdentifier)"
                let body = "Jangan lupa untuk mengunjungi mitra bukalapak \(beacon.distance()) meter dari anda"
                localPushNotif(notifID: "onDetect-\(beacon.regionIdentifier)",
                               title: title,
                               body: body,
                               category: "detected")
                
                IDS.append(beacon.regionIdentifier)
            }
        }
        
        UserDefaults.standard.set(IDS, forKey: kListMajorsLocalPush)
    }
    
    func showNotifHi(beacon: BLBeacon) {
        localPushNotif(notifID: "onEnter-\(beacon.regionIdentifier)",
            title: "Selamat Datang di Warung \(beacon.regionIdentifier)",
            body: "Jangan lupa untuk mengunjungi mitra bukalapak \(beacon.distance()) meter dari anda",
        category: "hi")
    }
    
    func showNotifBye(beacon: BLBeacon) {
        localPushNotif(notifID: "onExit-\(beacon.regionIdentifier)",
            title: "Terima Kasih telah mengunjungi Warung \(beacon.regionIdentifier)",
            body: "Jangan lupa untuk mengunjungi mitra bukalapak \(beacon.distance()) meter dari anda",
        category: "bye")
    }
}

extension ViewController: BeaconManagerDelegate {
    func onDetected(beacons: [BLBeacon]) {
        setTableWith(beacons: beacons)
        
        print("__onDetected")
        print(beacons)
        
        showPushNotifIfNotYet()
    }
    
    func onEnter(beacons: [BLBeacon]) {
        print("__onEnter")
        print(beacons)
        setTableWith(beacons: beacons)
        
        beacons.forEach { showNotifHi(beacon: $0) }
    }
    
    func onExit(beacons: [BLBeacon]) {
        print("__onExit")
        print(beacons)
        setTableWith(beacons: [])
        
        beacons.forEach { showNotifBye(beacon: $0) }
    }
}





