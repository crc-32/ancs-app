//
//  ContentView.swift
//  ancs-app
//
//  Created by crc32 on 06/08/2021.
//

import SwiftUI
import CoreBluetooth
import CobbleLE

enum SubviewSlide: Int {
    case welcome = 0
    case connecting = 1
    case success = 2
    case noPermission = 3
    case pairError = 4
}

struct ContentView: View {
    private var centralController = LECentralController()
    private var peripheralServerController = LEPeripheralController()
    private var proximityDiscovery: ProximityDiscovery
    @State private var peripheralClientController: LEClientController?
    @State private var status: ConnectivityStatus? = nil
    @State private var running = false
    @State private var slide = SubviewSlide.welcome
    @State private var ancsState = false
    
    @State private var statusText = "\n"
    
    var subviews = [
        GraphicView(
            title: "Welcome",
            desc: "This app lets you pair your Pebble for seeing notifications (only!) without access to the official Pebble app!"
        ),
        GraphicView(
            title: "Connecting to your watch...",
            desc: "Place or hold the watch next to your device and then confirm any pop-ups you see"
        ),
        GraphicView(
            title: "Success!",
            desc: "Your Pebble should now display notifications from this device!"
        ),
        GraphicView(
            title: "Success! But...",
            desc: "You didn't allow the watch to receive notifications. Please go to Settings > Bluetooth > Pebble, and enable 'Share system notifications', then you're done!"
        ),
        GraphicView(
            title: "Oops!",
            desc: "The watch didn't pair correctly, please try again"
        )
    ]
    
    init() {
        proximityDiscovery = ProximityDiscovery(centralController: centralController)
    }
    
    private func connStatusChange(connStatus: ConnectivityStatus) {
        status = connStatus
        if status?.pairingErrorCode != .noError {
            disconnect()
            running = false
            status = nil
            statusText = "Pairing error"
            slide = .pairError
        } else if status?.connected == true && status?.paired == true {
            if #available(iOS 13.0, *), ancsState {
                statusText = "Connected. Waiting for notification setup..."
            }else {
                ancsDone()
            }
        }else if status?.connected == true && status?.paired == false {
            statusText = "Pairing..."
        }else {
            statusText = "Connecting..."
        }
    }
    
    private func ancsDone() {
        slide = .success
        statusText = "Done!"
    }
    
    private func disconnect() {
        proximityDiscovery.stopDiscovery()
        peripheralClientController?.disconnect()
        peripheralClientController = nil
    }
    
    var body: some View {
        GeometryReader { metrics in
            VStack() {
                subviews[slide.rawValue]
                VStack() {
                    if !running {
                        Button(slide == .pairError ? "Try again" : "Connect to Pebble") {
                            running = true
                            statusText = "Scanning..."
                            slide = .connecting
                            
                            proximityDiscovery.onCandidateFound = {peripheral in
                                if peripheralClientController == nil && peripheral.name?.contains("Pebble") == true {
                                    proximityDiscovery.stopDiscovery()
                                    peripheralClientController = LEClientController(peripheral: peripheral,
                                                                                    centralManager: centralController.centralManager,
                                                                                    stateCallback: connStatusChange)
                                    centralController.ancsUpdateCallback = {ancsPeripheral in
                                        ancsState = ancsPeripheral.ancsAuthorized
                                        if status?.connected == true && status?.paired == true {
                                            if ancsPeripheral.ancsAuthorized {
                                                ancsDone()
                                            }else {
                                                slide = .noPermission
                                                statusText = "Watch was denied notification permission."
                                            }
                                        }
                                    }
                                    peripheralClientController!.connect(requireANCS: true)
                                }
                            }
                            proximityDiscovery.startDiscovery()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    }else if (status?.connected != true || status?.paired != true){
                        Button("Cancel") {
                            disconnect()
                            slide = .welcome
                            status = nil
                            running = false
                            statusText = "\n"
                        }
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    }
                }.frame(maxHeight: .infinity)
                Spacer()
                Text(statusText).multilineTextAlignment(.center).frame(maxWidth: metrics.size.width * 0.95).padding(.bottom, 5).foregroundColor(.gray)
            }
            .accentColor(Color(red: 0.98, green: 0.64, blue: 0.52))
            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
    }
}
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif