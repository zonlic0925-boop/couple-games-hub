import SwiftUI

public struct MainLobbyView: View {
    @StateObject private var viewModel = LobbyViewModel()
    @ObservedObject private var registry = GameHubRegistry.shared
    
    @State private var selectedCategory: MiniGameCategory? = nil
    @State private var activeGameItem: MiniGameItem? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            CoupleColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题
                headerView
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                
                // 联机/同屏状态栏
                connectionModeBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // 分类筛选器 Tab
                categoryFilterBar
                    .padding(.bottom, 12)
                
                // 游戏列表滚动视图 (Game Box)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(registry.games(for: selectedCategory)) { game in
                            gameCard(for: game)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(item: $activeGameItem) { game in
            destinationGameView(for: game)
        }
        .sheet(isPresented: $viewModel.showingRoomCodeSheet) {
            RoomCodeSheet(viewModel: viewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text("💖")
                    .font(.system(size: 26))
                Text("情侣游戏盒")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(CoupleColors.textDark)
            }
            Text("双人同屏 · 远程联机 · 甜蜜升温")
                .font(.system(size: 13))
                .foregroundColor(CoupleColors.textMuted)
        }
    }
    
    private var connectionModeBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(viewModel.isConnected ? "已连接爱人" : "面对面同屏模式")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(CoupleColors.textDark)
            }
            Spacer()
            
            Button(action: { viewModel.showingRoomCodeSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("联机匹配")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(CoupleColors.primaryGradient))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        )
    }
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryTab(title: "全部游戏", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(MiniGameCategory.allCases, id: \.self) { cat in
                    categoryTab(title: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func categoryTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? CoupleColors.pinkMain : Color.white.opacity(0.8))
                )
                .foregroundColor(isSelected ? .white : CoupleColors.textDark)
        }
    }
    
    private func gameCard(for game: MiniGameItem) -> some View {
        Button(action: { activeGameItem = game }) {
            HStack(spacing: 16) {
                // 图标 / 标志
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: game.bannerColorHex) ?? CoupleColors.pinkMain)
                        .frame(width: 58, height: 58)
                    Image(systemName: game.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(game.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(CoupleColors.textDark)
                        if game.isNew {
                            Text("NEW")
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(CoupleColors.pinkMain))
                                .foregroundColor(.white)
                        }
                    }
                    Text(game.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(CoupleColors.textMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CoupleColors.textMuted.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func destinationGameView(for game: MiniGameItem) -> some View {
        if game.id == "sync_mind" {
            SyncMindGameView(onExit: { activeGameItem = nil })
        } else {
            // 默认为心动轨道即时物理游戏
            OrbitGameView(viewModel: OrbitGameViewModel(transport: viewModel.transport)) {
                activeGameItem = nil
            }
        }
    }
}
