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
    
    @State private var peripheralClientController: LEClientController?
    @State private var status: ConnectivityStatus? = nil
    @State private var running = false
    
    private func connStatusChange(connStatus: ConnectivityStatus) {
        status = connStatus
    }
    
    var body: some View {
        VStack() {
            if status?.connected == true && status?.paired == true {
                Text("Connected").multilineTextAlignment(.center)
            }else if status?.connected == true && status?.paired == false {
                Text("Pairing...").multilineTextAlignment(.center)
            }else if status != nil {
                Text("Connecting...").multilineTextAlignment(.center)
            }else {
                Text("Tap below to connect the nearest Pebble").multilineTextAlignment(.center)
            }
            if !running {
                Button("Connect") {
                    running = true
                    centralController.startScan() {discoveredDevice in
                        if peripheralClientController == nil && discoveredDevice.name?.contains("Pebble") == true {
                            peripheralClientController = LEClientController(peripheral: discoveredDevice,
                                                                              centralManager: centralController.centralManager,
                                                                              stateCallback: connStatusChange)
                            peripheralClientController!.connect()
                        }
                    }
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }else {
                Button("Disconnect") {
                    centralController.stopScan()
                    peripheralClientController?.disconnect()
                    peripheralClientController = nil
                    status = nil
                    running = false
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
