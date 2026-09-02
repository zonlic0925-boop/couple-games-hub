import SwiftUI

// ==========================================
// 1. 色彩与设计系统
// ==========================================
public enum CoupleColors {
    public static let pinkMain = Color(red: 255/255, green: 107/255, blue: 139/255)
    public static let pinkSoft = Color(red: 255/255, green: 168/255, blue: 186/255)
    public static let blueMain = Color(red: 108/255, green: 146/255, blue: 244/255)
    public static let blueSoft = Color(red: 163/255, green: 188/255, blue: 249/255)
    public static let textDark = Color(red: 44/255, green: 44/255, blue: 46/255)
    public static let textMuted = Color(red: 142/255, green: 142/255, blue: 147/255)
    
    public static let backgroundGradient = LinearGradient(
        colors: [Color(red: 255/255, green: 240/255, blue: 244/255), Color(red: 245/255, green: 247/255, blue: 255/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let primaryGradient = LinearGradient(
        colors: [pinkMain, Color(red: 255/255, green: 142/255, blue: 83/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// ==========================================
// 2. 游戏盒游戏数据结构
// ==========================================
public struct MiniGameItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let category: String
    public let isNew: Bool
    public let badgeText: String?
    
    public init(id: String, title: String, subtitle: String, iconName: String, category: String, isNew: Bool = false, badgeText: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.category = category
        self.isNew = isNew
        self.badgeText = badgeText
    }
}

// ==========================================
// 3. 游戏 1：心动轨道 (即时物理碰撞视图)
// ==========================================
public struct OrbitGameView: View {
    var onExit: () -> Void
    
    @State private var ballX: CGFloat = 0.5
    @State private var ballY: CGFloat = 0.5
    @State private var ballVX: CGFloat = 0.3
    @State private var ballVY: CGFloat = 0.5
    @State private var hostPaddleX: CGFloat = 0.5
    @State private var guestPaddleX: CGFloat = 0.5
    @State private var hostScore: Int = 0
    @State private var guestScore: Int = 0
    @State private var rallyCount: Int = 0
    @State private var isAccelerated: Bool = false
    @State private var floatingHearts: [Int] = []
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 21/255, green: 22/255, blue: 30/255)
                    .ignoresSafeArea()
                
                // 中场分隔虚线
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 8]))
                .foregroundColor(.white.opacity(0.15))
                
                // 顶部玩家挡板 (Guest - 蓝方)
                RoundedRectangle(cornerRadius: 8)
                    .fill(CoupleColors.blueMain)
                    .frame(width: geo.size.width * 0.28, height: 16)
                    .position(x: guestPaddleX * geo.size.width, y: geo.size.height * 0.12)
                
                // 底部玩家挡板 (Host - 粉方)
                RoundedRectangle(cornerRadius: 8)
                    .fill(CoupleColors.pinkMain)
                    .frame(width: geo.size.width * 0.28, height: 16)
                    .position(x: hostPaddleX * geo.size.width, y: geo.size.height * 0.88)
                
                // 爱心小球
                Text(isAccelerated ? "🔥" : "💖")
                    .font(.system(size: geo.size.width * 0.08))
                    .position(x: ballX * geo.size.width, y: ballY * geo.size.height)
                
                // 浮动爱心
                ForEach(floatingHearts, id: \.self) { _ in
                    Text("💕")
                        .font(.system(size: 26))
                        .position(x: CGFloat.random(in: 60...(geo.size.width - 60)), y: geo.size.height * 0.7)
                        .transition(.asymmetric(insertion: .scale, removal: .opacity))
                }
                
                // HUD 顶部与底部栏
                VStack {
                    HStack {
                        Button(action: onExit) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("退出")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.white.opacity(0.2)))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Text("💙 \(guestScore)")
                                .foregroundColor(CoupleColors.blueSoft)
                            Text(isAccelerated ? "🔥 x\(rallyCount)" : "连击: \(rallyCount)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("\(hostScore) 💖")
                                .foregroundColor(CoupleColors.pinkSoft)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.12)))
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    HStack {
                        Text("轻触上下半区滑动挡板")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Button(action: {
                            floatingHearts.append(Int.random(in: 1...99999))
                        }) {
                            Text("💌 发送爱心")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(CoupleColors.pinkMain))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let nx = max(0.15, min(0.85, value.location.x / geo.size.width))
                        if value.location.y < geo.size.height / 2 {
                            guestPaddleX = nx
                        } else {
                            hostPaddleX = nx
                        }
                    }
            )
        }
        .onReceive(timer) { _ in
            stepPhysics()
        }
    }
    
    private func stepPhysics() {
        let dt: CGFloat = 0.016
        ballX += ballVX * dt
        ballY += ballVY * dt
        
        // 左右墙壁弹射
        if ballX <= 0.04 {
            ballX = 0.04
            ballVX = abs(ballVX)
        } else if ballX >= 0.96 {
            ballX = 0.96
            ballVX = -abs(ballVX)
        }
        
        // 碰撞下挡板 (Host)
        if abs(ballY - 0.88) < 0.03 && abs(ballX - hostPaddleX) < 0.16 && ballVY > 0 {
            ballVY = -abs(ballVY)
            ballVX += (ballX - hostPaddleX) * 0.4
            onHit()
        }
        
        // 碰撞上挡板 (Guest)
        if abs(ballY - 0.12) < 0.03 && abs(ballX - guestPaddleX) < 0.16 && ballVY < 0 {
            ballVY = abs(ballVY)
            ballVX += (ballX - guestPaddleX) * 0.4
            onHit()
        }
        
        // 得分判定
        if ballY < 0.05 {
            hostScore += 1
            resetBall(hostScored: true)
        } else if ballY > 0.95 {
            guestScore += 1
            resetBall(hostScored: false)
        }
    }
    
    private func onHit() {
        rallyCount += 1
        if rallyCount >= 5 && !isAccelerated {
            isAccelerated = true
            ballVX *= 1.25
            ballVY *= 1.25
        }
    }
    
    private func resetBall(hostScored: Bool) {
        ballX = 0.5
        ballY = 0.5
        rallyCount = 0
        isAccelerated = false
        ballVX = CGFloat.random(in: -0.2...0.2)
        ballVY = hostScored ? -0.45 : 0.45
    }
}

