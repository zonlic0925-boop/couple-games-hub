# 项目实时状态看板 (Project Status)

> 最后更新时间: 2026-09-04 (DualCourt 3D 轮次)  
> 状态级别: 🟢 生产就绪 (Production Ready - High Quality Polish)

---

## 1. 核心里程碑与健康度

| 模块 | 状态 | 覆盖度 / 说明 |
| :--- | :--- | :--- |
| **Web SPA 游戏矩阵** | 🟢 完备 (21 款) | 涵盖球类、棋类、动作射击、跑酷竞速、派对默契、益智闯关共 21 款 |
| **三模式支持** | 🟢 完备 | 1. 📱 同屏双人对战 2. 🤖 单人练习 (AI 智能陪练) 3. 🌐 跨设备联机对战 |
| **DualCourt 3D 乒乓/网球 (PRD 交付)** | 🟢 完备 | 按 DualCourt 3D PRD 重构两游戏：Canvas 透视投影 3D 视角（乒乓第一人称后置机位/网球越肩追踪）、马格努斯空气动力学物理、Swipe-to-Hit 滑动击球（方向/力度/上旋·削球·侧旋/弧线加转）、Perfect·Good·Early·Late 时机判定、半自动跑位、AI 状态机陪练、网球三场地（硬地/红土高弹慢速/草地低弹快速）、发球落点辅助圈、CoreHaptics 映射的 Web 触觉降级、同屏分屏双视角、联机快照含旋转全场状态 |
| **双人跑酷 DuoDash 3D (新增)** | 🟢 完备 | 三轨道伪 3D 跑酷竞速：滑动变道/跳跃/滑铲、三道具互坑（导弹 1 秒变轨闪避/香蕉皮打滑/火箭冲刺）、同种子确定性赛道、10Hz 轻量状态镜像 + 幽灵对手距离指示 |
| **GameFX 特效引擎** | 🟢 完备 | 画布屏幕微震 (ScreenShake)、物理火花粒子爆发、水波纹扩散、浮动连击大字 |
| **GameAudio 真实合成音效** | 🟢 完备 | 木质清脆回弹、网面抽击破空、金属击打、重低音炮火震荡、围棋玉石落子、连击上升音阶 + DualCourt 新增挥拍破风/擦网闷响/场地弹跳 |
| **GameAI 智能算法库** | 🟢 完备 | 乒乓/网球/冰球/坦克/五子棋/黑白棋/四子棋/打砖块/贪吃蛇/方块/迷宫/跑酷专属对战算法 |
| **PWA 与桌面/移动双端适配** | 🟢 完备 | iPhone (Safe-Area)、iPad (响应式全屏/多列网格)、PC 端自适应居中模拟器 |
| **自动化测试** | 🟢 100% 通过 | `test_games.js` 全量通过 (153/153 测试项，含 DualCourt 投影/滑动分析/挥拍反解/90 帧物理有限性回归 + DuoDash 专项) |
| **联机通信与状态同步** | 🟢 已修复增强 | 微型坦克等联机对战双端双向移动/摇杆控制指令无缝传输无死锁；DualCourt 快照含球体三维速度与旋转、发球权、相持阶段 |
| **生产部署** | 🟢 已上线 | Vercel 生产部署 + GitHub Pages 备用部署 |

---

## 2. DualCourt 3D 轮次修复的既有缺陷

1. **AI 陪练按钮全游戏失效**：`startAIGame` 引用了不存在的 `selectedGameId`，点击后静默失败；已改回 `sheetGameId` 并验证。
2. **`showGlobalToast` 未定义**：模式切换/AI 提示与 DualCourt 场地切换提示调用了一个从未定义的函数；已补全局别名（复用 `netShowToast` + `#globalToast`）。
3. **乒乓/网球物理引擎常数大小写错配**：`dcStepBall` 曾读 `cfg.kd/cfg.km` 小写而引擎定义 `KD/KM`，导致积分即 NaN 并经 `dcClamp` 污染球拍坐标（NaN 比较恒 false 直接透传）；修复为大小写兼容 + NaN 熔断（`Number.isFinite` 逐字段）+ 主循环 try/catch 单帧保护。
4. **duodash 种子确定性**（协同轮次）：左右跑道改为每物件独立 `mulberry32(seed + idx*7919)` 流，联机两端确定性一致。

---

## 3. 线上访问地址

- **主入口 (Vercel)**: [https://couple-games-hub-livid.vercel.app](https://couple-games-hub-livid.vercel.app)
- **备用入口 (GitHub Pages)**: [https://zonlic0925-boop.github.io/couple-games-hub/](https://zonlic0925-boop.github.io/couple-games-hub/)
