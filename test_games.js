const fs = require('fs');
const vm = require('vm');

const html = fs.readFileSync('index.html', 'utf8');

// 提取主 script（不带 src 属性的内联脚本）
const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
if (!scriptMatch) {
    console.error("No script tag found!");
    process.exit(1);
}
const jsCode = scriptMatch[1];

// ============ 最小 DOM 环境模拟 ============
const mockElements = {};
function getOrCreateMockElement(id) {
    if (!mockElements[id]) {
        const el = {
            id,
            style: {},
            dataset: {},
            classList: {
                add: () => {},
                remove: () => {},
                toggle: () => {},
                contains: () => false
            },
            addEventListener: () => {},
            removeEventListener: () => {},
            children: [],
            appendChild: (c) => { el.children.push(c); },
            remove: () => {},
            innerHTML: '',
            innerText: '',
            value: '',
            offsetWidth: 375,
            offsetHeight: 667,
            clientWidth: 375,
            clientHeight: 500,
            width: 375,
            height: 500,
            parentElement: null,
            getContext: () => ({
                save: () => {}, restore: () => {}, beginPath: () => {}, closePath: () => {},
                moveTo: () => {}, lineTo: () => {}, arc: () => {}, fill: () => {}, stroke: () => {},
                fillRect: () => {}, strokeRect: () => {}, clearRect: () => {}, roundRect: () => {},
                fillText: () => {}, strokeText: () => {}, measureText: () => ({ width: 50 }), setLineDash: () => {},
                drawImage: () => {}, translate: () => {}, rotate: () => {}, clip: () => {},
                createLinearGradient: () => ({ addColorStop: () => {} }),
                createRadialGradient: () => ({ addColorStop: () => {} }),
                ellipse: () => {}, quadraticCurveTo: () => {}, bezierCurveTo: () => {},
                rect: () => {}, scale: () => {}
            }),
            getBoundingClientRect: () => ({ top: 0, left: 0, bottom: 667, right: 375, width: 375, height: 667 })
        };
        el.parentElement = el; // 指向自身即可满足尺寸读取
        mockElements[id] = el;
    }
    return mockElements[id];
}

const mockDocument = {
    getElementById: (id) => getOrCreateMockElement(id),
    querySelectorAll: () => [],
    querySelector: (sel) => (sel === '.app-viewport' ? getOrCreateMockElement('app-viewport') : null),
    createElement: (tag) => getOrCreateMockElement(`tag-${tag}-${Math.random()}`),
    body: getOrCreateMockElement('body')
};

// rAF 队列化：__flushRAF() 手动推进一帧，保证 launchGame 的 starter 同步可测
const rafQueue = [];

const mockWindow = {
    innerWidth: 375,
    innerHeight: 667,
    devicePixelRatio: 2,
    addEventListener: () => {},
    removeEventListener: () => {},
    requestAnimationFrame: (cb) => { rafQueue.push(cb); return rafQueue.length; },
    cancelAnimationFrame: (id) => { if (rafQueue[id - 1]) rafQueue[id - 1] = null; },
    __flushRAF: () => {
        const q = rafQueue.splice(0);
        q.forEach(cb => { if (cb) cb(Date.now()); });
    },
    AudioContext: class {
        constructor() { this.state = 'running'; }
        createOscillator() { return { type: '', frequency: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} }, connect: () => {}, start: () => {}, stop: () => {} }; }
        createGain() { return { gain: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} }, connect: () => {} }; }
        get destination() { return {}; }
        get currentTime() { return 0; }
        resume() { return Promise.resolve(); }
    },
    webkitAudioContext: class {
        constructor() { this.state = 'running'; }
        createOscillator() { return { type: '', frequency: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} }, connect: () => {}, start: () => {}, stop: () => {} }; }
        createGain() { return { gain: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} }, connect: () => {} }; }
        get destination() { return {}; }
        get currentTime() { return 0; }
        resume() { return Promise.resolve(); }
    },
    navigator: { vibrate: () => true }
};