// ==========================================
// 4. 游戏 2：默契共振 (灵魂问答与惩罚)
// ==========================================
public struct SyncMindGameView: View {
    var onExit: () -> Void
    
    struct Question {
        let prompt: String
        let a: String
        let b: String
        let penalty: String
    }
    
    let questions: [Question] = [
        Question(prompt: "周末休息，更倾向于怎么过？", a: "🛋️ 窝在沙发看剧点外卖", b: "☕ 出门探店看展逛街", penalty: "背着对方在客厅走一圈！"),
        Question(prompt: "旅行途中突然下大雨？", a: "☔ 随遇而安在咖啡馆发呆", b: "🗺️ 无论如何按原路线打卡", penalty: "给对方剥一个水果或揉肩 2 分钟！"),
        Question(prompt: "突然中了一千万，第一件事？", a: "✈️ 立刻买机票去环球旅行", b: "🏦 存银行收利息慢慢躺平", penalty: "深情对视 30 秒不许眨眼！"),
        Question(prompt: "深夜肚子饿了，会选择？", a: "🍢 叫上一大堆烧烤小龙虾", b: "🥛 喝杯热牛奶忍忍睡觉", penalty: "用可爱的语气说‘我最听你话了’！")
    ]
    
    @State private var qIndex = 0
    @State private var hostPick: String? = nil
    @State private var guestPick: String? = nil
    @State private var isRevealed = false
    @State private var score = 0
    
    public var body: some View {
        ZStack {
            CoupleColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 顶部栏
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(CoupleColors.textDark.opacity(0.5))
                    }
                    Spacer()
                    Text("默契积分: \(score)")
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.8)))
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                // 题目卡片
                let cur = questions[qIndex % questions.count]
                VStack(spacing: 12) {
                    Text("QUESTION \(qIndex + 1) / \(questions.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(CoupleColors.pinkMain)
                    Text(cur.prompt)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(CoupleColors.textDark)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 22).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, y: 3))
                .padding(.horizontal)
                
                // 选项 A
                optionCard(text: cur.a, optionKey: "A")
                // 选项 B
                optionCard(text: cur.b, optionKey: "B")
                
                // 揭晓结果弹窗
                if isRevealed {
                    VStack(spacing: 8) {
                        if hostPick == guestPick {
                            Text("🎉 心有灵犀！默契达成！")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.green)
                            Text("默契度 +10 分！")
                                .font(.system(size: 13))
                                .foregroundColor(CoupleColors.textMuted)
                        } else {
                            Text("💔 意见不一！触发情侣小惩罚：")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(CoupleColors.pinkMain)
                            Text(cur.penalty)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CoupleColors.textDark)
                        }
                        
                        Button(action: nextQ) {
                            Text("下一题 →")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(CoupleColors.primaryGradient))
                        }
                        .padding(.top, 6)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white).shadow(radius: 8))
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
    
    private func optionCard(text: String, optionKey: String) -> some View {
        VStack(spacing: 12) {
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(CoupleColors.textDark)
            
            HStack(spacing: 16) {
                Button(action: { select(opt: optionKey, isHost: true) }) {
                    Text(hostPick == optionKey ? "💖 粉方已选" : "粉方选择")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(hostPick == optionKey ? CoupleColors.pinkMain : .white))
                        .foregroundColor(hostPick == optionKey ? .white : CoupleColors.pinkMain)
                        .overlay(Capsule().stroke(CoupleColors.pinkMain, lineWidth: 1))
                }
                
                Button(action: { select(opt: optionKey, isHost: false) }) {
                    Text(guestPick == optionKey ? "💙 蓝方已选" : "蓝方选择")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(guestPick == optionKey ? CoupleColors.blueMain : .white))
                        .foregroundColor(guestPick == optionKey ? .white : CoupleColors.blueMain)
                        .overlay(Capsule().stroke(CoupleColors.blueMain, lineWidth: 1))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white).shadow(color: .black.opacity(0.03), radius: 6, y: 2))
        .padding(.horizontal)
    }
    
    private func select(opt: String, isHost: Bool) {
        if isHost { hostPick = opt } else { guestPick = opt }
        if hostPick != nil && guestPick != nil {
            isRevealed = true
            if hostPick == guestPick { score += 10 }
        }
    }
    
    private func nextQ() {
        hostPick = nil
        guestPick = nil
        isRevealed = false
        qIndex = (qIndex + 1) % questions.count
    }
}

