#!/usr/bin/env node
/**
 * Headless screenshot export for App Store Connect.
 * Uses Playwright to render each slide at full resolution and saves to fastlane directory structure.
 *
 * Usage: node export-screenshots.mjs [--base-url http://localhost:3001] [--device iphone|ipad|all]
 */

import { chromium } from "playwright";
import { mkdirSync, existsSync, writeFileSync } from "fs";
import path from "path";

const BASE_URL = process.argv.includes("--base-url")
  ? process.argv[process.argv.indexOf("--base-url") + 1]
  : "http://localhost:3001";

const deviceArg = process.argv.includes("--device")
  ? process.argv[process.argv.indexOf("--device") + 1]
  : "all";

const LOCALES = ["en", "de"];
const LOCALE_MAP = { en: "en-US", de: "de-DE" };

const DEVICES = [
  {
    name: "iphone",
    designW: 1320,
    designH: 2868,
    sizes: [
      { label: "iPhone 6.9 inch", w: 1320, h: 2868 },
      { label: "iPhone 6.5 inch", w: 1284, h: 2778 },
      { label: "iPhone 6.3 inch", w: 1206, h: 2622 },
      { label: "iPhone 6.1 inch", w: 1125, h: 2436 },
    ],
  },
  {
    name: "ipad",
    designW: 2064,
    designH: 2752,
    sizes: [
      { label: '13" iPad', w: 2064, h: 2752 },
      { label: '12.9" iPad Pro', w: 2048, h: 2732 },
    ],
  },
];

const SLIDE_COUNT = 7;
const OUTPUT_DIR = path.resolve("fastlane/screenshots");

async function main() {
  console.log("Launching browser...");
  const browser = await chromium.launch();

  const activeDevices = deviceArg === "all"
    ? DEVICES
    : DEVICES.filter(d => d.name === deviceArg);

  for (const device of activeDevices) {
    for (const locale of LOCALES) {
      const ascLocale = LOCALE_MAP[locale];

      for (const size of device.sizes) {
        const dir = path.join(OUTPUT_DIR, ascLocale);
        if (!existsSync(dir)) mkdirSync(dir, { recursive: true });

        const deviceLabel = device.name === "ipad" ? "iPad" : "iPhone";
        console.log(`\n--- ${deviceLabel} ${ascLocale} @ ${size.w}x${size.h} ---`);

        for (let i = 0; i < SLIDE_COUNT; i++) {
          const page = await browser.newPage({
            viewport: { width: device.designW, height: device.designH },
            deviceScaleFactor: 1,
            colorScheme: "dark",
          });

          const url = `${BASE_URL}?slide=${i}&locale=${locale}&device=${device.name}`;
          await page.goto(url, { waitUntil: "networkidle" });
          await page.waitForTimeout(1500);

          const el = page.locator("#capture");
          await el.waitFor({ state: "visible", timeout: 10000 });

          const prefix = device.name === "ipad" ? "iPad" : "iPhone";
          const filename = `${ascLocale}-${prefix}-${String(i + 1).padStart(2, "0")}-${size.w}x${size.h}.png`;
          const filepath = path.join(dir, filename);

          const screenshotBuffer = await el.screenshot({ type: "png" });

          if (size.w !== device.designW || size.h !== device.designH) {
            const resized = await page.evaluate(
              async ({ dataUrl, targetW, targetH }) => {
                return new Promise((resolve) => {
                  const img = new Image();
                  img.onload = () => {
                    const c = document.createElement("canvas");
                    c.width = targetW;
                    c.height = targetH;
                    c.getContext("2d").drawImage(img, 0, 0, targetW, targetH);
                    resolve(c.toDataURL("image/png").split(",")[1]);
                  };
                  img.src = dataUrl;
                });
              },
              {
                dataUrl: `data:image/png;base64,${screenshotBuffer.toString("base64")}`,
                targetW: size.w,
                targetH: size.h,
              }
            );
            writeFileSync(filepath, Buffer.from(resized, "base64"));
          } else {
            writeFileSync(filepath, screenshotBuffer);
          }

          console.log(`  ✓ Slide ${i + 1} → ${filename}`);
          await page.close();
        }
      }
    }
  }

  await browser.close();

  const total = activeDevices.reduce((sum, d) => sum + d.sizes.length * SLIDE_COUNT * LOCALES.length, 0);
  console.log(`\nDone! ${total} screenshots saved to ${OUTPUT_DIR}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
