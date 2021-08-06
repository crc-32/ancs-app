//
//  CentralDelegate.swift
//  bigbutton
//
//  Created by crc32 on 06/08/2021.
//

import Foundation
import CoreBluetooth

class BTDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    static let pairServiceUUID = CBUUID(string: "0000fed9-0000-1000-8000-00805f9b34fb")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown:
                print("unknown")
            case .resetting:
                print("resetting")
            case .unsupported:
                print("unsupported")
            case .unauthorized:
                print("unauthorized")
            case .poweredOff:
                print("poweredOff")
                centralManager?.stopScan()
            case .poweredOn:
                print("poweredOn")
                startScan()
            default:
                print("unknown")
        }
    }
    
    func startScan() {
        centralManager?.scanForPeripherals(withServices: [BTDelegate.pairServiceUUID], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("peripheral: \(peripheral)")
    }
}
