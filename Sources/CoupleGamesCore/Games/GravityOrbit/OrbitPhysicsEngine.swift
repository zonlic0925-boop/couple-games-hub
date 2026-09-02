import Foundation

/// 纯 Swift 跨平台高精度 2D 物理与碰撞引擎（房主 Host 端单向权威运算）
public final class OrbitPhysicsEngine: @unchecked Sendable {
    public var ball: BallSnapshot
    public var hostPaddle: PaddleSnapshot
    public var guestPaddle: PaddleSnapshot
    public private(set) var hostScore: Int = 0
    public private(set) var guestScore: Int = 0
    public private(set) var currentRally: Int = 0
    
    public var onScoreUpdated: ((_ scorer: PlayerRole, _ host: Int, _ guest: Int) -> Void)?
    public var onPaddleHit: ((_ role: PlayerRole, _ rally: Int) -> Void)?
    public var onWallHit: (() -> Void)?
    
    private let paddleRadius: Double = 0.08
    private let ballRadius: Double = 0.035
    private let baseSpeed: Double = 0.75
    private let maxSpeed: Double = 1.45
    
    public init() {
        self.ball = BallSnapshot(
            position: NormalizedPoint(x: 0.5, y: 0.5),
            velocity: NormalizedPoint(x: 0.0, y: 0.6)
        )
        self.hostPaddle = PaddleSnapshot(
            role: .host,
            position: NormalizedPoint(x: 0.5, y: 0.15),
            touchActive: false
        )
        self.guestPaddle = PaddleSnapshot(
            role: .guest,
            position: NormalizedPoint(x: 0.5, y: 0.85),
            touchActive: false
        )
        resetBall(servingTo: .host)
    }
    
    public func resetBall(servingTo role: PlayerRole) {
        let initialVy = (role == .host ? -baseSpeed : baseSpeed)
        let randomVx = Double.random(in: -0.25...0.25)
        ball = BallSnapshot(
            position: NormalizedPoint(x: 0.5, y: 0.5),
            velocity: NormalizedPoint(x: randomVx, y: initialVy),
            isHeartAccelerated: false
        )
        currentRally = 0
    }
    
    /// 物理步进计算 (每帧调用，dt 约为 1/60 秒)
    public func step(deltaTime dt: Double) {
        var px = ball.position.x + ball.velocity.x * dt
        var py = ball.position.y + ball.velocity.y * dt
        var vx = ball.velocity.x
        var vy = ball.velocity.y
        
        // 左右侧边界反弹
        if px - ballRadius <= 0.0 {
            px = ballRadius
            vx = abs(vx)
            onWallHit?()
        } else if px + ballRadius >= 1.0 {
            px = 1.0 - ballRadius
            vx = -abs(vx)
            onWallHit?()
        }
        
        // 与 Host 挡板碰撞检测 (上方 / y 较小处)
        let dHostX = px - hostPaddle.position.x
        let dHostY = py - hostPaddle.position.y
        let distHost = sqrt(dHostX * dHostX + dHostY * dHostY)
        if distHost <= (paddleRadius + ballRadius) && vy < 0 {
            // 反弹并施加横向切线角
            let impactFactor = (px - hostPaddle.position.x) / paddleRadius
            vx = impactFactor * 0.9
            let currentSpeed = min(sqrt(vx * vx + vy * vy) * 1.05, maxSpeed)
            vy = sqrt(max(0.01, currentSpeed * currentSpeed - vx * vx))
            currentRally += 1
            ball.isHeartAccelerated = currentRally >= 5
            onPaddleHit?(.host, currentRally)
        }
        
        // 与 Guest 挡板碰撞检测 (下方 / y 较大处)
        let dGuestX = px - guestPaddle.position.x
        let dGuestY = py - guestPaddle.position.y
        let distGuest = sqrt(dGuestX * dGuestX + dGuestY * dGuestY)
        if distGuest <= (paddleRadius + ballRadius) && vy > 0 {
            let impactFactor = (px - guestPaddle.position.x) / paddleRadius
            vx = impactFactor * 0.9
            let currentSpeed = min(sqrt(vx * vx + vy * vy) * 1.05, maxSpeed)
            vy = -sqrt(max(0.01, currentSpeed * currentSpeed - vx * vx))
            currentRally += 1
            ball.isHeartAccelerated = currentRally >= 5
            onPaddleHit?(.guest, currentRally)
        }
        
        // 胜负与得分检测 (越过底线)
        if py < -0.05 {
            // Guest 赢一分
            guestScore += 1
            onScoreUpdated?(.guest, hostScore, guestScore)
            resetBall(servingTo: .host)
            return
        } else if py > 1.05 {
            // Host 赢一分
            hostScore += 1
            onScoreUpdated?(.host, hostScore, guestScore)
            resetBall(servingTo: .guest)
            return
        }
        
        ball.position = NormalizedPoint(x: px, y: py)
        ball.velocity = NormalizedPoint(x: vx, y: vy)
    }
    
    /// 更新挡板目标位置
    public func updatePaddle(role: PlayerRole, normalizedX: Double, normalizedY: Double) {
        let clampedX = min(max(normalizedX, paddleRadius), 1.0 - paddleRadius)
        switch role {
        case .host:
            // Host 限制在上方区域 (0.05 ... 0.45)
            let clampedY = min(max(normalizedY, 0.05), 0.45)
            hostPaddle.position = NormalizedPoint(x: clampedX, y: clampedY)
            hostPaddle.touchActive = true
        case .guest:
            // Guest 限制在下方区域 (0.55 ... 0.95)
            let clampedY = min(max(normalizedY, 0.55), 0.95)
            guestPaddle.position = NormalizedPoint(x: clampedX, y: clampedY)
            guestPaddle.touchActive = true
        }
    }
    
    public func restart() {
        hostScore = 0
        guestScore = 0
        currentRally = 0
        resetBall(servingTo: .host)
    }
}
