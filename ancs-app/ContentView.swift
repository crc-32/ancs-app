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

struct StatusOverlay: View {
    let statusText: String
    init(statusText: String) {
        self.statusText = statusText
    }
    var body: some View {
        Text(statusText).multilineTextAlignment(.center).padding(.bottom, 10).foregroundColor(.gray).transition(.opacity)
    }
}

struct ContentView: View {
    
    @ObservedObject private var btController = BTController()
    
    let subviews = [
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
    
    var body: some View {
        GeometryReader { metrics in
            VStack() {
                switch btController.state {
                case .idle:
                    subviews[SubviewSlide.welcome.rawValue]
                case .scanning, .pairing, .connecting:
                    subviews[SubviewSlide.connecting.rawValue]
                case .pairError:
                    subviews[SubviewSlide.pairError.rawValue]
                case .connected:
                    subviews[SubviewSlide.success.rawValue]
                case .connectedNoANCS, .waitANCS:
                    subviews[SubviewSlide.noPermission.rawValue]
                }
                VStack() {
                    switch btController.state {
                    case .idle, .pairError:
                        Button(btController.state == .pairError ? "Try again" : "Connect to Pebble") {
                            btController.scanAndConnect()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    case .pairing, .scanning, .connecting:
                        Button("Cancel") {
                            btController.cancelOrDisconnect()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    case .connectedNoANCS, .waitANCS:
                        Button("Open Settings") {
                            UIApplication.shared.open(URL(string: "App-Prefs:root=General")!)
                        }
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    case .connected:
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 56.0))
                    }
                }.frame(maxHeight: .infinity)
                Spacer()
            }
            .accentColor(Color(red: 0.98, green: 0.64, blue: 0.52))
            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            .overlay(StatusOverlay(statusText: btController.state.description).frame(maxWidth: metrics.size.width * 0.95), alignment: .bottom)
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
