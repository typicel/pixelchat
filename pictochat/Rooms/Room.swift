//
//  ColorMultipeerSession.swift
//  pictochat
//

import MultipeerConnectivity
import os
import PencilKit

struct Message: Identifiable{
    let id = UUID()
    let peerId: MCPeerID
    let drawing: PKDrawing
}

class Room: NSObject, ObservableObject {
    private var myPeerId: MCPeerID  // MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let log = Logger()
    
    var roomId: String
    
    init(roomId: String, displayName: String) {
        self.roomId = roomId
        
        myPeerId = MCPeerID(displayName: displayName)
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: self.roomId)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: self.roomId)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var messageHistory: [Message] = []
    
    func send(message: String) {
        log.info("send: sending \"\(message)\" to \(self.session.connectedPeers.count) peers")
        
        if !session.connectedPeers.isEmpty {
            do {
                try session.send(message.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
                let decoder = JSONDecoder()
                if let data = message.data(using: .utf8) {
                    let drawing = try decoder.decode(PKDrawing.self, from: data)
                    messageHistory.append(Message(peerId: self.myPeerId, drawing: drawing))
                }
            } catch {
                log.error("Error for sending: \(String(describing: error))")
            }
            
        } else {
            let decoder = JSONDecoder()
            do {
                if let data = message.data(using: .utf8) {
                    let drawing = try decoder.decode(PKDrawing.self, from: data)
                    messageHistory.append(Message(peerId: self.myPeerId, drawing: drawing))
                }
            } catch {
                log.error("Error decoding")
            }
        }
    }
    
    func invite(peerId: MCPeerID){
        log.info("Inviting peer \(peerId)")
        self.serviceBrowser.invitePeer(peerId, to: self.session, withContext: nil, timeout: 10)
    }
    
    // returns number of connected users
    func numberConnectedUsers() -> Int {
        return self.session.connectedPeers.count
    }
    
    // Updates the display name of the connected user
    func updateDisplayName(displayName: String){
        myPeerId = MCPeerID(displayName: displayName)
    }
}

extension Room: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }

}

extension Room: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}

extension Room: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.rawValue)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        log.info("Within didReceive data")
        do {
            let message = String(data: data, encoding: .utf8)
            let decoder = JSONDecoder()
            let drawing = try decoder.decode(PKDrawing.self, from: data)
            messageHistory.append(Message(peerId: peerID, drawing: drawing))
            log.info("Received message in room \(self.roomId): \(String(describing: message))")
        } catch {
            log.error("Error receiving message in room \(self.roomId)")
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}