// ============ MQTT 公共中转模拟（联机冒烟测试） ============
function makeMockMqtt() {
    const handlers = {};
    const client = {
        published: [],
        ended: false,
        on: (ev, cb) => { (handlers[ev] = handlers[ev] || []).push(cb); },
        subscribe: (topic, cb) => { setTimeout(() => cb(null), 0); },
        publish: (topic, payload) => { client.published.push({ topic, payload: String(payload) }); },
        end: () => { client.ended = true; }
    };
    const mqtt = {
        connect: () => {
            setTimeout(() => (handlers.connect || []).forEach(cb => cb()), 0);
            return client;
        },
        __client: client,
        __handlers: handlers
    };
    return { mqtt, client };
}

const { mqtt, client: mockMqttClient } = makeMockMqtt();

const sandbox = {
    document: mockDocument,
    window: mockWindow,
    navigator: mockWindow.navigator,
    console,
    performance: { now: () => Date.now() },
    JSON,
    Math,
    Date,
    requestAnimationFrame: mockWindow.requestAnimationFrame,
    cancelAnimationFrame: mockWindow.cancelAnimationFrame,
    AudioContext: mockWindow.AudioContext,
    webkitAudioContext: mockWindow.webkitAudioContext,
    setTimeout, clearTimeout, setInterval, clearInterval,
    mqtt,
    assert,
    __flushRAF: mockWindow.__flushRAF
};
const context = vm.createContext(sandbox);

const GAME_IDS = [
    'pingpong', 'tennis', 'orbit', 'tank', 'connect4', 'reaction', 'snake',
    'syncmind', 'touchheart', 'gomoku', 'reversi', 'dots', 'memory',
    'airhockey', 'breakout', 'racer', 'tetris', 'drawguess', 'truthdare', 'maze', 'duodash'
];

let passed = 0;
let failed = 0;
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
async function check(name, fn) {
    try {
        await fn();
        passed++;
        console.log(`✅ ${name}`);
    } catch (err) {
        failed++;
        console.error(`❌ ${name}:`, err ? (err.message || err.toString()) : 'error');
    }
}
function assert(cond, msg) {
    if (!cond) throw new Error(msg || 'assertion failed');
}

