//
//  ContentView.swift
//  bigbutton
//
//  Created by crc32 on 06/08/2021.
//

import SwiftUI
import CoreBluetooth
import CobbleLE

struct ContentView: View {
    private var centralController = LECentralController()
    private var peripheralServerController = LEPeripheralController()
    private var proximityDiscovery: ProximityDiscovery
    @State private var peripheralClientController: LEClientController?
    @State private var status: ConnectivityStatus? = nil
    @State private var running = false
    
    @State private var statusText = "Tap below to connect the nearest Pebble"
    
    init() {
        proximityDiscovery = ProximityDiscovery(centralController: centralController)
    }
    
    private func connStatusChange(connStatus: ConnectivityStatus) {
        status = connStatus
        if status?.connected == true && status?.paired == true {
            statusText = "Connected. You can now forget about this app!"
        }else if status?.connected == true && status?.paired == false {
            statusText = "Pairing..."
        }else {
            statusText = "Connecting..."
        }
    }
    
    var body: some View {
        VStack() {
            Text(statusText).multilineTextAlignment(.center)
            if !running {
                Button("Connect") {
                    running = true
                    statusText = "Scanning... (Put Pebble on Bluetooth settings page & hold device close)"
                    proximityDiscovery.onCandidateFound = {peripheral in
                        if peripheralClientController == nil && peripheral.name?.contains("Pebble") == true {
                            proximityDiscovery.stopDiscovery()
                            peripheralClientController = LEClientController(peripheral: peripheral,
                                                                            centralManager: centralController.centralManager,
                                                                            stateCallback: connStatusChange)
                            peripheralClientController!.connect()
                        }
                    }
                    proximityDiscovery.startDiscovery()
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }else {
                Button("Disconnect") {
                    proximityDiscovery.stopDiscovery()
                    peripheralClientController?.disconnect()
                    peripheralClientController = nil
                    status = nil
                    running = false
                    statusText = "Tap below to connect the nearest Pebble"
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
