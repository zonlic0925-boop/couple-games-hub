import Foundation

/// 归一化二维坐标点 (0.0 ... 1.0 比例，适配不同机型分辨率屏幕)
public struct NormalizedPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// 物理刚体球状态快照
public struct BallSnapshot: Codable, Equatable, Sendable {
    public var position: NormalizedPoint
    public var velocity: NormalizedPoint
    public var spin: Double
    public var isHeartAccelerated: Bool
    
    public init(position: NormalizedPoint, velocity: NormalizedPoint, spin: Double = 0, isHeartAccelerated: Bool = false) {
        self.position = position
        self.velocity = velocity
        self.spin = spin
        self.isHeartAccelerated = isHeartAccelerated
    }
}

/// 玩家挡板输入与位置快照
public struct PaddleSnapshot: Codable, Equatable, Sendable {
    public var role: PlayerRole
    public var position: NormalizedPoint
    public var touchActive: Bool
    
    public init(role: PlayerRole, position: NormalizedPoint, touchActive: Bool) {
        self.role = role
        self.position = position
        self.touchActive = touchActive
    }
}

/// 游戏即时帧同步载荷
public struct OrbitFramePayload: Codable, Equatable, Sendable {
    public var frameIndex: UInt64
    public var timestamp: Double
    public var ball: BallSnapshot
    public var hostPaddle: PaddleSnapshot
    public var guestPaddle: PaddleSnapshot
    public var hostScore: Int
    public var guestScore: Int
    public var currentRally: Int // 双方连续对打回合数 (心动连击)
    
    public init(frameIndex: UInt64, timestamp: Double, ball: BallSnapshot, hostPaddle: PaddleSnapshot, guestPaddle: PaddleSnapshot, hostScore: Int, guestScore: Int, currentRally: Int) {
        self.frameIndex = frameIndex
        self.timestamp = timestamp
        self.ball = ball
        self.hostPaddle = hostPaddle
        self.guestPaddle = guestPaddle
        self.hostScore = hostScore
        self.guestScore = guestScore
        self.currentRally = currentRally
    }
}

/// 动作与事件包 (可靠通道发送)
public enum OrbitEvent: Codable, Equatable, Sendable {
    case rallyMilestone(count: Int)      // 触发心动连击里程碑
    case scored(scorer: PlayerRole)       // 进球得分
    case sendHeart(from: PlayerRole)      // 屏幕飘爱心互动
    case restartMatch                     // 重新开始游戏
}
