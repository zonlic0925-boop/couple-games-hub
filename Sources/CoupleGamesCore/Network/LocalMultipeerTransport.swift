import Foundation
#if canImport(MultipeerConnectivity)
import MultipeerConnectivity
#endif

/// 基于 Apple MultipeerConnectivity 的局域网/蓝牙极速免流直连传输器
public final class LocalMultipeerTransport: NSObject, NetworkTransport, @unchecked Sendable {
    public private(set) var status: ConnectionStatus = .idle {
        didSet {
            onStatusChanged?(status)
        }
    }
    
    public var onStatusChanged: (@Sendable (ConnectionStatus) -> Void)?
    public var onDataReceived: (@Sendable (Data) -> Void)?
    
    private let serviceType = "cpl-game"
    
    #if canImport(MultipeerConnectivity)
    private var myPeerId: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var currentRole: PlayerRole = .host
    private var targetRoomCode: String?
    #endif
    
    public override init() {
        #if canImport(MultipeerConnectivity)
        let deviceName = ProcessInfo.processInfo.hostName
        self.myPeerId = MCPeerID(displayName: deviceName)
        #endif
        super.init()
    }
    
    public func startHosting(roomCode: String?) {
        #if canImport(MultipeerConnectivity)
        disconnect()
        self.currentRole = .host
        self.targetRoomCode = roomCode
        self.status = .searching
        
        let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        self.session = newSession
        
        var discoveryInfo: [String: String] = [:]
        if let code = roomCode {
            discoveryInfo["room"] = code
        }
        
        let adv = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: discoveryInfo, serviceType: serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        self.advertiser = adv
        #else
        self.status = .error(message: "MultipeerConnectivity not supported on this platform")
        #endif
    }
    
    public func join(roomCode: String) {
        #if canImport(MultipeerConnectivity)
        disconnect()
        self.currentRole = .guest
        self.targetRoomCode = roomCode
        self.status = .searching
        
        let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        self.session = newSession
        
        let brow = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        brow.delegate = self
        brow.startBrowsingForPeers()
        self.browser = brow
        #else
        self.status = .error(message: "MultipeerConnectivity not supported on this platform")
        #endif
    }
    
    public func send(data: Data, reliably: Bool) {
        #if canImport(MultipeerConnectivity)
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        let mode: MCSessionSendDataMode = reliably ? .reliable : .unreliable
        do {
            try session.send(data, toPeers: session.connectedPeers, with: mode)
        } catch {
            print("Multipeer send failed: \(error)")
        }
        #endif
    }
    
    public func disconnect() {
        #if canImport(MultipeerConnectivity)
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        #endif
        self.status = .idle
    }
}

#if canImport(MultipeerConnectivity)
extension LocalMultipeerTransport: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connected:
                self.status = .connected(peer: peerID.displayName, role: self.currentRole)
            case .connecting:
                self.status = .connecting(peer: peerID.displayName)
            case .notConnected:
                self.status = .disconnected(reason: "Peer disconnected")
            @unknown default:
                break
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        onDataReceived?(data)
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension LocalMultipeerTransport: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 房主直接接受邀请
        invitationHandler(true, self.session)
    }
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.status = .error(message: error.localizedDescription)
        }
    }
}

extension LocalMultipeerTransport: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let session = self.session else { return }
        
        // 校验房间码是否匹配
        if let targetCode = self.targetRoomCode {
            if let advertisedCode = info?["room"], advertisedCode == targetCode {
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            }
        } else {
            // 未指定房间码则直连发现的首个节点
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.status = .error(message: error.localizedDescription)
        }
    }
}
#endif
