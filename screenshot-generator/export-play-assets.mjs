#!/usr/bin/env node
/**
 * Export Google Play Store assets via Playwright.
 *  - Phone screenshots: 7 slides x 2 locales from variants.html -> 1080x2400
 *  - Feature graphic: feature_graphic.html -> 1024x500
 * Output: play-assets/ (PNGs are written raw at deviceScaleFactor; resizing done by magick afterwards)
 */
import { chromium } from "playwright";
import { mkdirSync, existsSync, writeFileSync } from "fs";
import path from "path";

const BASE_URL = "http://localhost:3001";
const ROOT = path.resolve("play-assets");
const LOCALES = [
  { key: "en", toggle: "#ten", out: "en-US" },
  { key: "de", toggle: "#tde", out: "de-DE" },
];

async function exportScreenshots(browser) {
  for (const loc of LOCALES) {
    const dir = path.join(ROOT, "screenshots", loc.out);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });

    const page = await browser.newPage({ deviceScaleFactor: 4, colorScheme: "dark" });
    await page.goto(`${BASE_URL}/variants.html`, { waitUntil: "networkidle" });
    await page.click(loc.toggle);
    await page.waitForTimeout(800);

    const slides = page.locator(".cell .slide");
    const count = await slides.count();
    console.log(`\n[${loc.out}] ${count} slides`);

    for (let i = 0; i < count; i++) {
      const el = slides.nth(i);
      await el.scrollIntoViewIfNeeded();
      await page.waitForTimeout(120);
      const buf = await el.screenshot({ type: "png" });
      const file = path.join(dir, `${String(i + 1).padStart(2, "0")}.png`);
      writeFileSync(file, buf);
      console.log(`  ✓ ${path.basename(file)}`);
    }
    await page.close();
  }
}

async function exportFeatureGraphic(browser) {
  const page = await browser.newPage({
    viewport: { width: 1024, height: 500 },
    deviceScaleFactor: 2,
    colorScheme: "dark",
  });
  await page.goto(`${BASE_URL}/feature_graphic.html`, { waitUntil: "networkidle" });
  await page.waitForTimeout(600);
  const el = page.locator("#capture");
  await el.waitFor({ state: "visible" });
  const buf = await el.screenshot({ type: "png" });
  if (!existsSync(ROOT)) mkdirSync(ROOT, { recursive: true });
  writeFileSync(path.join(ROOT, "feature_graphic_raw.png"), buf);
  console.log("\n[feature_graphic_raw.png] written (2048x1000)");
  await page.close();
}

async function main() {
  const browser = await chromium.launch();
  await exportScreenshots(browser);
  await exportFeatureGraphic(browser);
  await browser.close();
  console.log("\nDone.");
}
main().catch((e) => { console.error(e); process.exit(1); });
