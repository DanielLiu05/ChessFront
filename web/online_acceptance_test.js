#!/usr/bin/env node
const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawn } = require('child_process');

let chromium;
let devices;
try {
  ({ chromium, devices } = require('playwright'));
} catch (error) {
  console.error('Playwright is required. Run: cd web && npm install --no-save playwright');
  process.exit(2);
}

const ROOT = path.resolve(__dirname, '..');
const WEB_ROOT = path.join(ROOT, 'builds', 'web');
const OUT = path.join(WEB_ROOT, 'acceptance');
const GODOT = process.env.GODOT || 'D:/Program Files/Godot/godot.exe';
const STATIC_PORT = Number(process.env.ONLINE_STATIC_PORT || 8060);
const SERVER_PORT = Number(process.env.ONLINE_SERVER_PORT || 9000);
const CHANNEL = process.env.PW_CHANNEL || 'msedge';
const SERVER_URL = `ws://127.0.0.1:${SERVER_PORT}`;
const PAGE_URL = `http://localhost:${STATIC_PORT}/repo/index.html?online_test=1`;
const GRACE_SECONDS = 12;
const failures = [];

const MIME = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.png': 'image/png',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.css': 'text/css',
};

function check(condition, message) {
  if (condition) {
    console.log(`PASS ${message}`);
  } else {
    failures.push(message);
    console.error(`FAIL ${message}`);
  }
}

function startStaticServer() {
  return new Promise((resolve, reject) => {
    const server = http.createServer((request, response) => {
      const url = new URL(request.url, 'http://localhost');
      let relative = decodeURIComponent(url.pathname);
      if (relative === '/' || relative === '/repo' || relative === '/repo/') {
        relative = '/repo/index.html';
      }
      if (!relative.startsWith('/repo/')) {
        response.writeHead(404);
        response.end('Not found');
        return;
      }
      const file = path.join(WEB_ROOT, relative.slice('/repo/'.length));
      if (!file.startsWith(WEB_ROOT)) {
        response.writeHead(403);
        response.end('Forbidden');
        return;
      }
      fs.readFile(file, (error, data) => {
        if (error) {
          response.writeHead(404);
          response.end('Not found');
          return;
        }
        response.writeHead(200, {
          'Content-Type': MIME[path.extname(file)] || 'application/octet-stream',
          'Cache-Control': 'no-store',
        });
        response.end(data);
      });
    });
    server.on('error', reject);
    server.listen(STATIC_PORT, '127.0.0.1', () => resolve(server));
  });
}

function startGodotServer() {
  return new Promise((resolve, reject) => {
    const child = spawn(GODOT, [
      '--headless',
      '--path',
      ROOT,
      '--script',
      'res://scripts/net/server_main.gd',
      '--',
      '--port',
      String(SERVER_PORT),
      '--bind',
      '127.0.0.1',
      '--grace-seconds',
      String(GRACE_SECONDS),
    ], { cwd: ROOT });
    let settled = false;
    let output = '';
    const timer = setTimeout(() => {
      if (!settled) {
        settled = true;
        child.kill();
        reject(new Error(`Godot server did not start: ${output.slice(-800)}`));
      }
    }, 60000);
    child.stdout.on('data', (data) => {
      output += String(data);
      if (!settled && output.includes('listening on ws://')) {
        settled = true;
        clearTimeout(timer);
        resolve(child);
      }
    });
    child.stderr.on('data', (data) => {
      output += String(data);
    });
    child.on('exit', (code) => {
      if (!settled) {
        settled = true;
        clearTimeout(timer);
        reject(new Error(`Godot server exited early (${code}): ${output.slice(-800)}`));
      }
    });
  });
}

async function openPage(browser, options, insets) {
  const context = await browser.newContext(options);
  if (insets) {
    await context.addInitScript((value) => {
      window.chessfrontSafeInsetsOverride = value;
    }, insets);
  }
  const page = await context.newPage();
  const errors = [];
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('pageerror', (error) => errors.push(String(error)));
  await page.goto(PAGE_URL, { waitUntil: 'load' });
  await page.waitForFunction(
    () => window.chessfrontReadyMs !== null
      && typeof window.chessfrontOnlineCommand === 'function',
    null,
    { timeout: 60000 }
  );
  return { context, page, errors };
}

async function command(page, name, argument = '') {
  return page.evaluate(({ name, argument }) => {
    const raw = window.chessfrontOnlineCommand(name, argument);
    return JSON.parse(raw);
  }, { name, argument });
}

async function state(page) {
  const result = await command(page, 'state');
  if (!result.ok) throw new Error(`state command failed: ${JSON.stringify(result)}`);
  return result.state;
}

async function waitFor(page, predicate, label, timeout = 20000) {
  const deadline = Date.now() + timeout;
  let last = null;
  while (Date.now() < deadline) {
    last = await state(page);
    if (predicate(last)) return last;
    await page.waitForTimeout(100);
  }
  throw new Error(`timeout waiting for ${label}: ${JSON.stringify(last).slice(0, 1200)}`);
}

async function waitForConnection(page) {
  return waitFor(page, (value) => value.client_state === 'connected', 'client connection');
}

