import SwiftUI
import Combine

/// 联机连接类型
public enum OnlineChannelType: String, CaseIterable, Identifiable {
    case localMultipeer = "近场免网直连 (面对面)"
    case remoteRoomCode = "远程 4 位房间码 (异地恋)"
    
    public var id: String { rawValue }
}

@MainActor
public final class LobbyViewModel: ObservableObject {
    @Published public var selectedChannel: OnlineChannelType = .localMultipeer
    @Published public var roomCodeInput: String = ""
    @Published public var generatedRoomCode: String = ""
    @Published public var connectionStatus: ConnectionStatus = .idle
    @Published public var isHosting: Bool = false
    @Published public var activeGameViewModel: OrbitGameViewModel?
    
    private var localTransport = LocalMultipeerTransport()
    private var remoteTransport = RemoteRoomTransport()
    
    private var currentTransport: any NetworkTransport {
        selectedChannel == .localMultipeer ? localTransport : remoteTransport
    }
    
    public init() {
        setupTransportCallbacks()
    }
    
    private func setupTransportCallbacks() {
        let handleStatus: @Sendable (ConnectionStatus) -> Void = { [weak self] status in
            Task { @MainActor in
                guard let self = self else { return }
                self.connectionStatus = status
                
                if case .connected(_, let role) = status {
                    CoupleHaptics.shared.success()
                    let code = self.isHosting ? self.generatedRoomCode : self.roomCodeInput
                    let playMode: GamePlayMode = (role == .host) ? .onlineHost(roomCode: code) : .onlineGuest(roomCode: code)
                    self.activeGameViewModel = OrbitGameViewModel(mode: playMode, transport: self.currentTransport)
                }
            }
        }
        
        localTransport.onStatusChanged = handleStatus
        remoteTransport.onStatusChanged = handleStatus
    }
    
    /// 开始单机同屏游戏
    public func startPassAndPlay() {
        CoupleHaptics.shared.tap()
        activeGameViewModel = OrbitGameViewModel(mode: .localPassAndPlay)
    }
    
    /// 作为房主创建房间
    public func createRoom() {
        CoupleHaptics.shared.tap()
        isHosting = true
        let code = String(format: "%04d", Int.random(in: 1000...9999))
        generatedRoomCode = code
        currentTransport.startHosting(roomCode: code)
    }
    
    /// 作为参与者加入房间
    public func joinRoom() {
        guard roomCodeInput.count == 4 else { return }
        CoupleHaptics.shared.tap()
        isHosting = false
        currentTransport.join(roomCode: roomCodeInput)
    }
    
    public func cancelMatching() {
        currentTransport.disconnect()
        connectionStatus = .idle
        isHosting = false
    }
}
