import SwiftUI

/// 即时物理引力球场景视图（高质感柔和配色与流光粒子）
public struct OrbitGameView: View {
    @ObservedObject public var viewModel: OrbitGameViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: OrbitGameViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        CoupleColors.sweetPink.opacity(0.15),
                        Color(red: 248/255, green: 246/255, blue: 252/255),
                        CoupleColors.calmBlue.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 中线与心动能量光环
                VStack {
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [CoupleColors.sweetPink.opacity(0.4), CoupleColors.sweetPink.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 2)
                        
                        // 心动连击数标识
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(viewModel.isHeartAccelerated ? CoupleColors.vibrantPink : .secondary)
                            Text("\(viewModel.currentRally)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        Rectangle()
                            .fill(LinearGradient(colors: [CoupleColors.calmBlue.opacity(0.1), CoupleColors.calmBlue.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 2)
                    }
                    Spacer()
                }
                
                // 比分显示
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TA 的心能")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.hostScore)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(CoupleColors.vibrantPink)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("我的心能")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.guestScore)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(CoupleColors.calmBlue)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    Spacer()
                }
                
                // 物理刚体：爱心能量球
                let ballX = viewModel.ballPosition.x * size.width
                let ballY = viewModel.ballPosition.y * size.height
                
                ZStack {
                    // 拖尾光晕
                    Circle()
                        .fill(viewModel.isHeartAccelerated ? CoupleColors.vibrantPink.opacity(0.4) : CoupleColors.sweetPink.opacity(0.3))
                        .frame(width: viewModel.isHeartAccelerated ? 54 : 44, height: viewModel.isHeartAccelerated ? 54 : 44)
                        .blur(radius: viewModel.isHeartAccelerated ? 8 : 4)
                    
                    // 核心图标
                    Image(systemName: "heart.fill")
                        .font(.system(size: viewModel.isHeartAccelerated ? 26 : 22))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(viewModel.isHeartAccelerated ? CoupleColors.vibrantPink : CoupleColors.sweetPink)
                                .frame(width: 38, height: 38)
                        )
                }
                .position(x: ballX, y: ballY)
                
                // 挡板 1 (Host 上方 / 粉色)
                let hostX = viewModel.hostPaddlePos.x * size.width
                let hostY = viewModel.hostPaddlePos.y * size.height
                
                Capsule()
                    .fill(CoupleColors.hostPlayerGradient)
                    .frame(width: size.width * 0.28, height: 20)
                    .shadow(color: CoupleColors.sweetPink.opacity(0.4), radius: 8, x: 0, y: 3)
                    .position(x: hostX, y: hostY)
                
                // 挡板 2 (Guest 下方 / 蓝色)
                let guestX = viewModel.guestPaddlePos.x * size.width
                let guestY = viewModel.guestPaddlePos.y * size.height
                
                Capsule()
                    .fill(CoupleColors.guestPlayerGradient)
                    .frame(width: size.width * 0.28, height: 20)
                    .shadow(color: CoupleColors.calmBlue.opacity(0.4), radius: 8, x: 0, y: -3)
                    .position(x: guestX, y: guestY)
                
                // 浮动爱心互动动效
                ForEach(viewModel.floatingHearts, id: \.self) { _ in
                    FloatingHeartView()
                }
                
                // 顶部控制与互动栏
                VStack {
                    HStack {
                        Button {
                            viewModel.stopGameLoop()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 发送爱心互动按钮
                        Button {
                            viewModel.sendHeartInteraction()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundColor(CoupleColors.vibrantPink)
                                Text("送小心心")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    Spacer()
                }
            }
            // 手势监听（根据不同模式自动识别控制权）
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let normX = value.location.x / size.width
                        let normY = value.location.y / size.height
                        
                        switch viewModel.mode {
                        case .localPassAndPlay:
                            // 同屏模式：触碰上半屏控制 Host，触碰下半屏控制 Guest
                            if normY < 0.5 {
                                viewModel.updatePaddleTouch(role: .host, normalizedX: normX, normalizedY: normY)
                            } else {
                                viewModel.updatePaddleTouch(role: .guest, normalizedX: normX, normalizedY: normY)
                            }
                        case .onlineHost:
                            viewModel.updatePaddleTouch(role: .host, normalizedX: normX, normalizedY: normY)
                        case .onlineGuest:
                            viewModel.updatePaddleTouch(role: .guest, normalizedX: normX, normalizedY: normY)
                        }
                    }
            )
        }
        .onAppear {
            viewModel.startGameLoop()
        }
        .onDisappear {
            viewModel.stopGameLoop()
        }
    }
}

/// 浪漫浮动爱心粒子
struct FloatingHeartView: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 36))
            .foregroundColor(CoupleColors.vibrantPink)
            .scaleEffect(scale)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.1)) {
                    offset = -160
                    opacity = 0
                    scale = 1.3
                }
            }
    }
}