async function openOnline(page) {
  const result = await command(page, 'openOnline');
  check(result.ok, `online page opens: ${result.error || ''}`);
  await waitFor(page, (value) => value.setup_page === 3, 'online setup page');
}

async function visibleHud(value) {
  for (const name of ['HUD', 'MobileHUD']) {
    const hud = value.hud && value.hud[name];
    if (hud && hud.visible) return hud;
  }
  return null;
}

async function save(page, name) {
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
}

async function run() {
  fs.mkdirSync(OUT, { recursive: true });
  if (!fs.existsSync(path.join(WEB_ROOT, 'index.html'))) {
    throw new Error('builds/web/index.html is missing; export the Web preset first');
  }
  const staticServer = await startStaticServer();
  const godot = await startGodotServer();
  const browser = await chromium.launch({ channel: CHANNEL, headless: true });
  const contexts = [];
  try {
    const desktop = await openPage(browser, { viewport: { width: 1280, height: 720 } }, null);
    contexts.push(desktop.context);
    const mobileInsets = { left: 0, top: 40, right: 0, bottom: 24 };
    const mobile = await openPage(browser, { ...devices['Pixel 7'] }, mobileInsets);
    contexts.push(mobile.context);
    const a = desktop.page;
    const b = mobile.page;

    await a.mouse.click(640, 360);
    await b.mouse.click(400, 800);
    await a.waitForTimeout(800);

    await openOnline(a);
    await openOnline(b);
    const connectA = await command(a, 'connect', SERVER_URL);
    const connectB = await command(b, 'connect', SERVER_URL);
    check(connectA.ok, 'desktop client connects');
    check(connectB.ok, 'mobile client connects');
    await waitForConnection(a);
    await waitForConnection(b);

    const created = await command(a, 'create');
    check(created.ok, 'desktop creates a room');
    const roomA = await waitFor(a, (value) => value.client_state === 'in_room', 'room creation');
    const code = roomA.code;
    check(/^[A-Z2-9]{6}$/.test(code), `room code is six characters (${code})`);
    const joined = await command(b, 'join', code);
    check(joined.ok, 'mobile joins the room');
    await waitFor(b, (value) => value.client_state === 'in_room', 'mobile lobby');
    await waitFor(a, (value) => value.room.full === true && value.room.joiner_connected === true, 'full room');
    const mapped = await command(a, 'selectMap', 'borderlands');
    check(mapped.ok, 'owner selects a map');
    await waitFor(a, (value) => value.room.map_id === 'borderlands', 'map selection');
    const started = await command(a, 'start');
    check(started.ok, 'owner starts the match');
    const stateA = await waitFor(a, (value) => value.online_mode && value.local_player > 0, 'desktop match');
    const stateB = await waitFor(b, (value) => value.online_mode && value.local_player > 0, 'mobile match');
    check(stateA.local_player !== stateB.local_player, 'clients receive opposite sides');
    check(stateA.assignment.first_player === stateB.assignment.first_player, 'both clients share the first player');
    check(!stateA.ai_running && !stateB.ai_running, 'no AI loop runs online');
    check(stateA.known_units < 32 && stateB.known_units < 32, 'both views are fog-limited');
    check(JSON.stringify(stateA).indexOf('player_gold') === -1, 'no gold table reaches the client');

    const hudA = await visibleHud(stateA);
    const hudB = await visibleHud(stateB);
    check(hudA && hudA.gold.includes('Opponent ?'), `desktop HUD hides enemy gold (${hudA && hudA.gold})`);
    check(hudB && hudB.gold.includes('Opponent ?'), `mobile HUD hides enemy gold (${hudB && hudB.gold})`);
    check(hudA && (hudA.turn.includes('You') || hudA.turn.includes('waiting')), 'desktop turn label uses You/Opponent');
    check(hudB && (hudB.turn.includes('You') || hudB.turn.includes('waiting')), 'mobile turn label uses You/Opponent');
    await save(a, 'desktop_online_match');
    await save(b, 'mobile_online_match');

    let active = stateA;
    let activePage = a;
    let idle = stateB;
    let idlePage = b;
    if (!stateA.can_act && stateB.can_act) {
      active = stateB;
      activePage = b;
      idle = stateA;
      idlePage = a;
    }
    const gated = await command(idlePage, 'moveFirst');
    check(!gated.ok, 'the inactive client cannot submit');
    const moved = await command(activePage, 'moveFirst');
    check(moved.ok, 'the active client submits a move through the gateway');
    const afterA = await waitFor(a, (value) => value.ply === 1, 'desktop ply 1');
    const afterB = await waitFor(b, (value) => value.ply === 1, 'mobile ply 1');
    check(
      (idlePage === a ? afterA : afterB).logs.length === 0,
      'a hidden opponent move is not logged'
    );

    const offered = await command(a, 'offerDraw');
    check(offered.ok, 'draw offer is sent');
    await waitFor(b, (value) => value.incoming_draw_offer === true, 'incoming draw offer');
    const accepted = await command(b, 'acceptDraw');
    check(accepted.ok, 'draw is accepted');
    const gameA = await waitFor(a, (value) => value.game_over === true, 'desktop game over');
    const gameB = await waitFor(b, (value) => value.game_over === true, 'mobile game over');
    const endHudA = await visibleHud(gameA);
    const endHudB = await visibleHud(gameB);
    check(endHudA && endHudA.rematch === 'Another Match', 'desktop offers Another Match');
    check(endHudA && endHudA.leave === 'Leave Room', 'desktop offers Leave Room');
    check(endHudB && endHudB.rematch === 'Another Match', 'mobile offers Another Match');
    check(endHudB && endHudB.leave === 'Leave Room', 'mobile offers Leave Room');
    check(endHudA && endHudA.gold.includes('Opponent ?'), 'desktop keeps enemy gold hidden at game over');
    check(endHudB && endHudB.gold.includes('Opponent ?'), 'mobile keeps enemy gold hidden at game over');
    await save(a, 'desktop_online_game_over');
    await save(b, 'mobile_online_game_over');

    await command(a, 'rematch');
    await command(b, 'rematch');
    await waitFor(a, (value) => value.setup_visible && !value.online_mode && value.client_state === 'in_room', 'desktop lobby');
    await waitFor(b, (value) => value.setup_visible && !value.online_mode && value.client_state === 'in_room', 'mobile lobby');
    const lobby = await state(a);
    check(String(lobby.room.map_id || '').length === 0, 'Another Match clears the map for reselection');
    await command(a, 'selectMap', 'borderlands');
    await waitFor(a, (value) => value.room.map_id === 'borderlands', 'second map selection');
    await command(a, 'start');
    const rematchA = await waitFor(a, (value) => value.online_mode, 'second desktop match');
    const rematchB = await waitFor(b, (value) => value.online_mode, 'second mobile match');
    check(rematchA.assignment.match_number === rematchB.assignment.match_number, 'both clients share the second match number');

    const plyBeforeReload = rematchA.ply;
    await b.reload({ waitUntil: 'load' });
    await b.waitForFunction(
      () => window.chessfrontReadyMs !== null
        && typeof window.chessfrontOnlineCommand === 'function',
      null,
      { timeout: 60000 }
    );
    await waitFor(a, (value) => value.overlay.visible === true && value.overlay.mode === 'opponent', 'waiting overlay');
    await save(a, 'desktop_online_waiting');
    await b.mouse.click(400, 800);
    await b.waitForTimeout(500);
    const resumedConnect = await command(b, 'connect', SERVER_URL);
    check(resumedConnect.ok, 'reloaded client reconnects');
    const resumedB = await waitFor(b, (value) => value.online_mode, 'mobile resume');
    const resumedA = await waitFor(a, (value) => value.overlay.visible === false, 'desktop overlay clears');
    check(resumedB.ply === plyBeforeReload, 'mobile resumes the same ply');
    check(resumedA.online_mode === true, 'desktop stays in the match');
    await save(b, 'mobile_online_resumed');

    await b.context().close();
    await waitFor(a, (value) => value.overlay.visible === true && value.overlay.mode === 'opponent', 'expiry waiting overlay');
    const aborted = await waitFor(
      a,
      (value) => !value.online_mode && value.setup_visible,
      'grace expiry abort',
      (GRACE_SECONDS + 12) * 1000
    );
    check(aborted.client_state === 'connected', 'remaining client stays connected after abort');
    check(String(aborted.room.code || '').length === 0, 'aborted room is cleared');

    const third = await openPage(browser, { viewport: { width: 1280, height: 720 } }, null);
    contexts.push(third.context);
    const c = third.page;
    await openOnline(c);
    await command(c, 'connect', SERVER_URL);
    await waitForConnection(c);
    await command(a, 'create');
    const thirdRoom = await waitFor(a, (value) => value.client_state === 'in_room', 'third room');
    await command(c, 'join', thirdRoom.code);
    await waitFor(c, (value) => value.room.full === true, 'third room full');
    await command(a, 'selectMap', 'borderlands');
    await waitFor(a, (value) => value.room.map_id === 'borderlands', 'third map');
    await command(a, 'start');
    await waitFor(a, (value) => value.online_mode, 'third desktop match');
    await waitFor(c, (value) => value.online_mode, 'third joiner match');
    await command(a, 'leave');
    const left = await waitFor(a, (value) => value.setup_visible && !value.online_mode, 'desktop leave');
    const closed = await waitFor(c, (value) => !value.online_mode && value.client_state === 'connected', 'opponent room close');
    check(left.client_state === 'connected', 'leaver returns to online setup');
    check(String(closed.room.code || '').length === 0, 'opponent sees the room close');

    const errors = [...desktop.errors, ...mobile.errors, ...third.errors];
    check(errors.length === 0, `no console errors (${errors.slice(0, 3).join('; ')})`);
  } finally {
    for (const context of contexts) {
      try { await context.close(); } catch (error) { /* already closed */ }
    }
    await browser.close();
    godot.kill();
    staticServer.close();
  }
  console.log(`Online browser acceptance complete: ${failures.length} failure(s)`);
  process.exit(failures.length === 0 ? 0 : 1);
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
