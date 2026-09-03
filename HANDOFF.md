# 任务交接文档 (Agent Handoff Snapshot)

> **交接时间**：2026-09-02（20 游戏矩阵 + 全游戏联网对战 + 平板适配完成）  
> **交接状态**：Web/PWA 端全量交付，自动化测试 42/42 通过；Swift 原生端新增内容待跟进（见下）。

---

## 📌 本轮完成内容

1. **游戏矩阵 9 → 20 款**：新增五子棋、黑白棋、点格棋、记忆翻牌、空气曲棍球、打砖块对决、竞速躲避、俄罗斯方块对决、你画我猜、真心话大冒险、迷宫竞速。全部为 Canvas/DOM 原生实现，无第三方游戏引擎。
2. **全部 20 款游戏具备「同屏 + 联机」双模式**：
   - 入口改为模式选择弹层（`openModeSheet`），联机走 4 位房码配对（`netCreateRoom` / `netJoinRoom`）。
   - NetPlay 模块：MQTT over WebSocket 公共中转（EMQX/HiveMQ/Mosquitto 三级切换），协议 `hi/start/snap/in/ev/bye`。
   - 每款游戏在 `NET_HOOKS[gameId]` 注册 `{ stream, snapPeriod, snap, restore, input, event, buildOpts }` 钩子。
3. **联机权威模型**（改游戏前必读）：
   - **动作类**（乒乓/网球/轨道/坦克/冰球/砖块/方块/贪吃蛇）：房主权威模拟 + 周期快照；蓝方输入上行、本地球拍/单位本地预测。
   - **回合类**（四子棋/五子棋/黑白棋/点格棋/记忆/默契）：变化即推送 `netPushSnap()`，终局广播 `over` 事件，双端同弹结算窗。
   - **确定性竞速类**（竞速躲避/迷宫）：双端同种子 `mulberry32` 生成赛道/迷宫，各自本地权威移动，结果以事件互认。
   - **坐标归一化**：跨设备快照一律除以画布宽高传输（像素坐标不可直接同步，双端尺寸不同）。
4. **iPhone/iPad 适配**：平板不再套手机框（`hover+fine pointer` 限定桌面）、大厅 2/3 列响应式网格、乒乓/网球大屏速度缩放。
5. **镜像同步**：`index.html` 与 `preview.html` 已 1:1（7257 行）。

---

## ⚠️ 关键避坑提示

- **改 Canvas 尺寸/样式必须**继续使用 `getCanvasTouchPos` 拾取触点；新增游戏沿用 `bindBoardTap` / 各自 `applyTouch` 模式。
- **快照必须可 JSON 序列化**：游戏状态里不要塞函数/Canvas 对象；粒子等纯视觉元素可不入快照。
- **联机模式双端网格必须一致**：贪吃蛇联机固定 20×24 网格（`snakeCell` 自适应），勿改回按画布尺寸计算。
- **exitToLobby 会执行 `GAME_CLEANUPS` 全表 + netDisconnect**：新游戏记得注册 cleanup，勿在 cleanup 里重复弹结算窗。
- **再来一局**：结算浮层已统一仲裁（房主重开+广播 start，蓝方发 rematch 请求），新游戏不要自己实现 rematch。
- **hi 重试**：加入方 1.5s×8 次重试 hi，收到 start 自动停止；勿在别处再发 hi。

---

## 🚀 未竟事项（下一轮跟进）

1. **Swift 原生端 (SingleFile_CoupleGamesApp.swift / Sources/CoupleGamesCore) 未同步本轮内容**：
   - 11 款新游戏、NetPlay 联网层（Swift 侧建议 MultipeerConnectivity 局域网 + GameKit 可选）均只在 Web 端实现。
   - 原因：本机为 Windows 无法运行 `swift build` 验证，为守住「零构建破坏」铁律未动 Swift 代码。**在 macOS 环境补齐 Swift 端时务必先跑 `swift build && swift test`。**
2. **联机延迟调优（可选）**：动作类快照 66ms 无插值，弱网下可加线性插值缓冲。
3. ** TURN 中继（可选）**：MQTT 中转延迟 ~100-250ms，若需竞技级手感可引入自建 TURN/WebRTC。
4. **发布**：本地验证后执行 `./deploy_now.sh` 部署 Cloudflare Pages。
