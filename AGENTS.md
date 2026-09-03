# Project Agent Constitution: 情侣双人小游戏 (Couple Games Hub)

> 本文件是本项目的唯一 Agent 宪法真源 (Single Source of Truth)。  
> 所有针对此项目的 AI Agent、协作工具（Claude Code, Cursor, Copilot, Gemini CLI, Windsurf, Devin, Cline 等）均必须严格遵守本宪法。

---

## 1. 核心铁律 (Core Non-Negotiables)

1. **零构建破坏原则 (Zero-Build-Breakage)**：
   - 任何涉及 Swift SPM 的改动，必须确保 `Package.swift` 结构完整、`SingleFile_CoupleGamesApp.swift` 与 `Sources/` 模块兼容。
   - 任何涉及 Web H5/PWA 的改动，必须保持 `index.html`（产物主入口）与 `preview.html` 绝对一致（`index.html` 复制覆盖 `preview.html` 或通过脚本同步）。
2. **同屏双人输入隔离原则 (Touch & Input Isolation)**：
   - 必须处理好触控冲突 (`touch-action: none`)、`e.preventDefault()`、多指并发触控 (`e.touches[i].identifier`)。
   - 顶/底（或左/右）两方操作区域在逻辑和物理坐标上严禁交叉干扰。
3. **沉浸式视口与震动降级 (Immersion & Graceful Haptics)**：
   - Web 移动端全屏交互：必须适配 Safe Area (`viewport-fit=cover`, `env(safe-area-inset-*)`)，禁用长按选中文本、弹性下拉刷新。
   - 触觉反馈必须做可用性防御：Web 端 `navigator.vibrate` / iOS Swift 端 `UIImpactFeedbackGenerator`。
4. **单源同步与防漂移 (Sync & Consistency)**：
   - 所有 AI 工具规则入口（`.cursorrules`, `CLAUDE.md`, `.github/copilot-instructions.md`, `GEMINI.md` 等）只做轻量索引，统一引用本文件，严禁产生分化分支。
5. **实时进度更新 (Status Update Loop)**：
   - 每次任务变更必须即时同步 `PROJECT_STATUS.md` 与 `HANDOFF.md`，交接必须闭环。

---

## 2. 项目架构与真实技术栈 (Stack & Architecture)

### 2.1 架构形态 (Dual-Engine / Multi-Platform)
本项目为**同屏双人情侣小游戏中心**，包含两大工程形态：
- **Web H5 / PWA 端 (主力即时部署体验)**：
  - **核心入口**：`index.html`（单文件自包含 SPA，内置 Tailwind CSS CDN、Canvas 渲染引擎、Web Audio 合成音效、PWA Service Worker 与 LocalStorage 本地对战记录）。
  - **静态资源与 PWA 资产**：`manifest.json`, `icon.svg`, `icon-192.png`, `icon-512.png`, `favicon.png`, `apple-touch-icon.png`。
  - **镜像预览**：`preview.html`（必须与 `index.html` 保持二进制/内容完全同步）。
- **Native iOS / macOS 端 (Swift Package)**：
  - **模块化代码**：`Sources/CoupleGamesCore/`（`DesignSystem`, `Games`, `Haptics`, `Lobby`, `Network`）与测试 `Tests/CoupleGamesCoreTests/`。
  - **即插即用独立 App 文件**：`SingleFile_CoupleGamesApp.swift`（SwiftUI 完整自包含全游戏实现）。
  - **构建规范**：Swift 5.9+, iOS 17+, macOS 14+。

### 2.2 核心游戏矩阵 (Game Matrix)
当前已实现并验证的核心游戏：
1. **心动轨道 (Orbit Collision)** - 物理即时弹球碰撞与连击加速
2. **默契共鸣 (Sync Mind)** - 节奏与二选一同步默契测试
3. **心跳轻触 (Touch Heart)** - 快速反应同屏轻触与胜负惩罚
4. **乒乓对决 (Table Tennis)** - 2.5D 弧线物理乒乓击球
5. **大满贯网球 (Tennis Grand Slam)** - 经典网球场地对战
6. **坦克大战 (Tank Duel)** - 双人同屏摇杆瞄准射击
7. **经典四子棋 (Connect 4)** - 策略重力落子连珠
8. **手速反应王 (Reaction Speed)** - 颜色与图形瞬时抢答
9. **双人贪吃蛇 (Snake Battle)** - 边界生存与抢食竞争

