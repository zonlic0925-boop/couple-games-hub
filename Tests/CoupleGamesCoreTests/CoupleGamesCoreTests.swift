import XCTest
@testable import CoupleGamesCore

final class CoupleGamesCoreTests: XCTestCase {
    
    func testPhysicsEngineStepAndBoundaryBounce() {
        let engine = OrbitPhysicsEngine()
        
        // 验证初始状态
        XCTAssertEqual(engine.hostScore, 0)
        XCTAssertEqual(engine.guestScore, 0)
        XCTAssertEqual(engine.currentRally, 0)
        
        // 执行 10 帧物理模拟步进
        for _ in 0..<10 {
            engine.step(deltaTime: 1.0 / 60.0)
        }
        
        // 坐标应该保持在归一化合理区间内
        XCTAssertGreaterThanOrEqual(engine.ball.position.x, 0.0)
        XCTAssertLessThanOrEqual(engine.ball.position.x, 1.0)
    }
    
    func testPaddlePositionClamping() {
        let engine = OrbitPhysicsEngine()
        
        // 测试 Host 挡板边界限制 (上限与下限)
        engine.updatePaddle(role: .host, normalizedX: -0.5, normalizedY: 0.9)
        XCTAssertGreaterThanOrEqual(engine.hostPaddle.position.x, 0.05)
        XCTAssertLessThanOrEqual(engine.hostPaddle.position.y, 0.45)
        
        // 测试 Guest 挡板边界限制
        engine.updatePaddle(role: .guest, normalizedX: 1.5, normalizedY: 0.1)
        XCTAssertLessThanOrEqual(engine.guestPaddle.position.x, 0.95)
        XCTAssertGreaterThanOrEqual(engine.guestPaddle.position.y, 0.55)
    }
    
    func testSnapshotEncodingDecoding() throws {
        let originalPayload = OrbitFramePayload(
            frameIndex: 42,
            timestamp: 1725280000.0,
            ball: BallSnapshot(
                position: NormalizedPoint(x: 0.5, y: 0.6),
                velocity: NormalizedPoint(x: 0.1, y: -0.8),
                spin: 0.0,
                isHeartAccelerated: true
            ),
            hostPaddle: PaddleSnapshot(role: .host, position: NormalizedPoint(x: 0.5, y: 0.2), touchActive: true),
            guestPaddle: PaddleSnapshot(role: .guest, position: NormalizedPoint(x: 0.5, y: 0.8), touchActive: true),
            hostScore: 2,
            guestScore: 3,
            currentRally: 6
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPayload)
        
        let decoder = JSONDecoder()
        let decodedPayload = try decoder.decode(OrbitFramePayload.self, from: data)
        
        XCTAssertEqual(originalPayload, decodedPayload)
        XCTAssertTrue(decodedPayload.ball.isHeartAccelerated)
        XCTAssertEqual(decodedPayload.currentRally, 6)
    }
}