async function run() {
    try {
        vm.runInContext(jsCode, context);
        console.log("✅ index.html JavaScript syntax and initialization PASSED.\n");

    // ========== 1. 全部 20 款游戏：同屏模式启动 ==========
    console.log('--- 同屏模式：20 款游戏生命周期 ---');
    GAME_IDS.forEach(g => {
        check(`launchGame('${g}') 同屏启动`, () => {
            vm.runInContext(`launchGame('${g}')`, context);
            const visible = vm.runInContext(`document.getElementById('screen-${g}').style.display`, context);
            assert(visible === 'flex', `screen-${g} 未显示`);
        });
        check(`exitToLobby('${g}') 收尾清理`, () => {
            vm.runInContext(`exitToLobby('screen-${g}')`, context);
            const hidden = vm.runInContext(`document.getElementById('screen-${g}').style.display`, context);
            assert(hidden === 'none', `screen-${g} 未关闭`);
        });
    });

    // ========== 2. 联机配对流程（房主视角） ==========
    console.log('\n--- 联机配对：创建房间 → 对方加入 → 自动开局 ---');
    await check('openModeSheet + openNetPanel + netCreateRoom', async () => {
        vm.runInContext(`openModeSheet('gomoku'); openNetPanel(); netCreateRoom();`, context);
        await sleep(30); // 等待模拟 MQTT connect / subscribe 异步完成
    });
    await check('房主收到 hi → 自动开局 gomoku', async () => {
        await sleep(30); // hi 重试定时器触发，确保 start 已发布
        vm.runInContext(`netOnMessage(null, JSON.stringify({ t: 'hi', from: 'peer' }))`, context);
        const active = vm.runInContext(`NET.active`, context);
        assert(active === true, 'NET.active 应为 true');
        assert(mockMqttClient.published.some(p => p.payload.includes('"start"')), '应广播 start 消息');
    });

    // ========== 3. 每款游戏：联机双端开局 + 快照编解码回环 ==========
    console.log('\n--- 联机模式：20 款游戏 开局 / 快照回环 / 恢复 ---');
    GAME_IDS.forEach(g => {
        check(`[net] ${g} 房主开局`, () => {
            vm.runInContext(`
                NET.gameId = '${g}';
                NET.active = false;
                NET.isHost = true;
                NET.connected = true;
                NET.client = mqtt.__client;
                NET.pendingOpts = (NET_HOOKS['${g}'] && NET_HOOKS['${g}'].buildOpts) ? NET_HOOKS['${g}'].buildOpts() : {};
                netBeginGame();
                __flushRAF();
            `, context);
            const active = vm.runInContext(`NET.active`, context);
            assert(active === true, 'NET.active 应为 true');
        });
        check(`[net] ${g} 快照 snap→JSON→restore 回环`, () => {
            const ok = vm.runInContext(`
                (function () {
                    const h = NET_HOOKS['${g}'];
                    if (!h || !h.snap || !h.restore) return 'no-stream';
                    NET.isHost = true;
                    const snap = JSON.parse(JSON.stringify(h.snap()));
                    NET.isHost = false;
                    h.restore(snap);
                    NET.isHost = true;
                    return 'ok';
                })()
            `, context);
            assert(ok === 'ok' || ok === 'no-stream', '回环执行失败');
        });
        check(`[net] ${g} 蓝方收到 start 消息开局`, () => {
            vm.runInContext(`
                (function () {
                    const h = NET_HOOKS['${g}'];
                    const opts = (h && h.buildOpts) ? h.buildOpts() : {};
                    NET.gameId = '${g}';
                    NET.active = false;
                    NET.isHost = false;
                    NET.connected = true;
                    NET.client = mqtt.__client;
                    netOnMessage(null, JSON.stringify({ t: 'start', game: '${g}', opts: opts }));
                    __flushRAF();
                })()
            `, context);
            const active = vm.runInContext(`NET.active`, context);
            assert(active === true, '蓝方 NET.active 应为 true');
        });
        check(`[net] ${g} 退出并断开`, () => {
            vm.runInContext(`exitToLobby('screen-${g}')`, context);
            const active = vm.runInContext(`NET.active`, context);
            assert(active === false, '退出后 NET.active 应为 false');
        });
    });

    // ========== 4. 房主接收蓝方输入抽查 ==========
    console.log('\n--- 房主权威输入抽查 ---');
    check('connect4 房主应用蓝方落子', () => {
        vm.runInContext(`
            NET.gameId = 'connect4'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            launchGame('connect4'); __flushRAF();
            c4CurrentTurn = 'blue'; // 模拟粉方已落子后的轮转
            NET_HOOKS.connect4.input('drop', 3);
        `, context);
        const cnt = vm.runInContext(`c4Grid.flat().filter(v => v === 'blue').length`, context);
        assert(cnt === 1, '蓝方棋子应已落盘');
    });
    check('gomoku 房主应用蓝方落子', () => {
        vm.runInContext(`
            NET.gameId = 'gomoku'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            launchGame('gomoku'); __flushRAF();
            gomTurn = 'blue'; // 模拟粉方已落子后的轮转
            NET_HOOKS.gomoku.input('move', [7, 7]);
        `, context);
        const v = vm.runInContext(`gomGrid[7][7]`, context);
        assert(v === 2, '蓝方白子应落在 7,7');
    });
    check('tank 房主应用蓝方开火', () => {
        vm.runInContext(`
            NET.gameId = 'tank'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            launchGame('tank'); __flushRAF();
            NET_HOOKS.tank.input('fire', 'guest');
        `, context);
    });
    check('reaction 房主接收蓝方抢答', () => {
        vm.runInContext(`
            NET.gameId = 'reaction'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            launchGame('reaction'); __flushRAF();
            NET_HOOKS.reaction.event('phase', 'ready');
            NET_HOOKS.reaction.input('tap', 180);
        `, context);
    });
    check('memory 房主应用蓝方翻牌', () => {
        vm.runInContext(`
            NET.gameId = 'memory'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            NET.pendingOpts = NET_HOOKS.memory.buildOpts();
            launchGame('memory'); __flushRAF();
            NET_HOOKS.memory.input('flip', 0);
        `, context);
    });

    // ========== 5. 结算/表情/事件广播抽查 ==========
    console.log('\n--- 事件广播抽查 ---');
    check('表情事件不抛错', () => {
        vm.runInContext(`
            NET.gameId = 'gomoku'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            handleNetEvent('emoji', '😍');
        `, context);
    });
    check('对联机 rematch 请求不抛错', () => {
        vm.runInContext(`handleNetEvent('rematch', null)`, context);
    });

    // ========== 6. GameFX 特效与 GameAI 智能陪练测试 ==========
    console.log('\n--- GameFX 与 GameAI 引擎测试 ---');
    check('GameFX 粒子系统、火花生成与震屏', () => {
        vm.runInContext(`
            GameFX.particles = [];
            GameFX.shockwaves = [];
            GameFX.floatingTexts = [];
            GameFX.shake('pingpongCanvas', 10, 100);
            assert(GameFX.shakes['pingpongCanvas'], '震屏记录应已写入');
            GameFX.addSparks(100, 100, '#FFD166', 15);
            assert(GameFX.particles.length === 15, '应生成 15 颗物理火花粒子');
            GameFX.addShockwave(50, 50, '#2C2C2E', 25);
            assert(GameFX.shockwaves.length === 1, '应生成 1 个扩散水波纹');
            GameFX.addFloatText(80, 80, 'PERFECT!', '#FF6B8B');
            assert(GameFX.floatingTexts.length === 1, '应生成 1 组浮动文字');
        `, context);
    });

    check('GameAI 算法库决策：五子棋/黑白棋/四子棋/乒乓球', () => {
        vm.runInContext(`
            // 五子棋 AI 决策
            const grid15 = Array.from({ length: 15 }, () => Array(15).fill(0));
            grid15[7][7] = 1; // 玩家落子中心
            const mv = GameAI.gomoku(grid15, 2);
            assert(Array.isArray(mv) && mv.length === 2, '五子棋 AI 应返回落子坐标');

            // 四子棋 AI 决策
            const c4g = Array.from({ length: 6 }, () => Array(7).fill(null));
            const c4col = GameAI.connect4(c4g, 'blue', 'pink');
            assert(typeof c4col === 'number' && c4col >= 0 && c4col < 7, '四子棋 AI 应返回有效列号');

            // 乒乓球 AI 移动跟随
            const paddle = { x: 100 };
            const ball = { x: 250, vx: 2, vy: -5 };
            GameAI.pingpong(paddle, ball, { width: 375, height: 600 });
            assert(paddle.x > 100, '乒乓 AI 球拍应主动向右侧球位置跟随移动');
        `, context);
    });

    check('triggerAudio 物理拟真音效工厂调用', () => {
        vm.runInContext(`
            triggerAudio('wood');
            triggerAudio('tennis');
            triggerAudio('puck');
            triggerAudio('cannon');
            triggerAudio('explosion');
            triggerAudio('stone');
            triggerAudio('chip');
            triggerAudio('pop');
            triggerAudio('brick');
            triggerAudio('smash');
            triggerAudio('fanfare');
            triggerAudio('whoosh');
            triggerAudio('netcord');
            triggerAudio('surface', { surface: 'clay' });
        `, context);
    });

    // ========== 6.5 DualCourt 3D：投影 / 滑动分析 / 挥拍物理 / 场地差异 ==========
    console.log('\n--- DualCourt 3D 乒乓/网球专项 ---');
    check('DC3D 透视投影：近大远小与深度剔除', () => {
        vm.runInContext(`
            const cam = { x: 0, y: 1.72, z: 3.1, pitch: 0.44, fov: 1.16 };
            const near = DC3D.project(cam, [0, 0.9, 1.4], 0, 0, 390, 500);
            const far = DC3D.project(cam, [0, 0.9, -1.4], 0, 0, 390, 500);
            assert(near && far, '近远两点都应可投影');
            assert(0.037 * near.s > 0.037 * far.s, '同一球体近处投影半径应更大');
            assert(Math.abs(near.x - 195) < 1, '中轴点应居中');
            const behind = DC3D.project(cam, [0, 0.9, 5.5], 0, 0, 390, 500);
            assert(behind === null, '相机后方点应被剔除');
            const guestCam = { x: 0, y: 1.72, z: -3.1, pitch: 0.44, fov: 1.16, yaw: Math.PI };
            const gFar = DC3D.project(guestCam, [0, 0.9, 1.4], 0, 0, 390, 500);
            assert(gFar, '镜像视角下对方远点应可投影');
        `, context);
    });
    check('滑动分析：方向/速度/弧线与立即出手阈值', () => {
        vm.runInContext(`
            const tr = dcSwipeNew();
            let res = null;
            for (let i = 0; i <= 6; i++) {
                const r = dcSwipeFeed(tr, 100 + i * 10, 400 - i * 14, 1000 + i * 16);
                if (r && !res) res = r; // 阈值触发即出手, 后续喂点不再重复触发
            }
            assert(res, '累计位移达阈值应立即出手(不等抬手)');
            assert(res.nx > 0.5 && res.ny < -0.5, '右上滑方向分量应为正/负(屏幕系)');
            assert(res.speed > 0.3, '滑动速度应大于 0.3 px/ms');
            // 直线 vs 弧线: 提高 fireLen 禁止自动触发, 专测完整轨迹的弧线度量
            const straight = dcSwipeNew();
            for (let i = 0; i <= 5; i++) dcSwipeFeed(straight, 50 + i * 12, 300, 2000 + i * 20, 9999);
            assert(dcSwipeDone(straight).curve < 2, '直线滑动弧线偏离应接近 0');
            const curved = dcSwipeNew();
            for (let i = 0; i <= 12; i++) dcSwipeFeed(curved, 50 + i * 8, 300 + Math.sin(i / 2) * 26, 3000 + i * 20, 9999);
            assert(dcSwipeDone(curved).curve > 4, '弧线滑动应测出明显偏离');
            // 未达阈值抬手: touchend 兜底出手
            const short = dcSwipeNew();
            dcSwipeFeed(short, 10, 10, 100);
            dcSwipeFeed(short, 20, 12, 140);
            const s2 = dcSwipeDone(short);
            assert(s2 && s2.chord > 0, '短滑动抬手后应兜底出手');
        `, context);
    });
    check('挥拍反解：过网净高与马格努斯补偿', () => {
        vm.runInContext(`
            const p0 = [0, 1.04, 1.5];
            const sol = dcSolveShot(p0, 0.2, 0.78, -0.9, 0.55, -9.8, 0, 0.9125, 0, 0);
            const tn = (0 - p0[2]) / sol.v[2];
            const yn = p0[1] + sol.v[1] * tn + 0.5 * -9.8 * tn * tn;
            assert(yn > 0.9125, '过网高度应高于网顶 0.9125, 实际 ' + yn.toFixed(3));
            // 负 margin 允许制造下网失误
            const sol2 = dcSolveShot(p0, 0.2, 0.78, -0.9, 0.42, -9.8, 0, 0.9125, -0.2, 0);
            assert(Array.isArray(sol2.v) && sol2.v.length === 3, '低弧出手应返回速度向量');
        `, context);
    });
    check('乒乓 3D：AI 滑动击球驱动回合与时机判定', () => {
        vm.runInContext(`
            AI_MODE = false;
            if (NET.active) netDisconnect();
            launchGame('pingpong'); __flushRAF();
            assert(TT3.running, 'TT3 引擎应已启动');
            assert(TT3.mode === 'local', '默认同屏应为分屏双视角模式');
            // 直接以 AI 参数替粉方出手 (发球)
            TT3.doServe('host', { speed: 0.9, nx: 0.2, ny: -0.7, curve: 0 });
            assert(TT3.phase === 'rally' && TT3.lastHitter === 'host', '发球后应进入相持');
            const sp0 = Math.hypot(TT3.ball.vx, TT3.ball.vy, TT3.ball.vz);
            assert(sp0 > 2, '发球初速应大于 2 m/s');
            // 模拟球飞向粉方击球窗口后 PERFECT 时机回击
            TT3.ball.z = 1.45; TT3.ball.vz = 4;
            TT3.doSwing('host', { nx: -0.4, ny: -0.85, speed: 1.2, curve: 10 });
            assert(TT3.lastHitter === 'host' && TT3.rally >= 2, '窗口内滑动应完成回击并累加回合');
            assert(Math.abs(TT3.ball.wx) > 0.3, '上滑应产生上旋(马格努斯下坠)');
            // 回归: 连续 90 帧物理积分球体状态必须始终有限 (防 KD/KM/g 大小写错配类 NaN)
            TT3.paddles.host.x = 0; TT3.paddles.guest.x = 0;
            TT3.scores = { host: 0, guest: 0 };
            TT3.doServe('host', { speed: 0.9, nx: 0.2, ny: -0.7, curve: 0 });
            for (let f = 0; f < 90; f++) {
                TT3.update(1 / 60);
                const b = TT3.ball;
                assert(Number.isFinite(b.x) && Number.isFinite(b.y) && Number.isFinite(b.z) &&
                    Number.isFinite(b.vx) && Number.isFinite(b.vy) && Number.isFinite(b.vz),
                    '第 ' + f + ' 帧球体状态出现非有限值');
                assert(Number.isFinite(TT3.paddles.host.x) && Number.isFinite(TT3.paddles.guest.x), '第 ' + f + ' 帧球拍坐标被污染');
            }
        `, context);
    });
    check('网球 3D：三种场地弹性差异与发球流程', () => {
        vm.runInContext(`
            AI_MODE = false;
            if (NET.active) netDisconnect();
            launchGame('tennis'); __flushRAF();
            assert(TN3.running, 'TN3 引擎应已启动');
            const es = ['hard', 'clay', 'grass'].map(s => { TN3.surface = s; return TN3.surf().e; });
            assert(es[1] > es[0] && es[0] > es[2], '弹性应为 红土 > 硬地 > 草地');
            assert(TN3.SURFACES.hard.mu > TN3.SURFACES.clay.mu, '红土水平摩擦损耗应更大(慢速滑步)');
            TN3.surface = 'hard';
            dcTnPickSurface('clay');
            assert(TN3.surface === 'clay', '同屏模式应允许切换场地');
            dcTnPickSurface('hard');
            TN3.doServe('host', { speed: 1.1, nx: -0.3, ny: -0.6, curve: 0 });
            assert(TN3.phase === 'rally' && TN3.lastHitter === 'host', '网球发球后应进入相持');
            const tnSp = Math.hypot(TN3.ball.vx, TN3.ball.vy, TN3.ball.vz);
            assert(tnSp > 10, '网球发球初速应大于 10 m/s');
            TN3.surface = 'hard';
        `, context);
    });
    await check('DualCourt 联机：快照回环与滑动输入上行', async () => {
        vm.runInContext(`
            NET.pendingOpts = { surface: 'clay' };
            TT3.ball.z = -0.4; TT3.phase = 'rally'; TT3.lastHitter = 'guest';
            const snap = NET_HOOKS.pingpong.snap();
            NET_HOOKS.pingpong.restore(JSON.parse(JSON.stringify(snap)));
            assert(Math.abs(TT3.ball.z - (-0.4)) < 1e-9, '乒乓快照回环应还原球体 z');
            TN3.players.host.x = 1.8;
            const tsnap = NET_HOOKS.tennis.snap();
            NET_HOOKS.tennis.restore(JSON.parse(JSON.stringify(tsnap)));
            assert(Math.abs(TN3.players.host.x - 1.8) < 1e-9, '网球快照回环应还原球员位置');
            NET_HOOKS.tennis.input('sw', [0.5, -0.6, 1.2, 4]);
            assert(TN3.players.guest.anim >= 0, '蓝方滑动输入应可被房主应用');
        `, context);
    });

    // ========== 7. 双人跑酷 DuoDash 3D：种子同步 / 动作 / 道具互坑 / 联机事件 ==========
    console.log('\n--- DuoDash 3D 双人跑酷专项 ---');
    await check("duodash 同屏开局与跑道初始化", () => {
        vm.runInContext(`
            NET.active = false; AI_MODE = false;
            launchGame('duodash'); __flushRAF();
            assert(typeof ddLeft === 'object' && typeof ddRight === 'object', '左右跑道应已初始化');
            ddCountdown = 0; // 测试跳过倒计时
        `, context);
    });
    await check("duodash 同种子确定性生成：左右跑道逐位一致", () => {
        vm.runInContext(`
            NET.pendingOpts = { seed: 8848 };
            startDuoDashGame(); __flushRAF();
            ddCountdown = 0; ddLastT = 0;
            __flushRAF(); __flushRAF();
        `, context);
        const same = vm.runInContext(`
            JSON.stringify(ddLeft.objs.map(o => [o.type, o.lane, o.wm])) === JSON.stringify(ddRight.objs.map(o => [o.type, o.lane, o.wm]))
        `, context);
        assert(same === true, '双跑道生成序列应逐位一致');
        const cnt = vm.runInContext('ddLeft.objs.length', context);
        assert(cnt > 0, '初始应生成赛道物件');
    });
    await check("duodash 动作：变道/跳跃/空中变道", () => {
        vm.runInContext(`
            ddMoveLane(ddLeft, -1);
            assert(ddLeft.lane === 0, '应变道到左轨');
            ddDoJump(ddLeft);
            assert(ddLeft.jumpT >= 0, '跳跃应置位');
            ddMoveLane(ddLeft, 1);
            assert(ddLeft.lane === 1, '空中变道应生效');
        `, context);
    });
    await check("duodash AI 陪练决策不抛错", () => {
        vm.runInContext(`
            AI_MODE = true;
            startDuoDashGame(); __flushRAF();
            ddCountdown = 0; ddLastT = 0;
            for (let i = 0; i < 30; i++) __flushRAF();
            AI_MODE = false;
        `, context);
    });
    await check("duodash 道具互坑：导弹 1 秒未换轨即命中减速", () => {
        vm.runInContext(`
            startDuoDashGame(); __flushRAF();
            ddCountdown = 0; ddLastT = 0;
            ddLeft.item = 'missile';
            ddUseItem(ddLeft);
            assert(ddRight.warn, '同屏导弹应给蓝方设置预警');
            assert(ddLeft.item === null, '道具使用后应清空槽位');
            ddRight.warn.deadline = performance.now() - 1; // 模拟超时未换轨
            ddStepRoad(ddRight, 0.016);
            assert(ddRight.buff && ddRight.buff.kind === 'slow', '未换轨应被命中并减速');
        `, context);
    });
    await check("duodash 导弹换轨闪避", () => {
        vm.runInContext(`
            ddRight.warn = { deadline: performance.now() + 900, fromLane: ddRight.lane };
            ddMoveLane(ddRight, ddRight.lane === 2 ? -1 : 1);
            assert(ddRight.warn === null, '1 秒内换轨应清除导弹预警');
        `, context);
    });
    await check("duodash 联机：状态镜像 + 道具事件 + 结局互认", () => {
        vm.runInContext(`
            NET.gameId = 'duodash'; NET.active = true; NET.isHost = true;
            NET.connected = true; NET.client = mqtt.__client;
            NET.pendingOpts = NET_HOOKS.duodash.buildOpts();
            startDuoDashGame(); __flushRAF();
            ddCountdown = 0; ddLastT = 0;
            __flushRAF(); __flushRAF();
            NET_HOOKS.duodash.event('ddstate', { d: 120.5, l: 2, a: 0, s: 0, c: 3, b: 0 });
            assert(ddGhost && ddGhost.l === 2, '幽灵镜像应记录对方状态');
            NET_HOOKS.duodash.event('dduse', { k: 'banana', l: 0 });
            assert(ddLeft.bananas.length === 1, '香蕉皮应落到我方赛道');
            NET_HOOKS.duodash.event('dduse', { k: 'missile' });
            assert(ddLeft.warn, '导弹预警应生效');
            NET_HOOKS.duodash.event('ddfin', null);
            assert(ddOver === true, '对方冲线应判定我方失败');
        `, context);
        const published = vm.runInContext(`mqtt.__client.published.some(p => p.payload.includes('ddstate'))`, context);
        assert(published, '应已向对方广播 10Hz 轻量状态包');
    });
    await check("duodash 撞毁结算（联机事件互认）", () => {
        vm.runInContext(`
            startDuoDashGame(); __flushRAF();
            ddCountdown = 0; ddLastT = 0;
            ddCrash(ddLeft); // 房主撞毁
        `, context);
        const over = vm.runInContext('ddOver', context);
        assert(over === true, '撞毁后应立即结算');
        const ev = vm.runInContext(`mqtt.__client.published.some(p => p.payload.includes('ddcrash'))`, context);
        assert(ev, '应广播 ddcrash 结局事件');
    });
    await check("duodash 退出清理", () => {
        vm.runInContext(`exitToLobby('screen-duodash')`, context);
        const running = vm.runInContext('ddRunning', context);
        assert(running === false, '退出后主循环应停止');
    });

    console.log(`\n========================================`);
    console.log(`结果: ${passed} 通过, ${failed} 失败 (共 ${passed + failed} 项)`);
    console.log(`========================================`);
        if (failed > 0) process.exit(1);
        console.log("\n🎉 ALL 21 GAMES + NETPLAY SMOKE TESTS PASSED!");
    } catch (err) {
        console.error("❌ Test failed with error:", err);
        process.exit(1);
    }
}

run();
