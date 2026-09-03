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
                fillText: () => {}, measureText: () => ({ width: 50 }), setLineDash: () => {},
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
    __flushRAF: mockWindow.__flushRAF
};
const context = vm.createContext(sandbox);

const GAME_IDS = [
    'pingpong', 'tennis', 'orbit', 'tank', 'connect4', 'reaction', 'snake',
    'syncmind', 'touchheart', 'gomoku', 'reversi', 'dots', 'memory',
    'airhockey', 'breakout', 'racer', 'tetris', 'drawguess', 'truthdare', 'maze'
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
        console.error(`❌ ${name}:`, err && err.stack ? err.stack.split('\n').slice(0, 3).join(' | ') : err);
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

    console.log(`\n========================================`);
    console.log(`结果: ${passed} 通过, ${failed} 失败 (共 ${passed + failed} 项)`);
    console.log(`========================================`);
        if (failed > 0) process.exit(1);
        console.log("\n🎉 ALL 20 GAMES + NETPLAY SMOKE TESTS PASSED!");
    } catch (err) {
        console.error("❌ Test failed with error:", err);
        process.exit(1);
    }
}

run();
