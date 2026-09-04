# Agent 任务交接文档 (Handoff)

> 交接日期: 2026-09-04  
> 当前版本: v2.5.0 (大厅 UI 重设计 + iPhone 安全区退出按钮修复 + DualCourt 3D + 21 游戏矩阵)

---

## 0. 本轮新完成：Happy Games 大厅 UI 重设计

**用户反馈**：主界面 UI 很差，要求调用 UI skill 重新优化。

**执行方法**：调用 `redesign-existing-projects` skill → Scan（读 CSS/HTML/JS 结构）→ Diagnose（按审计清单逐项打分）→ Fix（纯 CSS/HTML，零 JS 逻辑改动，不迁移框架）。

**诊断要点（Before）**：纯白卡 + 纯黑投影 + 20px 均一圆角（Generic card look）；21 个徽章五颜六色内联底色；头部居中 24px 系统字 + 🎮 + 副标题文案仍写「20 款」（实际 21）；浅粉线性渐变无层次；无 hover/浮起反馈；模式弹窗三行粉/绿/蓝高饱和撞色；配对面板硬切冷调蓝。

**重设计落地（After）**：
1. **氛围底**：`#lobby-view` 四层 radial-gradient 光斑（粉/暖粉/浅紫）叠 175° 暖色线性底，替代纯线性渐变。
2. **头部**：品牌行（💞 玫瑰渐变 logo + 26px/900 Happy Games + 毛玻璃「同屏+联机就绪」状态胶囊，dot 由绿色改为玫瑰呼吸点）；副标题修正「共 21 款」并左对齐加 600 字重；Safe-Area padding 顶部 +14px。
3. **分类条**：毛玻璃胶囊（白 72% + blur + 白描边），激活态玫瑰渐变 + 0.32 玫瑰阴影 + 顶部内高光；hover/active 反馈。
4. **游戏卡片**：暖调半透明白 `rgba(255,253,252,.92)` + blur + 玫瑰染色双层阴影（2px 近影 + 26px 环境影，弃纯黑）+ 内顶高光；hover 浮起 2px（仅 pointer:fine）；active 按压缩放。圆角 20px、描述 12px 暖灰单行省略。
5. **图标**：54px 17px 圆角，`::after` 150° 玻璃高光叠加（保留 21 种主题渐变作为游戏辨识色）。
6. **徽章统一**：sed 移除 21 处内联背景/前景色 → 统一玫瑰 15% 底 + `#C93B60` 字 + 999px 药丸（原 deep 底白字 12 个 + 浅底深字 9 个全删）。
7. **模式弹窗**：backdrop 深玫瑰 + blur(6px)；sheet 毛玻璃白 + 28px 顶圆角 + 上投影 + 缓动 `sheetUp`；头部文本类化（`.sheet-head-name/sub`）；三模式按钮改**同色系**暖调卡片（粉/杏/淡紫）配同色系图标渐变与染色阴影，去掉刺眼绿。
8. **配对面板 net-panel**：背景并入暖粉光斑氛围，标题/说明改用 ink 色阶，输入框 focus 换玫瑰描边 + 4px 光晕。
9. **桌面端**：`.category-chip:hover`、`.game-card:hover`、`.game-card:hover .enter-btn`（箭头圆钮 hover 玫瑰实底）、`.mode-btn:hover` 浮起仅作用于 hover+fine 设备；700px 断点补 `.header-logo` 放大。enter-btn 箭头改用 Georgia 衬线并光学下沉 2px。

**验收（浏览器计算样式，393×852）**：lobby 4 层背景 gradient、标题 26px/900、卡片 bg `rgba(255,253,252,.92)`/20px 圆角/玫瑰染色阴影、激活 chip 玫瑰渐变、徽章统一 `#C93B60/rgba(255,107,139,.15)/999px`、头部无溢出（342px 行宽 0 overflow）、分类「体育竞技」过滤 5 卡正常、弹窗游戏名/图标映射正确、进出游戏闭环、列表滚动到底最后一张卡正常。`test_games.js` 153/153 通过，`preview.html` 已同步 diff 一致。

**遗留小瑕疵（非本轮范围，记录备查）**：桌面 ≥1100px 断点下 `.game-list` 有 3 列 grid 规则，但 `.app-viewport` 桌面模拟壳固定 390px 宽（`@media (min-width:500px) and (hover:hover) and (pointer:fine)`），1100px 断点实际永不生效——桌面壳内永远 2 列，3 列规则为死代码。如需桌面宽壳/真平板 3 列需调整壳宽度策略（如 iPad 直屏无 hover 全宽已走 700px 断点正常 2 列）。本轮未处理以避免改变桌面模拟壳交互预设。

---

## 1. 上一轮（iPhone 安全区退出按钮修复）

**用户反馈**：乒乓与网球在 iPhone 上可玩，但退出按钮被挡住无法退出。

**根因（因果链）**：`viewport-fit=cover` 使 `.game-screen` 铺满物理屏幕顶端 → iPhone 顶部 ~59px 为灵动岛/状态栏区域 → 项目内其他游戏均有 `calc(env(safe-area-inset-top) + Npx)` 顶部安全区，唯独 DualCourt 重构引入的乒乓/网球顶栏只写了 `padding:10px 16px` → 退出按钮恰好落在灵动岛下方不可见/不可点。

**修复范围（同类缺陷一次修全）**：
1. `index.html` 乒乓顶栏（`#screen-pingpong`）：`padding:calc(env(safe-area-inset-top, 20px) + 10px) 16px 10px`。
2. `index.html` 网球顶栏（`#screen-tennis`）：同上。
3. `#screen-connect4`（同类隐患）：补安全区 padding（顶+底）+ `flex-direction: column`（此前 flex row 下三块子元素横向挤压）。
4. `#screen-reaction`（同类隐患）：两个浮动按钮 `top:12px` → `top:calc(env(safe-area-inset-top, 20px) + 12px)`。

**验证（393×852 iPhone 14 Pro 视口 + 模拟灵动岛 59px）**：乒乓/网球退出按钮顶 69px（=59+10，完全避开灵动岛）；点击退出后正确回到大厅（乒乓/网球双向闭环）；四子棋 column 布局棋盘正常可见；反应王按钮位置正确；画布 flex:1 自动收缩无副作用。`index.html`/`preview.html` diff 一致。

---

## 2. DualCourt 3D 核心交付（上上轮）

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

## 3. DuoDash 3D 遗留交接

- DuoDash 3D（游戏 21）由上一会话完成：三轨道伪 3D 跑酷、道具互坑、`mulberry32(seed + idx*7919)` 每物件独立种子流保证联机确定性、10Hz 轻量镜像 + 幽灵对手。
- 上一会话「并发会话警示」中提到的 DualCourt 未注册问题**已在本轮全部解决**（卡片/GAME_META/教练条/测试齐备），该警示可关闭。

## 4. 远端自动部署状态

- 只要推送至 GitHub `main` 分支，Vercel 会自动拉取并完成生产部署。
- 部署目标域名保持稳定：`https://couple-games-hub-livid.vercel.app`
- 备用 GitHub Pages：`https://zonlic0925-boop.github.io/couple-games-hub/`
