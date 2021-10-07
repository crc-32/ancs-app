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
    var peripheral: CBPeripheral?
    
    static let pairServiceUUID = CBUUID(string: "0000fed9-0000-1000-8000-00805f9b34fb")
    static let connParamsUUID = CBUUID(string: "00000005-328E-0FBB-C642-1AA6699BDADA")
    static let connectivityUUID = CBUUID(string: "00000001-328E-0FBB-C642-1AA6699BDADA")
    static let pairTriggerUUID = CBUUID(string: "00000002-328E-0FBB-C642-1AA6699BDADA")
    
    //static let charConfUUID = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
    //static let charSubVal: [UInt8] = [0x01, 0x00]
    
    var running = false
    
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
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(peripheral.name! + " connected.")
        peripheral.discoverServices(nil)
        
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect: " + error!.localizedDescription)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("Failed to discover services: " + error!.localizedDescription)
            return
        }
        
        print("Discovered services.")
        let pairService = peripheral.services?.first(where: { $0.uuid == BTDelegate.pairServiceUUID })
        peripheral.discoverCharacteristics(nil, for: pairService!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print("Error discovering characteristics: " + error!.localizedDescription)
            return
        }
        
        print("Discovered characteristics.")
        switch service.uuid {
        case BTDelegate.pairServiceUUID:
            let connParamChar = service.characteristics?.first(where: { $0.uuid == BTDelegate.connParamsUUID })
            if (connParamChar == nil) {
                print("Starting connectivity w/o connparams")
                deviceConnectivity()
            }else {
                peripheral.discoverDescriptors(for: connParamChar!)
            }
            break
        default:
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error discovering descriptors for char " + characteristic.uuid.uuidString + ": " + error!.localizedDescription)
            return
        }
        
        switch characteristic.uuid {
        case BTDelegate.connParamsUUID:
            peripheral.setNotifyValue(true, for: characteristic)
            break
        case BTDelegate.connectivityUUID:
            peripheral.setNotifyValue(true, for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        default:
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if (error != nil) {
            print("Error writing desc value for char " + descriptor.characteristic!.uuid.uuidString + ": " + error!.localizedDescription)
            return
        }
        print("Wrote a notif val")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error updating notif state for char " + characteristic.uuid.uuidString + ": " + error!.localizedDescription)
            return
        }
        
        switch characteristic.uuid {
        case BTDelegate.connParamsUUID:
            let disableParamManagementVal: [UInt8] = [0x00, 0x01]
            peripheral.writeValue(Data(disableParamManagementVal), for: characteristic, type: .withResponse)
            break
        case BTDelegate.connectivityUUID:
            print("Subscribed successfully to connectivity")
            break
        default:
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error writing to char " + characteristic.uuid.uuidString + ": " + error!.localizedDescription)
            return
        }
        
        switch characteristic.uuid {
        case BTDelegate.connParamsUUID:
            print("Starting connectivity after connparams")
            deviceConnectivity()
            break
        default:
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error while listening to char " + characteristic.uuid.uuidString + ": " + error!.localizedDescription)
            return
        }
        
        switch characteristic.uuid {
        case BTDelegate.connectivityUUID:
            let status = ConnectivityStatus(characteristicValue: characteristic.value!)
            print("Connectivity status update: " + status.description)
            if !running {
                running = true
                if status.connected && status.paired {
                    print("Paired.")
                }else {
                    print("Not yet paired, pairing...")
                    let pairTrigger = characteristic.service?.characteristics?.first(where: { $0.uuid == BTDelegate.pairTriggerUUID })
                    if pairTrigger!.properties.contains(.write) {
                        print("Writing pairing trigger")
                        peripheral.writeValue(Data([0xFF, status.supportsPinningWithoutSlaveSecurity ? 0xFF : 0x00, 0x00, 0x00, 0x00]), for: pairTrigger!, type: .withResponse)
                    }else {
                        print("Reading pairing trigger")
                        let _ = peripheral.readValue(for: pairTrigger!)
                    }
                }
            }
            break
        default:
            break
        }
    }
    
    func deviceConnectivity() {
        let pairService = peripheral!.services?.first(where: { $0.uuid == BTDelegate.pairServiceUUID })
        let connCharacteristic = pairService!.characteristics!.first(where: { $0.uuid == BTDelegate.connectivityUUID })
        peripheral!.discoverDescriptors(for: connCharacteristic!)
    }
    
    func startScan() {
        centralManager?.scanForPeripherals(withServices: [BTDelegate.pairServiceUUID], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if self.peripheral == nil {
            print("peripheral: \(peripheral)")
            if peripheral.name?.contains("Pebble") == true {
                self.peripheral = peripheral
                peripheral.delegate = self
                centralManager.connect(peripheral)
            }
        }
    }
}
