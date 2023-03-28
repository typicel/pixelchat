//
//  ContentView.swift
//  pictochat
//
//  Created by Tyler McCormick on 3/26/23.
//

import SwiftUI

extension Font {
    static func myCustomFont(size: CGFloat) -> Font {
        return Font.custom("SF Mono", size: size)
    }
}

struct ContentView: View {
    @ObservedObject var roomManager = RoomManager(displayName: "grendorb")
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(roomManager.rooms.keys.sorted(), id: \.self) { roomId in
                        NavigationLink {
                            RoomView(room: roomManager.rooms[roomId]!)
                        } label: {
                            Text(roomId)
                                .padding()
                                .font(.myCustomFont(size: 40))
                        } // label
                    } // ForEach
                } // LazyVGrid
            } // VStack
            .navigationTitle("PixelChat")
        } // NavigationView
    } // body
} // ContentView

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