// ==========================================
// 5. 游戏 3：心跳共振 (长按同频脉搏)
// ==========================================
public struct TouchHeartGameView: View {
    var onExit: () -> Void
    @State private var isPressing = false
    @State private var pressDuration: Double = 0.0
    @State private var heartScale: CGFloat = 1.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        ZStack {
            Color(red: 28/255, green: 28/255, blue: 30/255).ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button(action: onExit) {
                        Text("✕ 退出")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.white.opacity(0.15)))
                    }
                    Spacer()
                    Text("同步心率感应")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [CoupleColors.pinkMain.opacity(0.3), .clear], center: .center, startRadius: 40, endRadius: 140))
                        .scaleEffect(isPressing ? heartScale * 1.3 : 1.0)
                    
                    Text("❤️")
                        .font(.system(size: 90))
                        .scaleEffect(isPressing ? heartScale : 1.0)
                }
                .frame(width: 260, height: 260)
                .contentShape(Circle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressing = true }
                        .onEnded { _ in
                            isPressing = false
                            pressDuration = 0
                            heartScale = 1.0
                        }
                )
                
                Text(isPressing ? "已同步连线: \(String(format: "%.1f", pressDuration)) 秒" : "双方将手指贴合在爱心上长按")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isPressing ? CoupleColors.pinkSoft : .white.opacity(0.6))
                
                Spacer()
            }
        }
        .onReceive(timer) { _ in
            if isPressing {
                pressDuration += 0.1
                heartScale = 1.0 + CGFloat(sin(pressDuration * 8)) * 0.2
            }
        }
    }
}

// ==========================================
// 6. 主游戏盒大厅视图 (直接作为 App 入口根视图)
// ==========================================
public struct CoupleGamesAppView: View {
    let games: [MiniGameItem] = [
        MiniGameItem(id: "orbit", title: "心动轨道", subtitle: "引力弹球 · 切线碰撞与心动加速", iconName: "bolt.heart.fill", category: "即时物理", isNew: false, badgeText: "HOT"),
        MiniGameItem(id: "sync", title: "默契共振", subtitle: "灵魂二选一 · 测默契，分歧触发可爱惩罚", iconName: "heart.text.square.fill", category: "默契心理", isNew: true, badgeText: "NEW"),
        MiniGameItem(id: "pulse", title: "心跳共振", subtitle: "双人指尖同频长按 · 感受心跳同频脉搏", iconName: "waveform.path.ecg", category: "双人互动", isNew: false)
    ]
    
    @State private var activeGameId: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            CoupleColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text("💖")
                            .font(.system(size: 26))
                        Text("情侣游戏盒")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(CoupleColors.textDark)
                    }
                    Text("双人同屏 · 极简开局 · 甜蜜升温")
                        .font(.system(size: 13))
                        .foregroundColor(CoupleColors.textMuted)
                }
                .padding(.top, 46)
                .padding(.bottom, 20)
                
                // 游戏列表
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(games) { game in
                            Button(action: { activeGameId = game.id }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(game.id == "orbit" ? CoupleColors.pinkMain : (game.id == "sync" ? Color.purple : Color.orange))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: game.iconName)
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(game.title)
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundColor(CoupleColors.textDark)
                                            if let badge = game.badgeText {
                                                Text(badge)
                                                    .font(.system(size: 9, weight: .black))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(CoupleColors.pinkMain))
                                            }
                                        }
                                        Text(game.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(CoupleColors.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(CoupleColors.textMuted.opacity(0.4))
                                }
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 22).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, y: 3))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .fullScreenCover(item: Binding<MiniGameItem?>(
            get: { games.first(where: { $0.id == activeGameId }) },
            set: { activeGameId = $0?.id }
        )) { item in
            if item.id == "orbit" {
                OrbitGameView(onExit: { activeGameId = nil })
            } else if item.id == "sync" {
                SyncMindGameView(onExit: { activeGameId = nil })
            } else {
                TouchHeartGameView(onExit: { activeGameId = nil })
            }
        }
    }
}
