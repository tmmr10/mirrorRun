import { chromium } from "playwright";
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 1000, height: 800 }, deviceScaleFactor: 2 });
await p.goto("file:///tmp/mr_icons/" + process.argv[2], { waitUntil: "networkidle" });
await p.waitForTimeout(600);
await p.screenshot({ path: "/tmp/mr_icons/" + process.argv[3], fullPage: true });
await b.close();
console.log("shot done");
