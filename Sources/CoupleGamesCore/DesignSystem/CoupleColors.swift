import SwiftUI

/// 情侣专属柔和色彩系统
public enum CoupleColors {
    // 主色调：温暖蜜桃粉与沉稳云雾蓝
    public static let sweetPink = Color(red: 255/255, green: 130/255, blue: 155/255)
    public static let softRose = Color(red: 255/255, green: 182/255, blue: 193/255)
    public static let vibrantPink = Color(red: 255/255, green: 90/255, blue: 130/255)
    
    public static let calmBlue = Color(red: 100/255, green: 160/255, blue: 245/255)
    public static let lightCyan = Color(red: 175/255, green: 220/255, blue: 255/255)
    public static let deepIndigo = Color(red: 60/255, green: 90/255, blue: 160/255)
    
    // 背景与质感
    public static let warmBackground = Color(red: 250/255, green: 248/255, blue: 252/255)
    public static let darkBackground = Color(red: 22/255, green: 20/255, blue: 30/255)
    public static let cardSurface = Color.white.opacity(0.85)
    public static let cardBorder = Color.white.opacity(0.4)
    
    // 渐变方案
    public static let romanceGradient = LinearGradient(
        colors: [sweetPink, Color(red: 255/255, green: 150/255, blue: 190/255), calmBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let hostPlayerGradient = LinearGradient(
        colors: [vibrantPink, sweetPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let guestPlayerGradient = LinearGradient(
        colors: [calmBlue, lightCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let heartGlow = RadialGradient(
        colors: [sweetPink.opacity(0.7), sweetPink.opacity(0.0)],
        center: .center,
        startRadius: 10,
        endRadius: 80
    )
}
