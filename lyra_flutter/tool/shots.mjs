// CI 截图：逐个打开 ?shot=<id>，等待 Flutter 首帧后截图到 tool/shots/
import { chromium } from 'playwright';
import fs from 'node:fs';

const list = JSON.parse(fs.readFileSync('./shots.json', 'utf8'));
fs.mkdirSync('./shots', { recursive: true });
const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
const page = await ctx.newPage();
const logs = [];
page.on('pageerror', e => logs.push('PAGEERROR ' + e.message));
page.on('console', m => { if (m.type() === 'error' || /Exception|Error/.test(m.text())) logs.push(m.type() + ' ' + m.text()); });

let i = 0;
for (const id of list) {
  i++;
  const before = logs.length;
  try {
    await page.goto(`http://localhost:8080/?shot=${encodeURIComponent(id)}`, { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 60000 });
    await page.waitForTimeout(i === 1 ? 9000 : 3500); // 首次需下载 CanvasKit 与回退字体
    await page.screenshot({ path: `./shots/${String(i).padStart(2, '0')}-${id.replace(/[^\w-]+/g, '_')}.png` });
  } catch (e) {
    logs.push(`SHOT-FAIL ${id}: ${e.message}`);
  }
  if (logs.length > before) logs.splice(before, 0, `--- ${id}`);
}
fs.writeFileSync('./shots/log.txt', logs.join('\n') || 'no errors');
await browser.close();
console.log(logs.slice(0, 80).join('\n'));
