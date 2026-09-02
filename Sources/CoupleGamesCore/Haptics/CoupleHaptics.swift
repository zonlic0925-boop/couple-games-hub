import SwiftUI
#if os(iOS)
import UIKit
import CoreHaptics
#endif

/// 情侣专属细腻触觉反馈引擎
public final class CoupleHaptics {
    public static let shared = CoupleHaptics()
    
    #if os(iOS)
    private var hapticEngine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif
    
    private init() {
        #if os(iOS)
        prepare()
        #endif
    }
    
    public func prepare() {
        #if os(iOS)
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptics Engine creation failed: \(error)")
        }
        #endif
    }
    
    /// 按钮点击轻微触觉
    public func tap() {
        #if os(iOS)
        impactLight.impactOccurred()
        #endif
    }
    
    /// 挡板击中物理球时的回弹反馈
    public func ballHitPaddle(intensity: Float = 0.8) {
        #if os(iOS)
        if intensity > 0.8 {
            impactHeavy.impactOccurred(intensity: CGFloat(intensity))
        } else {
            impactMedium.impactOccurred(intensity: CGFloat(intensity))
        }
        #endif
    }
    
    /// 球体撞墙触觉
    public func ballHitWall() {
        #if os(iOS)
        impactRigid.impactOccurred(intensity: 0.5)
        #endif
    }
    
    /// 模拟“心跳”双击触感 (用于进球、默契共振高潮时)
    public func heartbeat() {
        #if os(iOS)
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine = hapticEngine else {
            impactMedium.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.impactHeavy.impactOccurred()
            }
            return
        }
        
        do {
            let beat1 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ], relativeTime: 0)
            
            let beat2 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ], relativeTime: 0.14)
            
            let pattern = try CHHapticPattern(events: [beat1, beat2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impactHeavy.impactOccurred()
        }
        #endif
    }
    
    /// 得分成功/匹配成功反馈
    public func success() {
        #if os(iOS)
        notificationGenerator.notificationOccurred(.success)
        #endif
    }
    
    /// 扣分/失误反馈
    public func warning() {
        #if os(iOS)
        notificationGenerator.notificationOccurred(.warning)
        #endif
    }
}
