//
//  ProximityDiscovery.swift
//  bigbutton
//
//  Created by crc32 on 10/10/2021.
//

import Foundation
import CobbleLE
import CoreBluetooth
class ProximityDiscovery {
    private let centralController: LECentralController
    var onCandidateFound: ((CBPeripheral) -> ())?
    
    private var rssiThreshold = -35
    private var rangeTimer: Timer?
    
    init(centralController: LECentralController) {
        self.centralController = centralController
    }
    
    func startDiscovery() {
        centralController.startScan() {discoveredDevice, rssi in
            //print("RSSI: \(rssi)/\(self.rssiThreshold)")
            if rssi >= self.rssiThreshold {
                self.onCandidateFound?(discoveredDevice)
            }
        }
        rangeTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.rssiThreshold -= 5
        }
    }
    
    func stopDiscovery() {
        rangeTimer?.invalidate()
        rangeTimer = nil
        
        centralController.stopScan()
    }
}
