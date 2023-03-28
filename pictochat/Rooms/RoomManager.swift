//
//  RoomManager.swift
//  pictochat
//
//  Created by Tyler McCormick on 3/26/23.
//
import MultipeerConnectivity
import os

class RoomManager: ObservableObject {
    @Published var rooms: [String: Room] = [:]
    private var log = Logger()
    
    init(displayName: String) {
        let roomIDs = ["A", "B", "C", "D"]
        for id in roomIDs {
            log.info("Initializing room \(id)")
            rooms[id] = Room(roomId: id, displayName: displayName)
        }
    }
    
    // Iterates through each room and updates the display name for the current user
    func updateName(displayName: String) {
        for room in rooms.values {
            room.updateDisplayName(displayName: displayName)
        }
    }
    
}
