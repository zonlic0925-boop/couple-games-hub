import Foundation

/// 玩家角色
public enum PlayerRole: String, Codable, Sendable {
    case host   // 房主 (通常为粉方/物理主控端)
    case guest  // 客人 (通常为蓝方/客户端)
    
    public var opponent: PlayerRole {
        self == .host ? .guest : .host
    }
}

/// 统一连接状态
public enum ConnectionStatus: Equatable, Sendable {
    case idle
    case searching
    case connecting(peer: String)
    case connected(peer: String, role: PlayerRole)
    case disconnected(reason: String?)
    case error(message: String)
    
    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// 统一网络传输层接口
public protocol NetworkTransport: AnyObject, Sendable {
    var status: ConnectionStatus { get }
    var onStatusChanged: (@Sendable (ConnectionStatus) -> Void)? { get set }
    var onDataReceived: (@Sendable (Data) -> Void)? { get set }
    
    func startHosting(roomCode: String?)
    func join(roomCode: String)
    func send(data: Data, reliably: Bool)
    func disconnect()
}