---

## 3. 规范目录与 Owner 边界 (Directory & Owner Boundaries)

| 目录 / 文件 | 职责说明 | 变更边界与约束 |
| :--- | :--- | :--- |
| `index.html` | Web 端主入口与完整 SPA 逻辑 | **核心**：样式、Canvas 物理帧循环、Touch 事件绑定，修改后必须同步 `preview.html` |
| `preview.html` | 本地与远程实时预览入口 | 禁止单独修改，必须由 `index.html` 同步生成 |
| `SingleFile_CoupleGamesApp.swift` | 纯单文件 SwiftUI 全功能独立运行体 | 保持零外部第三方依赖，纯 SwiftUI + Combine + CoreHaptics |
| `Sources/CoupleGamesCore/` | 模块化 Swift Package 源码 | 遵循 SwiftUI MVVM 架构与分层规范 |
| `manifest.json`, `*.png`, `*.svg` | PWA 桌面与安装图标资源 | 保证规范分辨率 (192, 512, Apple Touch) |
| `deploy.sh`, `deploy_now.sh` | 自动化 GitHub 提交与部署脚本 | 默认只读审计，不盲目自动 push |
| `PROJECT_STATUS.md` | 项目实时状态看板 | 每次代码改动与任务完成必须同步更新 |
| `HANDOFF.md` | Agent 间任务交接与未竟事项清单 | 跨轮次任务与中断时记录完整上下文 |

---

## 4. 产品非目标与拒绝方向 (Non-Goals & Refusal Directions)

在没有用户明确要求的情况下，**严禁引入以下复杂度和改动**：
1. **严禁引入重量级前端打包框架**：禁止将单文件极速加载的 `index.html` 强制改写为依赖 Webpack/Vite/Next.js/React node_modules 的复杂工程。
2. **严禁引入非必要的外部后端服务**：当前定位为同屏纯本地或 P2P 本地局域网双人互动，禁止强制引入重度账号系统、数据库或第三方收费云服务。
3. **严禁破坏单文件自包含性**：`SingleFile_CoupleGamesApp.swift` 与 `index.html` 的独立直接运行特性是核心诉求，禁止将其拆散导致无法单文件拷贝运行。
4. **严禁破坏双人触控机制**：禁止使用粗暴的全局单点点击监听破坏同屏双指/多指独立滑动。
5. **严禁编造不存在的 API 或第三方 Pods/SPM 依赖**。

---

## 5. 变更安全与验收命令 Map (Verification Commands Map)

> 默认情况下，Agent 严禁在未经授权时静默执行破坏性命令。以下为标准只读或隔离环境验收指南：

### 5.1 Web 端验收
- **本地服务预览**（不写状态）：
  ```bash
  # Python 简易 HTTP 服务
  python -m http.server 8080
  # 访问 http://localhost:8080 验证 index.html 与 preview.html
  ```
- **文件一致性校验**：
  ```bash
  diff -u index.html preview.html
  ```
- **PWA Manifest 语法检查**：
  ```bash
  python -c "import json; json.load(open('manifest.json', 'r', encoding='utf-8'))"
  ```

### 5.2 Swift 端验收
- **Swift Package 编译检查**：
  ```bash
  swift build
  ```
- **Swift Core 单元测试**：
  ```bash
  swift test
  ```

---

## 6. AI Agent 协作与交接纪律 (Agent Discipline)

1. **第一性原理与 TOC 约束理论**：
   - 紧盯当前系统单一核心瓶颈（如触控延迟、物理帧掉帧、双端渲染差异），不针对非瓶颈进行过度设计。
2. **任务开始先确认，结束必留档**：
   - 开始任务：按 `[回执] 目标: ... | 成功标准: ... | 关键约束: ...` 输出。
   - 完成任务：更新 `PROJECT_STATUS.md` 进度看板与 `HANDOFF.md`。
3. **输出完整性**：
   - 禁止输出截断代码（`// ... 保持原有代码不变 ...`），修改关键逻辑时提供明确且完整的改动，确保可运行性。
