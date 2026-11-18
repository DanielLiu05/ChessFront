#!/usr/bin/env node
const fs = require('fs');

let chromium;
let devices;
try {
  ({ chromium, devices } = require('playwright'));
} catch (error) {
  console.error('Playwright is required. Run: cd web && npm install --no-save playwright');
  process.exit(2);
}

const URL = process.env.WEB_URL || 'http://localhost:8060/index.html';
const OUT = process.env.WEB_OUT || 'builds/web/acceptance';
const CHANNEL = process.env.PW_CHANNEL || 'msedge';
const failures = [];

function check(condition, message) {
  if (condition) {
    console.log(`PASS ${message}`);
  } else {
    failures.push(message);
    console.error(`FAIL ${message}`);
  }
}

function primaryY(viewport, insets) {
  const top = insets.top || 0;
  const bottom = insets.bottom || 0;
  const safeHeight = viewport.height - top - bottom;
  const panelHeight = Math.min(760, Math.max(0, safeHeight - 24));
  const panelTop = top + (safeHeight - panelHeight) / 2;
  return panelTop + panelHeight - 38;
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
  await page.goto(URL, { waitUntil: 'load' });
  await page.waitForFunction(() => window.chessfrontReadyMs !== null, null, {
    timeout: 60000,
  });
  return { context, page, errors };
}

async function overlayState(page) {
  return page.evaluate(() => ({
    play: getComputedStyle(document.getElementById('play-overlay')).display,
    rotate: getComputedStyle(document.getElementById('rotate-overlay')).display,
    readyMs: window.chessfrontReadyMs,
    safe: window.chessfrontSafeInsets,
    canvas: (() => {
      const canvas = document.querySelector('canvas');
      return canvas ? [canvas.width, canvas.height, canvas.clientWidth, canvas.clientHeight] : null;
    })(),
    fullscreen: !!document.fullscreenElement,
  }));
}

async function startAiFirst(page, insets) {
  let viewport = page.viewportSize();
  let y = primaryY(viewport, insets);
  for (let index = 0; index < 2; index++) {
    await page.mouse.click(viewport.width / 2, y);
    await page.waitForTimeout(850);
  }
  for (let index = 0; index < 3; index++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(120);
  }
  await page.keyboard.press('Enter');
  await page.waitForTimeout(350);
  for (let index = 0; index < 2; index++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(120);
  }
  await page.keyboard.press('Enter');
  await page.waitForTimeout(1200);
}

async function save(page, name) {
  await page.screenshot({ path: `${OUT}/${name}.png` });
}

async function runDesktop(browser, viewport, name) {
  const insets = { left: 0, top: 0, right: 0, bottom: 0 };
  const { context, page, errors } = await openPage(browser, { viewport }, insets);
  const state = await overlayState(page);
  check(state.play === 'none', `${name}: no play overlay on PC`);
  check(state.rotate === 'none', `${name}: no rotate overlay on PC`);
  await save(page, `${name}_setup`);
  await startAiFirst(page, insets);
  await page.waitForTimeout(7000);
  await save(page, `${name}_match`);
  check(errors.length === 0, `${name}: no console errors (${errors.slice(0, 2).join('; ')})`);
  await context.close();
}

async function runMobile(browser, deviceName, name) {
  const insets = { left: 0, top: 40, right: 0, bottom: 24 };
  const { context, page, errors } = await openPage(
    browser,
    { ...devices[deviceName] },
    insets
  );
  let state = await overlayState(page);
  check(state.play === 'flex', `${name}: tap-to-play overlay is visible`);
  check(state.rotate === 'none', `${name}: no rotate overlay in portrait`);
  check(
    state.canvas !== null && state.canvas[0] <= state.canvas[2] * 2 + 2,
    `${name}: canvas DPR is capped at 2x`
  );
  await save(page, `${name}_play`);

  let viewport = page.viewportSize();
  await page.mouse.click(viewport.width / 2, viewport.height / 2);
  await page.waitForTimeout(800);
  state = await overlayState(page);
  check(state.play === 'none', `${name}: tap hides the play overlay`);

  await startAiFirst(page, insets);
  await page.waitForTimeout(7000);
  await save(page, `${name}_match`);

  viewport = page.viewportSize();
  await page.setViewportSize({ width: viewport.height, height: viewport.width });
  await page.waitForTimeout(700);
  state = await overlayState(page);
  check(state.rotate === 'flex', `${name}: landscape shows the rotate overlay`);
  await save(page, `${name}_rotate`);

  await page.setViewportSize(viewport);
  await page.waitForTimeout(700);
  state = await overlayState(page);
  check(state.rotate === 'none', `${name}: returning to portrait hides the rotate overlay`);
  check(errors.length === 0, `${name}: no console errors (${errors.slice(0, 2).join('; ')})`);
  await context.close();
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ channel: CHANNEL, headless: true });
  try {
    await runDesktop(browser, { width: 1280, height: 720 }, 'desktop_1280');
    await runDesktop(browser, { width: 1920, height: 1080 }, 'desktop_1920');
    await runDesktop(browser, { width: 600, height: 900 }, 'narrow_pc');
    await runMobile(browser, 'Pixel 7', 'android');
    await runMobile(browser, 'iPhone 13', 'ios');
  } finally {
    await browser.close();
  }
  console.log(`Web acceptance complete: ${failures.length} failure(s)`);
  process.exit(failures.length === 0 ? 0 : 1);
})();
