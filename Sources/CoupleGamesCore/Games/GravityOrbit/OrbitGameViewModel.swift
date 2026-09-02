import SwiftUI
import Combine

/// 游戏运行模式
public enum GamePlayMode: Equatable {
    case localPassAndPlay         // 单机同屏 (一人上半屏，一人下半屏)
    case onlineHost(roomCode: String)  // 联机 Host 房主端
    case onlineGuest(roomCode: String) // 联机 Guest 参与端
}

@MainActor
public final class OrbitGameViewModel: ObservableObject {
    @Published public var ballPosition: NormalizedPoint = NormalizedPoint(x: 0.5, y: 0.5)
    @Published public var hostPaddlePos: NormalizedPoint = NormalizedPoint(x: 0.5, y: 0.15)
    @Published public var guestPaddlePos: NormalizedPoint = NormalizedPoint(x: 0.5, y: 0.85)
    @Published public var hostScore: Int = 0
    @Published public var guestScore: Int = 0
    @Published public var currentRally: Int = 0
    @Published public var isHeartAccelerated: Bool = false
    @Published public var floatingHearts: [UUID] = []
    
    public let mode: GamePlayMode
    private let engine = OrbitPhysicsEngine()
    private var transport: (any NetworkTransport)?
    private var displayLinkTimer: AnyCancellable?
    private var frameCounter: UInt64 = 0
    
    public init(mode: GamePlayMode, transport: (any NetworkTransport)? = nil) {
        self.mode = mode
        self.transport = transport
        setupEngineCallbacks()
        setupNetworkSync()
    }
    
    private func setupEngineCallbacks() {
        engine.onScoreUpdated = { [weak self] scorer, hScore, gScore in
            Task { @MainActor in
                guard let self = self else { return }
                self.hostScore = hScore
                self.guestScore = gScore
                CoupleHaptics.shared.heartbeat()
                self.broadcastEvent(.scored(scorer: scorer))
            }
        }
        
        engine.onPaddleHit = { [weak self] role, rally in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentRally = rally
                let intensity = min(1.0, 0.5 + Float(rally) * 0.08)
                CoupleHaptics.shared.ballHitPaddle(intensity: intensity)
                if rally == 5 || rally == 10 {
                    self.spawnHeartParticle()
                    self.broadcastEvent(.rallyMilestone(count: rally))
                }
            }
        }
        
        engine.onWallHit = {
            CoupleHaptics.shared.ballHitWall()
        }
    }
    
    private func setupNetworkSync() {
        guard let transport = transport else { return }
        
        transport.onDataReceived = { [weak self] data in
            Task { @MainActor in
                guard let self = self else { return }
                // 优先解析帧同步
                if let payload = try? JSONDecoder().decode(OrbitFramePayload.self, from: data) {
                    if case .onlineGuest = self.mode {
                        self.applyRemoteSnapshot(payload)
                    }
                } else if let paddle = try? JSONDecoder().decode(PaddleSnapshot.self, from: data) {
                    // Host 端接收来自 Guest 的挡板坐标
                    if case .onlineHost = self.mode, paddle.role == .guest {
                        self.engine.updatePaddle(role: .guest, normalizedX: paddle.position.x, normalizedY: paddle.position.y)
                    }
                } else if let event = try? JSONDecoder().decode(OrbitEvent.self, from: data) {
                    self.handleRemoteEvent(event)
                }
            }
        }
    }
    
    public func startGameLoop() {
        let fps: Double = 60.0
        let interval = 1.0 / fps
        displayLinkTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(dt: interval)
            }
    }
    
    public func stopGameLoop() {
        displayLinkTimer?.cancel()
        displayLinkTimer = nil
    }
    
    private func tick(dt: Double) {
        frameCounter += 1
        
        switch mode {
        case .localPassAndPlay, .onlineHost:
            engine.step(deltaTime: dt)
            ballPosition = engine.ball.position
            hostPaddlePos = engine.hostPaddle.position
            guestPaddlePos = engine.guestPaddle.position
            isHeartAccelerated = engine.ball.isHeartAccelerated
            
            // 联机 Host 房主端：广播权威帧快照
            if case .onlineHost = mode {
                let payload = OrbitFramePayload(
                    frameIndex: frameCounter,
                    timestamp: Date().timeIntervalSince1970,
                    ball: engine.ball,
                    hostPaddle: engine.hostPaddle,
                    guestPaddle: engine.guestPaddle,
                    hostScore: engine.hostScore,
                    guestScore: engine.guestScore,
                    currentRally: engine.currentRally
                )
                if let data = try? JSONEncoder().encode(payload) {
                    transport?.send(data: data, reliably: false)
                }
            }
            
        case .onlineGuest:
            // 客户端以插值渲染接收到的状态，并向 Host 发送本地触摸坐标
            let myPaddle = PaddleSnapshot(role: .guest, position: guestPaddlePos, touchActive: true)
            if let data = try? JSONEncoder().encode(myPaddle) {
                transport?.send(data: data, reliably: false)
            }
        }
    }
    
    private func applyRemoteSnapshot(_ payload: OrbitFramePayload) {
        self.ballPosition = payload.ball.position
        self.hostPaddlePos = payload.hostPaddle.position
        self.hostScore = payload.hostScore
        self.guestScore = payload.guestScore
        self.currentRally = payload.currentRally
        self.isHeartAccelerated = payload.ball.isHeartAccelerated
    }
    
    private func handleRemoteEvent(_ event: OrbitEvent) {
        switch event {
        case .rallyMilestone:
            spawnHeartParticle()
            CoupleHaptics.shared.heartbeat()
        case .scored:
            CoupleHaptics.shared.heartbeat()
        case .sendHeart:
            spawnHeartParticle()
            CoupleHaptics.shared.tap()
        case .restartMatch:
            engine.restart()
        }
    }
    
    public func updatePaddleTouch(role: PlayerRole, normalizedX: Double, normalizedY: Double) {
        switch mode {
        case .localPassAndPlay:
            engine.updatePaddle(role: role, normalizedX: normalizedX, normalizedY: normalizedY)
        case .onlineHost:
            if role == .host {
                engine.updatePaddle(role: .host, normalizedX: normalizedX, normalizedY: normalizedY)
            }
        case .onlineGuest:
            if role == .guest {
                guestPaddlePos = NormalizedPoint(x: normalizedX, y: normalizedY)
            }
        }
    }
    
    public func sendHeartInteraction() {
        spawnHeartParticle()
        CoupleHaptics.shared.heartbeat()
        let myRole: PlayerRole = (mode == .onlineGuest(roomCode: "")) ? .guest : .host
        broadcastEvent(.sendHeart(from: myRole))
    }
    
    private func spawnHeartParticle() {
        let heartId = UUID()
        floatingHearts.append(heartId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.floatingHearts.removeAll(where: { $0 == heartId })
        }
    }
    
    private func broadcastEvent(_ event: OrbitEvent) {
        guard let transport = transport, let data = try? JSONEncoder().encode(event) else { return }
        transport.send(data: data, reliably: true)
    }
}
