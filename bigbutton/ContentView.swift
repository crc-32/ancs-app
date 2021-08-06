//
//  ContentView.swift
//  bigbutton
//
//  Created by crc32 on 06/08/2021.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    var btDelegate = BTDelegate()
    
    var body: some View {
        VStack() {
            Button("do the thing") {
                btDelegate.startScan()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
