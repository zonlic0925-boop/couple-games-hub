# 情侣双人小游戏 (CoupleGames iOS)

一款面向 iOS 平台专为情侣设计的即时双人小游戏，支持**单机同屏指尖互动**、**面对面近场免流直连**与**远程 4 位房间码联机**。

---

## 核心特色与玩法

1. **同屏双人对战（面对面即开即玩）**：
   * 一部 iPhone / iPad 放在桌上，两人对坐，触碰屏幕上下半区。
   * 零网络门槛，适合聚餐、等车、咖啡厅等场景即开即玩。
2. **双机双模联机（近场 + 远程）**：
   * **近场模式**：依托 Apple 原生 `MultipeerConnectivity`，即使无 WiFi / 移动信号（如高铁、飞机、户外露营），也能蓝牙/局域网点对点自组织网络秒连。
   * **远程模式**：异地恋情侣输入 4 位房间码即可通过 WebSocket / 云端信令跨公网顺畅联机。
3. **首发即时物理小游戏：《心动轨道 (Gravity Orbit)》**：
   * 采用高精度 2D 物理碰撞与刚体运动模型。
   * **心动连击机制**：双方连续对打 5 回合以上，爱心球进入“加速心动”状态，伴随渐强震动反馈。
   * **即时情感互动**：一键互发“浮动爱心”，增进互动趣味。
4. **浪漫情侣视觉与触觉设计系统**：
   * **CoupleColors**：甜心粉、静谧蓝与柔和毛玻璃结合，避免传统街机游戏的生硬感。
   * **CoupleHaptics**：基于 `UIImpactFeedbackGenerator` 与 `UINotificationFeedbackGenerator` 打造的触觉反馈（击球、撞墙、心跳、进球）。

---

## 项目架构与工程结构

```
CoupleGames/
├── Package.swift                                      // Swift Package Manager 规范工程配置
├── Sources/CoupleGamesCore/
│   ├── DesignSystem/
│   │   └── CoupleColors.swift                         // 浪漫情侣色彩规范与渐变
│   ├── Haptics/
│   │   └── CoupleHaptics.swift                        // 细腻触觉反馈引擎
│   ├── Network/
│   │   ├── NetworkTransport.swift                     // 统一抽象网络通信接口
│   │   ├── LocalMultipeerTransport.swift              // 局域网/蓝牙免流点对点传输
│   │   └── RemoteRoomTransport.swift                  // 远程 4 位房间码信令传输
│   ├── Games/
│   │   └── GravityOrbit/                              // 首发即时物理游戏模块
│   │       ├── OrbitStateSnapshot.swift               // 归一化坐标与高频帧快照协议
│   │       ├── OrbitPhysicsEngine.swift               // Host 权威 2D 物理与碰撞引擎
│   │       ├── OrbitGameViewModel.swift               // 游戏核心状态机与网络同步
│   │       └── OrbitGameView.swift                    // 游戏渲染视图、拖尾光晕与爱心粒子
│   └── Lobby/
│       ├── LobbyViewModel.swift                       // 大厅业务逻辑、状态流转与房间管理
│       └── MainLobbyView.swift                        // 大厅主界面与 4 位房间码弹窗
└── Tests/CoupleGamesCoreTests/
    └── CoupleGamesCoreTests.swift                     // 物理引擎步进、边界限制与快照编解码测试
```

---

## 如何在 Xcode 中运行

1. 打开 Xcode，选择 **File -> Open...**，选择本项目根目录（包含 `Package.swift` 的文件夹）；
2. 或者在您的 iOS App 主工程（Target 为 iOS 17.0+）的 `Dependencies` 中引入 `CoupleGamesCore`；
3. 在 App 入口（如 `ContentView.swift`）直接展示主界面：
   ```swift
   import SwiftUI
   import CoupleGamesCore

   @main
   struct CoupleGamesApp: App {
       var body: some Scene {
           WindowGroup {
               MainLobbyView()
           }
       }
   }
   ```
4. 运行于真机即可体验原生触觉震动与近场蓝牙/局域网直连。
