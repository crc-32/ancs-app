//
//  BTController.swift
//  ancs-app
//
//  Created by crc32 on 13/10/2021.
//

import Foundation
import CoreBluetooth
import CobbleLE
import SwiftUI

enum BTControllerState: String, CustomStringConvertible {
    case idle = ""
    case scanning = "Scanning..."
    case pairing = "Pairing..."
    case connecting = "Connecting..."
    case pairError = "Error while pairing."
    case waitANCS = "Waiting for notification setup..."
    case connected = "Connected."
    case connectedNoANCS = "No ANCS permission."
    
    var description: String {
        get {
            return self.rawValue
        }
    }
}

class BTController: ObservableObject {
    private let centralController = LECentralController()
    private var proximityDiscovery: ProximityDiscovery!
    private var peripheralClientController: LEClientController?
    
    @Published var state: BTControllerState = .idle
    private var ancsStatus = false
    private var status: ConnectivityStatus?
    private var peripheral: CBPeripheral?
    
    init() {
        centralController.ancsUpdateCallback = self.ancsStatusChange
        proximityDiscovery = ProximityDiscovery(centralController: centralController, onCandidateFound: onCandidateFound)
    }
    
    private func ancsStatusChange(ancsPeripheral: CBPeripheral) {
        DispatchQueue.main.async { [self] in
            ancsStatus = ancsPeripheral.ancsAuthorized
            if status?.connected == true && status?.paired == true {
                withAnimation {
                    if ancsPeripheral.ancsAuthorized {
                        state = .connected
                    }else {
                        state = .connectedNoANCS
                    }
                }
            }
        }
    }
    
    private func onCandidateFound(peripheral: CBPeripheral) {
        if peripheralClientController == nil && peripheral.name?.contains("Pebble") == true {
            proximityDiscovery.stopDiscovery()
            self.peripheral = peripheral
            peripheralClientController = LEClientController(peripheral: peripheral,
                                                            centralManager: centralController.centralManager,
                                                            stateCallback: connStatusChange)
            peripheralClientController!.connect(requireANCS: true)
        }
    }
    
    private func connStatusChange(connStatus: ConnectivityStatus) {
        DispatchQueue.main.async { [self] in
            withAnimation {
                status = connStatus
                if status?.pairingErrorCode != .noError {
                    cancelOrDisconnect(pairFail: true)
                    status = nil
                    state = .pairError
                } else if status?.connected == true && status?.paired == true {
                    if #available(iOS 13.0, *) {
                        if !ancsStatus, peripheral?.ancsAuthorized != true{
                            state = .waitANCS
                        }else {
                            state = .connected
                        }
                    }else {
                        state = .connected
                    }
                }else if status?.connected == true && status?.paired == false {
                    state = .pairing
                }else {
                    state = .connecting
                }
            }
        }
    }
    
    func scanAndConnect() {
        proximityDiscovery.startDiscovery()
        DispatchQueue.main.async { [self] in
            withAnimation {
                state = .scanning
            }
        }
    }
    
    func cancelOrDisconnect(pairFail: Bool = false) {
        proximityDiscovery.stopDiscovery()
        peripheralClientController?.disconnect()
        peripheralClientController = nil
        status = nil
        if !pairFail {
            DispatchQueue.main.async { [self] in
                withAnimation {
                    state = .idle
                }
            }
        }
        
    }
}
