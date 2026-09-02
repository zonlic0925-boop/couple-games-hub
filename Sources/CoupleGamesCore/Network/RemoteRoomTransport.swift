import Foundation

/// 基于轻量 WebSocket / 房间码广播的远程网络传输器
public final class RemoteRoomTransport: NSObject, NetworkTransport, @unchecked Sendable {
    public private(set) var status: ConnectionStatus = .idle {
        didSet {
            onStatusChanged?(status)
        }
    }
    
    public var onStatusChanged: (@Sendable (ConnectionStatus) -> Void)?
    public var onDataReceived: (@Sendable (Data) -> Void)?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var roomCode: String?
    private var currentRole: PlayerRole = .host
    
    // 默认可配置公共免费信令中继或私有部署 WebSocket 服务
    private let serverBaseURL: String
    
    public init(serverBaseURL: String = "wss://relay.couplegames.local/ws") {
        self.serverBaseURL = serverBaseURL
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    public func startHosting(roomCode: String?) {
        disconnect()
        let code = roomCode ?? String(format: "%04d", Int.random(in: 1000...9999))
        self.roomCode = code
        self.currentRole = .host
        connectToRelay(code: code, role: .host)
    }
    
    public func join(roomCode: String) {
        disconnect()
        self.roomCode = roomCode
        self.currentRole = .guest
        connectToRelay(code: roomCode, role: .guest)
    }
    
    private func connectToRelay(code: String, role: PlayerRole) {
        self.status = .searching
        guard let url = URL(string: "\(serverBaseURL)?room=\(code)&role=\(role.rawValue)") else {
            self.status = .error(message: "Invalid relay server URL")
            return
        }
        
        let task = urlSession?.webSocketTask(with: url)
        self.webSocketTask = task
        task?.resume()
        
        listenForMessages()
        
        // 模拟/真实握手完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if case .searching = self.status {
                self.status = .connected(peer: "Room #\(code)", role: role)
            }
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.onDataReceived?(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.onDataReceived?(data)
                    }
                @unknown default:
                    break
                }
                self.listenForMessages()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.status = .error(message: error.localizedDescription)
                }
            }
        }
    }
    
    public func send(data: Data, reliably: Bool) {
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Remote send error: \(error)")
            }
        }
    }
    
    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        self.status = .idle
    }
}

extension RemoteRoomTransport: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // Socket 连接建立
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async { [weak self] in
            self?.status = .disconnected(reason: "Remote session closed")
        }
    }
}
