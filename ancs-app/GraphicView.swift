//
//  GraphicView.swift
//  ancs-app
//
//  Created by crc32 on 11/10/2021.
//

import SwiftUI

struct ImageOverlay: View {
    var title: String
    var desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(
                .system(
                    size: 40, design: .rounded
                )
                .weight(.medium))
                .foregroundColor(.white)
                .padding(.bottom, 1)
            Text(desc).font(.system(.body))
                .foregroundColor(.white)
        }.padding(5)
    }
}

struct GraphicView: View {
    var title: String
    var desc: String
    
    var body: some View {
        Image("splash-bg")
            .resizable()
            .scaledToFill()
            .overlay(ImageOverlay(title: title, desc: desc))
            .frame(maxHeight: 200, alignment: .leading)
            .clipped()
    }
}

#if DEBUG
struct GraphicView_Previews: PreviewProvider {
    static var previews: some View {
        GraphicView(title: "Lorem ipsum", desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer sagittis nisi ut elit venenatis aliquet. ")
    }
}
#endif
