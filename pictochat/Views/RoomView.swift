//
//  RoomView.swift
//  pictochat
//
//  Created by Tyler McCormick on 3/26/23.
//

import SwiftUI
import PencilKit

struct RoomView: View {
    @ObservedObject var room: Room
    
    @State private var message = ""
    
    let canvasView = PKCanvasViewRepresentable()
    
    func encodeAndSend() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(canvasView.canvas.drawing)
            let message = String(data: data, encoding: .utf8)!
            room.send(message: message)
        } catch {
            fatalError("Error encoding canvas drawing")
        }
    }
    
    
    var body: some View {
        VStack {
            Text("Room \(room.roomId)")
                .font(.title)
            
            ScrollView {
                ForEach(room.messageHistory) { message in
                    HStack {
                        Text("\(message.peerId.displayName): ")
                        Image(uiImage: message.drawing.image(from: message.drawing.bounds, scale: UIScreen.main.scale))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
            
            Spacer()
            
            // Drawing section
            ZStack {
                Rectangle()
                    .size(width: 200, height: 200)
                    .fill(.clear)
                
                canvasView
                    .frame(height: 100.0)
                    .border(Color.gray, width: 5)
                
            }
            
            TextField("Enter message", text: $message)
            
            
            Button("Send") {
                encodeAndSend()
                canvasView.canvas.drawing = PKDrawing()
            }
            
        } .padding()
        
        
        
    }
}

struct PKCanvasViewRepresentable: UIViewRepresentable {
    var canvas = PKCanvasView()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.tool = PKInkingTool(.pen, color: .black, width: 15)
        canvas.drawingPolicy = .anyInput
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}

struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        RoomView(room: Room(roomId: "X", displayName: "Grendorb"))
    }
}
