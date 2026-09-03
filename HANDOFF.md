# Agent 任务交接文档 (Handoff)

> 交接日期: 2026-09-04  
> 当前版本: v2.4.0 (DualCourt 3D 乒乓/网球 PRD 交付 + DuoDash 3D + 21 游戏矩阵)

---

## 1. 刚刚完成的核心工作（本轮：DualCourt 3D，按 PRD 交付）

1. **按《DualCourt 3D》PRD 完整重构「乒乓」与「网球」两游戏**（PRD 技术栈条款 Unity/Godot 与项目宪法单文件 Web 约束冲突，取 Web 交付硬约束，玩法层全量用 Canvas 透视投影自研实现）：
   - **DC3D 共享微引擎**：透视投影（yaw/pitch/fov，近大远小+深度剔除）、世界空间 poly/line/ball/groundEllipse、`dcSolveShot` 抛物线反解（迭代保证过网净高 + 马格努斯下坠补偿）、`dcStepBall` 空气动力学积分（重力+二次阻力+马格努斯：上旋下坠/侧旋拐弯，网球横向系数 kmy 衰减防失控）。
   - **Swipe-to-Hit 触控**：`dcSwipeFeed` 累计 34px 立即出手（不等抬手，保 0.3s 反应窗口）；滑动向量→方向/力度，弧线偏离→旋转加成；上滑上旋/下滑削球/横滑侧旋；多指 identifier 隔离，分屏按 y 分配半场；合成 TouchEvent 已实测真机同路径。
   - **时机判定**：球距最佳击球平面 → PERFECT/GOOD/EARLY/LATE 浮字 + 分档质量（散布/下网率/飞行时长惩罚）+ 分级触觉（`dcHaptic`: 甜区瞬态/边缘发闷/扣杀组合，`navigator.vibrate` 降级）。
   - **乒乓 3D**：第一人称后置固定机位、半透明近拍+挥拍动画、ITTF 蓝台+网带+中线、发球辅助圈、台面弹跳旋转效应（上旋前冲/下旋减速）、乒乓规则（回落己方/两跳/出界/擦网）、5 分制每球轮换发球。
   - **网球 3D**：越肩动态追踪机位（随球平移）、单打场全套白线+球网+球网柱、三种场地（硬地 0.73/红土 0.80 高弹慢速滑步/草地 0.62 低弹快速）、二跳与出界判罚、发球力度=深浅左右=角度、场地切换 chips（相持中禁切、联机加入方只读由 buildOpts 同步）、小人渲染（腿/躯干/头/挥拍臂）。
   - **AI 陪练状态机**：观察预判（线性外推截击点）→ 趋位 → 出手，含 8-9% 失误率与大角度调动。
   - **三模式**：AI 陪练=第一人称全屏主体验；同屏双人=上下分屏双视角（同一物理世界两套投影）；联机=沿用 NET_HOOKS 房主权威快照流（快照含球三维状态+旋转+发球权+相持阶段，guest 以 `sw` 事件上行滑动参数）。
   - **稳健性**：NaN 熔断（`Number.isFinite` 逐字段，异常按对方得分恢复可玩）+ 主循环 try/catch 单帧保护。
2. **修复三个既有缺陷**：`startAIGame` 引用未定义 `selectedGameId`（AI 陪练按钮全游戏静默失效）→ 改回 `sheetGameId`；`showGlobalToast` 从未定义 → 补全局别名；`dcStepBall` 读 `cfg.kd/km` 小写而引擎定义 `KD/KM` 大写 → 积分即 NaN 且经 `dcClamp(NaN)` 透传污染球拍 → 大小写兼容 + 熔断 + 回归测试（90 帧物理有限性断言）。
3. **测试扩充**：`test_games.js` 新增 DualCourt 专项 6 项（透视投影近大远小/滑动分析立即出手与弧线度量/挥拍反解过网净高/乒乓 AI 击球与时机/网球三场地弹性排序与发球初速/联机快照回环与滑动上行），全量 **153/153 通过**。
4. **注册与同步**：大堂双卡片（「DualCourt 乒乓 3D (Swipe Hit)」/「DualCourt 网球 3D (Triple Surface)」）、`GAME_META` 更名、`screen-pingpong`/`screen-tennis` 加教练提示条与场地选择条、新 CSS（`.dc-coach`/`.dc-surface-chip`）、GameAudio 新增 `whoosh`/`netcord`/`surface` 三音色；`index.html` 与 `preview.html` 二进制一致。
5. **浏览器 iPhone 视口（390×844）实测**：3D 第一人称渲染、触摸滑动发球（上旋 0.8）、AI 回击、玩家回击至 rally=4 多拍对拉、得分与轮换发球、红土落地水平速度保持率 0.59（硬地 0.80）、同屏分屏双视角渲染、全程 0 JS 报错。注：ZCode 内嵌浏览器 rAF 被宿主节流，测试以手动步帧驱动（真机浏览器无此问题）。

## 2. 上一轮（DuoDash 3D）遗留交接

- DuoDash 3D（游戏 21）由上一会话完成：三轨道伪 3D 跑酷、道具互坑、`mulberry32(seed + idx*7919)` 每物件独立种子流保证联机确定性、10Hz 轻量镜像 + 幽灵对手。
- 上一会话「并发会话警示」中提到的 DualCourt 未注册问题**已在本轮全部解决**（卡片/GAME_META/教练条/测试齐备），该警示可关闭。

## 3. 远端自动部署状态

- 只要推送至 GitHub `main` 分支，Vercel 会自动拉取并完成生产部署。
- 部署目标域名保持稳定：`https://couple-games-hub-livid.vercel.app`
- 备用 GitHub Pages：`https://zonlic0925-boop.github.io/couple-games-hub/`
