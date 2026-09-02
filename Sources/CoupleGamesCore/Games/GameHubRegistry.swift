import SwiftUI

/// 小游戏类型分类
public enum MiniGameCategory: String, CaseIterable, Codable {
    case physical = "即时物理"
    case tacit = "默契心理"
    case coop = "双人协作"
    case creative = "创意恶搞"
}

/// 统一的小游戏元数据协议
public protocol MiniGameMetadata {
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
    var iconName: String { get }
    var category: MiniGameCategory { get }
    var isNew: Bool { get }
    var bannerColorHex: String { get }
}

/// 标准小游戏定义模型
public struct MiniGameItem: Identifiable, MiniGameMetadata, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let category: MiniGameCategory
    public let isNew: Bool
    public let bannerColorHex: String
    
    public init(id: String, title: String, subtitle: String, iconName: String, category: MiniGameCategory, isNew: Bool = false, bannerColorHex: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.category = category
        self.isNew = isNew
        self.bannerColorHex = bannerColorHex
    }
}

/// 全局游戏盒注册中心 (Game Hub Registry)
public final class GameHubRegistry: ObservableObject {
    public static let shared = GameHubRegistry()
    
    @Published public var availableGames: [MiniGameItem] = []
    
    private init() {
        registerDefaultGames()
    }
    
    private func registerDefaultGames() {
        self.availableGames = [
            MiniGameItem(
                id: "gravity_orbit",
                title: "心动轨道",
                subtitle: "高能引力弹球 · 指尖连击与反弹",
                iconName: "circle.circle.fill",
                category: .physical,
                isNew: false,
                bannerColorHex: "#FF6B8B"
            ),
            MiniGameItem(
                id: "sync_mind",
                title: "默契共振",
                subtitle: "灵魂二选一 · 测测我们有多同步",
                iconName: "heart.text.square.fill",
                category: .tacit,
                isNew: true,
                bannerColorHex: "#9B51E0"
            ),
            MiniGameItem(
                id: "heart_balance",
                title: "同心天平",
                subtitle: "双人协同平衡 · 别让爱心滑落",
                iconName: "scale.3d",
                category: .coop,
                isNew: true,
                bannerColorHex: "#4E54C8"
            ),
            MiniGameItem(
                id: "finger_heart",
                title: "指尖触电",
                subtitle: "同时按下屏幕 · 感受心跳共振",
                iconName: "hand.tap.fill",
                category: .creative,
                isNew: false,
                bannerColorHex: "#FF8E53"
            )
        ]
    }
    
    public func games(for category: MiniGameCategory?) -> [MiniGameItem] {
        guard let category = category else { return availableGames }
        return availableGames.filter { $0.category == category }
    }
}
