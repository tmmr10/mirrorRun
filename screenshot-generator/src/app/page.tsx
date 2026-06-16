"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import { toPng } from "html-to-image";

// ============================================================================
// Mirror Runners — App Store Screenshot Generator (Direction 2026-06)
// Aligned to the StandBy Hub / IronRep house style:
//   Hero + one-benefit-per-feature slide + branded outro.
//   Real device frame · accent glow · eyebrow / headline / sub typography.
// Brand twist: a glowing vertical mirror line down the center on hero & outro.
//
// Screenshots are a single (locale-independent) set in /public/screenshots/.
// Headlines are bilingual (en/de). Design canvas = 1320×2868 (6.9").
// ============================================================================

const W = 1320, H = 2868;
const IPAD_W = 2064, IPAD_H = 2752;
type Device = "iphone" | "ipad";

const IPHONE_SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;
const IPAD_SIZES = [
  { label: '13" iPad', w: 2064, h: 2752 },
  { label: '12.9" iPad Pro', w: 2048, h: 2732 },
] as const;

// === REAL DEVICE FRAME (mockup.png pre-measured, % of frame) ===
const MK = { l: 5.09, t: 2.21, w: 89.82, h: 95.58, rx: 13.73, ry: 6.33 };

// === THEME (Mirror Runners brand) ===
const THEME = {
  fg: "#F1F1FA",
  purple: "#B48CFF",
  cyan: "#50C8FF",
  magenta: "#D880FF",
  orange: "#FF8C50",
  pink: "#FF8FB0",
  green: "#00DCA0",
  muted: "#8B8BAE",
  bg: "#08080F",
};

// === SHOTS — per-locale app screenshots: /public/screenshots/<locale>/<file> ===
// The in-app UI is localized, so each language uses its own captures.
const FILES: Record<string, string> = {
  menu: "01_menu.png",
  gameplay: "02_gameplay.png",
  phantom: "03_phantom.png",
  swap: "04_swap.png",
  skins: "05_skins.png",
  creator: "06_creator.png",
};
// Locale is threaded via renderSlide (keeps the Slide components clean).
let _shotLocale: Locale = "en";
const shot = (key: string) => `/screenshots/${_shotLocale}/${FILES[key]}`;

// === LOCALES + COPY ===
const LOCALES = ["en", "de"] as const;
type Locale = (typeof LOCALES)[number];
type Slide = { id: string; eyebrow: string; headline: string; sub: string };

const COPY: Record<Locale, Slide[]> = {
  en: [
    { id: "hero",     eyebrow: "MIRROR RUNNERS",  headline: "One move.\nTwo runners.", sub: "A split-screen reflex runner. |Steer both sides at once.|" },
    { id: "worlds",   eyebrow: "11 WORLDS",       headline: "Run further.\nSee more.",  sub: "Forest, crystal, volcano, space — |11 worlds| to chase." },
    { id: "phantom",  eyebrow: "PHANTOM EVENT",   headline: "They vanish.\nRemember.",  sub: "Obstacles turn invisible — |memorize| them before they fade." },
    { id: "swap",     eyebrow: "MIRROR SWAP",     headline: "Controls flip.\nStay sharp.", sub: "Left becomes right. |Rewire your reflexes| on the fly." },
    { id: "skins",    eyebrow: "UNLOCK SKINS",    headline: "Earn them\nby playing.",   sub: "Collect coins and |unlock new runners| as you go." },
    { id: "creator",  eyebrow: "SKIN CREATOR",    headline: "Make it\nyours.",          sub: "Design your own runner — |colors, helmets, faces|." },
    { id: "outro",    eyebrow: "MIRROR RUNNERS",  headline: "Get it free.",             sub: "One move. Two runners. |Endless mirror chaos.|" },
  ],
  de: [
    { id: "hero",     eyebrow: "MIRROR RUNNERS",  headline: "Eine Bewegung.\nZwei Runner.", sub: "Ein Splitscreen-Reflex-Runner. |Steuere beide Seiten zugleich.|" },
    { id: "worlds",   eyebrow: "11 WELTEN",       headline: "Lauf weiter.\nEntdecke mehr.", sub: "Wald, Kristall, Vulkan, All — |11 Welten| warten auf dich." },
    { id: "phantom",  eyebrow: "PHANTOM-EVENT",   headline: "Sie verschwinden.\nMerk sie dir.", sub: "Hindernisse werden unsichtbar — |einprägen|, bevor sie weg sind." },
    { id: "swap",     eyebrow: "SPIEGEL-TAUSCH",  headline: "Steuerung kippt.\nBleib wach.", sub: "Links wird rechts. |Verdrahte deine Reflexe| neu." },
    { id: "skins",    eyebrow: "SKINS FREISPIELEN", headline: "Erspiele sie\ndurch Spielen.", sub: "Sammle Coins und |schalte neue Runner frei|." },
    { id: "creator",  eyebrow: "SKIN CREATOR",    headline: "Mach ihn\neinzigartig.",   sub: "Gestalte deinen Runner — |Farben, Helme, Gesichter|." },
    { id: "outro",    eyebrow: "MIRROR RUNNERS",  headline: "Jetzt gratis holen.",      sub: "Eine Bewegung. Zwei Runner. |Endloses Spiegel-Chaos.|" },
  ],
};

const SLIDE_COUNT = 7;

// Per-slide accent + radial-glow background tint (index-aligned)
const ACCENTS = [THEME.purple, THEME.cyan, THEME.magenta, THEME.orange, THEME.pink, THEME.green, THEME.purple];
const GLOWS = ["#160C2A", "#08182A", "#1C0A28", "#241208", "#220C16", "#08221A", "#140A26"];

// ============================================================================
// PRIMITIVES
// ============================================================================
function hex(c: string, a: number) { return c + Math.round(a * 255).toString(16).padStart(2, "0"); }

// Sub text with |highlighted| spans → brighter weight.
function Sub({ text }: { text: string }) {
  const parts = text.split("|");
  return (
    <span>
      {parts.map((p, i) =>
        i % 2 === 1
          ? <b key={i} style={{ color: "#FFFFFF", fontWeight: 700 }}>{p}</b>
          : <span key={i}>{p}</span>
      )}
    </span>
  );
}

// Faint glowing vertical mirror line down the center — the brand signature.
function MirrorLine({ accent }: { accent: string }) {
  return (
    <div style={{ position: "absolute", top: 0, bottom: 0, left: "50%", width: 2, transform: "translateX(-50%)", zIndex: 1, pointerEvents: "none",
      background: `linear-gradient(180deg, transparent, ${hex(accent, 0.55)} 25%, ${hex(accent, 0.55)} 75%, transparent)`,
      boxShadow: `0 0 24px ${hex(accent, 0.45)}` }} />
  );
}

// Real portrait iPhone: mockup frame behind, screenshot in the screen area on top.
function Phone({ src, glow, style }: { src: string; glow?: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: `${1022}/${2082}`,
      filter: `drop-shadow(0 30px 60px rgba(0,0,0,.7))${glow ? ` drop-shadow(0 0 60px ${hex(glow, 0.34)})` : ""}`, ...style }}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/mockup.png" alt="" style={{ position: "absolute", inset: 0, width: "100%", height: "100%", zIndex: 1 }} draggable={false} />
      <div style={{ position: "absolute", left: `${MK.l}%`, top: `${MK.t}%`, width: `${MK.w}%`, height: `${MK.h}%`, borderRadius: `${MK.rx}% / ${MK.ry}%`, overflow: "hidden", background: "#000", zIndex: 2 }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={src} alt="" style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} draggable={false} />
      </div>
    </div>
  );
}

function CaptionTop({ slide, cw, accent, k }: { slide: Slide; cw: number; accent: string; k: number }) {
  return (
    <div style={{ position: "absolute", top: "6.2%", left: "8%", right: "8%", textAlign: "center", zIndex: 5, fontFamily: "var(--font-inter)" }}>
      <div style={{ color: accent, fontWeight: 700, letterSpacing: "0.18em", textTransform: "uppercase", fontSize: cw * 0.030 * k, marginBottom: cw * 0.028 * k }}>{slide.eyebrow}</div>
      <div style={{ color: THEME.fg, fontWeight: 800, letterSpacing: "-0.03em", lineHeight: 1.04, whiteSpace: "pre-line", fontSize: cw * 0.082 * k, textShadow: "0 4px 30px rgba(0,0,0,.6)" }}>{slide.headline}</div>
      <div style={{ color: THEME.muted, fontSize: cw * 0.029 * k, lineHeight: 1.45, marginTop: cw * 0.030 * k, maxWidth: "88%", marginInline: "auto" }}>
        <Sub text={slide.sub} />
      </div>
    </div>
  );
}

// ============================================================================
// HERO — dark/neon backdrop, mirror line, device showing the menu
// ============================================================================
function HeroSlide({ cw, ch, slide }: { cw: number; ch: number; slide: Slide }) {
  const isIPad = cw > 1800; const k = isIPad ? 0.62 : 1;
  return (
    <div style={{ width: cw, height: ch, position: "relative", overflow: "hidden", fontFamily: "var(--font-inter)",
      background: `radial-gradient(125% 80% at 50% 16%, ${GLOWS[0]} 0%, #0A0A16 46%, #06060C)` }}>
      <div style={{ position: "absolute", left: "28%", top: "20%", width: "60%", height: "44%", background: `radial-gradient(ellipse, ${hex(THEME.purple, 0.20)}, transparent 70%)` }} />
      <div style={{ position: "absolute", left: "72%", top: "44%", width: "55%", height: "44%", background: `radial-gradient(ellipse, ${hex(THEME.cyan, 0.16)}, transparent 70%)` }} />
      <MirrorLine accent={THEME.purple} />
      <CaptionTop slide={slide} cw={cw} accent={THEME.purple} k={k} />
      <Phone src={shot("menu")} glow={THEME.purple}
        style={{ position: "absolute", top: isIPad ? "30%" : "33%", left: "50%", transform: "translateX(-50%)", width: isIPad ? "42%" : "62%", zIndex: 3 }} />
    </div>
  );
}

// ============================================================================
// FEATURE — one benefit, accent glow, full-visible device
// ============================================================================
function FeatureSlide({ cw, ch, slide, accent, glow, shotKey, side = "center" }: {
  cw: number; ch: number; slide: Slide; accent: string; glow: string; shotKey: string; side?: "center" | "left" | "right";
}) {
  const isIPad = cw > 1800; const k = isIPad ? 0.62 : 1;
  const left = side === "left" ? (isIPad ? "30%" : "24%") : side === "right" ? (isIPad ? "70%" : "76%") : "50%";
  return (
    <div style={{ width: cw, height: ch, position: "relative", overflow: "hidden", fontFamily: "var(--font-inter)",
      background: `radial-gradient(125% 75% at 50% 64%, ${glow} 0%, #0A0A16 52%, #06060C)` }}>
      <div style={{ position: "absolute", left: "50%", top: "64%", transform: "translate(-50%,-50%)", width: "120%", height: "56%", background: `radial-gradient(ellipse, ${hex(accent, 0.20)}, transparent 70%)`, pointerEvents: "none" }} />
      <CaptionTop slide={slide} cw={cw} accent={accent} k={k} />
      <Phone src={shot(shotKey)} glow={accent}
        style={{ position: "absolute", top: isIPad ? "31%" : "34%", left, transform: "translateX(-50%)", width: isIPad ? "42%" : "62%", zIndex: 4 }} />
    </div>
  );
}

// ============================================================================
// OUTRO — branding + CTA (icon, wordmark, mirror line, stars)
// ============================================================================
function OutroSlide({ cw, ch, slide }: { cw: number; ch: number; slide: Slide }) {
  const k = cw > 1800 ? 0.62 : 1;
  return (
    <div style={{ width: cw, height: ch, position: "relative", overflow: "hidden", fontFamily: "var(--font-inter)",
      background: `radial-gradient(120% 70% at 50% 42%, ${GLOWS[6]} 0%, #0A0A16 50%, #06060C)` }}>
      <div style={{ position: "absolute", left: "50%", top: "42%", transform: "translate(-50%,-50%)", width: "110%", height: "50%", background: `radial-gradient(ellipse, ${hex(THEME.purple, 0.18)}, transparent 70%)` }} />
      <MirrorLine accent={THEME.purple} />
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", padding: `0 ${cw * 0.09}px`, zIndex: 3 }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/app-icon.png" alt="" style={{ width: cw * 0.20 * k, height: cw * 0.20 * k, borderRadius: cw * 0.045 * k, boxShadow: `0 0 ${cw * 0.07}px ${hex(THEME.purple, 0.5)}`, marginBottom: cw * 0.055 }} draggable={false} />
        <div style={{ fontSize: cw * 0.11 * k, fontWeight: 900, letterSpacing: "0.04em", lineHeight: 1, color: THEME.fg }}>MIRROR</div>
        <div style={{ fontSize: cw * 0.11 * k, fontWeight: 900, letterSpacing: "0.04em", lineHeight: 1, color: THEME.purple, marginBottom: cw * 0.045 }}>RUNNERS</div>
        <div style={{ fontSize: cw * 0.062 * k, fontWeight: 800, letterSpacing: "-0.02em", color: THEME.fg }}>{slide.headline}</div>
        <div style={{ fontSize: cw * 0.030 * k, color: THEME.muted, marginTop: cw * 0.035, lineHeight: 1.5, maxWidth: "84%" }}>
          <Sub text={slide.sub} />
        </div>
        <div style={{ display: "flex", gap: cw * 0.012, marginTop: cw * 0.05 }}>
          {[1, 2, 3, 4, 5].map(i => <span key={i} style={{ color: "#FFC23E", fontSize: cw * 0.045 * k }}>★</span>)}
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// SLIDE REGISTRY
// ============================================================================
function renderSlide(index: number, cw: number, ch: number, locale: Locale) {
  _shotLocale = locale;
  const s = COPY[locale][index];
  switch (index) {
    case 0: return <HeroSlide cw={cw} ch={ch} slide={s} />;
    case 1: return <FeatureSlide cw={cw} ch={ch} slide={s} accent={ACCENTS[1]} glow={GLOWS[1]} shotKey="gameplay" />;
    case 2: return <FeatureSlide cw={cw} ch={ch} slide={s} accent={ACCENTS[2]} glow={GLOWS[2]} shotKey="phantom" />;
    case 3: return <FeatureSlide cw={cw} ch={ch} slide={s} accent={ACCENTS[3]} glow={GLOWS[3]} shotKey="swap" />;
    case 4: return <FeatureSlide cw={cw} ch={ch} slide={s} accent={ACCENTS[4]} glow={GLOWS[4]} shotKey="skins" />;
    case 5: return <FeatureSlide cw={cw} ch={ch} slide={s} accent={ACCENTS[5]} glow={GLOWS[5]} shotKey="creator" />;
    case 6: return <OutroSlide cw={cw} ch={ch} slide={s} />;
    default: return null;
  }
}

// ============================================================================
// PREVIEW CARD
// ============================================================================
function ScreenshotPreview({ index, locale, device, onExport }: { index: number; locale: Locale; device: Device; onExport: (i: number) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.2);
  const cw = device === "ipad" ? IPAD_W : W;
  const ch = device === "ipad" ? IPAD_H : H;
  useEffect(() => {
    if (!ref.current) return;
    const parent = ref.current.parentElement; if (!parent) return;
    const ro = new ResizeObserver(() => setScale(parent.clientWidth / cw));
    ro.observe(parent); return () => ro.disconnect();
  }, [cw]);
  return (
    <div className="flex flex-col gap-2">
      <div className="relative group cursor-pointer overflow-hidden rounded-xl border border-white/10 hover:border-[#B48CFF]/60 transition-colors" style={{ aspectRatio: `${cw}/${ch}` }} onClick={() => onExport(index)}>
        <div ref={ref} style={{ transform: `scale(${scale})`, transformOrigin: "top left" }}>
          {renderSlide(index, cw, ch, locale)}
        </div>
        <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center rounded-xl">
          <span className="text-white font-semibold text-sm">Export</span>
        </div>
      </div>
      <p className="text-xs text-white/40 text-center truncate">{COPY[locale][index].eyebrow}</p>
    </div>
  );
}

function SingleSlide({ index, locale, device }: { index: number; locale: Locale; device: Device }) {
  const cw = device === "ipad" ? IPAD_W : W;
  const ch = device === "ipad" ? IPAD_H : H;
  const node = renderSlide(index, cw, ch, locale);
  if (!node) return null;
  return <div id="capture" style={{ width: cw, height: ch, background: THEME.bg, overflow: "hidden" }}>{node}</div>;
}

// ============================================================================
// PAGE
// ============================================================================
export default function ScreenshotsPage() {
  const [locale, setLocale] = useState<Locale>("en");
  const [device, setDevice] = useState<Device>("iphone");
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exporting, setExporting] = useState(false);
  const [headless, setHeadless] = useState<{ slide: number; locale: Locale; device: Device } | null>(null);

  const activeSizes = device === "ipad" ? IPAD_SIZES : IPHONE_SIZES;
  const canvasW = device === "ipad" ? IPAD_W : W;
  const canvasH = device === "ipad" ? IPAD_H : H;

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const s = params.get("slide");
    if (s !== null) {
      const l = params.get("locale") as Locale | null;
      const d = params.get("device") as Device | null;
      setHeadless({ slide: parseInt(s, 10), locale: l && LOCALES.includes(l) ? l : "en", device: d === "ipad" ? "ipad" : "iphone" });
    }
  }, []);
  useEffect(() => { setSizeIdx(0); }, [device]);

  const exportSlide = useCallback(async (index: number) => {
    if (exporting) return;
    setExporting(true);
    const size = activeSizes[sizeIdx];
    const el = document.createElement("div");
    el.style.cssText = `position:absolute;left:-9999px;width:${canvasW}px;height:${canvasH}px;font-family:var(--font-inter);background:${THEME.bg};overflow:hidden`;
    document.body.appendChild(el);
    const { createRoot } = await import("react-dom/client");
    const root = createRoot(el);
    root.render(renderSlide(index, canvasW, canvasH, locale));
    await new Promise(r => setTimeout(r, 600));
    el.style.left = "0px"; el.style.zIndex = "-1";
    try {
      const opts = { width: canvasW, height: canvasH, pixelRatio: 1, cacheBust: true };
      await toPng(el, opts);
      const url = await toPng(el, opts);
      let finalUrl = url;
      if (size.w !== canvasW || size.h !== canvasH) {
        const img = new Image(); img.src = url; await new Promise(r => (img.onload = r));
        const c = document.createElement("canvas"); c.width = size.w; c.height = size.h;
        c.getContext("2d")!.drawImage(img, 0, 0, size.w, size.h);
        finalUrl = c.toDataURL("image/png");
      }
      const a = document.createElement("a"); a.href = finalUrl;
      a.download = `${String(index + 1).padStart(2, "0")}-${COPY[locale][index].id}-${locale}-${size.w}x${size.h}.png`;
      a.click();
    } finally {
      root.unmount(); document.body.removeChild(el); setExporting(false);
    }
  }, [locale, sizeIdx, exporting, activeSizes, canvasW, canvasH]);

  const exportAll = useCallback(async () => {
    for (let i = 0; i < SLIDE_COUNT; i++) { await exportSlide(i); await new Promise(r => setTimeout(r, 300)); }
  }, [exportSlide]);

  if (headless) return <SingleSlide index={headless.slide} locale={headless.locale} device={headless.device} />;

  return (
    <div className="min-h-screen bg-neutral-950 text-white p-8">
      <div className="flex items-center gap-4 mb-8 flex-wrap">
        <h1 className="text-xl font-bold mr-2">Mirror Runners Screenshots</h1>
        <div className="flex gap-1 bg-neutral-800 rounded-lg p-1">
          {(["iphone", "ipad"] as const).map(d => (
            <button key={d} onClick={() => setDevice(d)} className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${device === d ? "bg-[#B48CFF] text-black" : "text-neutral-400 hover:text-white"}`}>{d === "iphone" ? "iPhone" : "iPad"}</button>
          ))}
        </div>
        <div className="flex gap-1 bg-neutral-800 rounded-lg p-1">
          {LOCALES.map(l => (
            <button key={l} onClick={() => setLocale(l)} className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${locale === l ? "bg-[#B48CFF] text-black" : "text-neutral-400 hover:text-white"}`}>{l.toUpperCase()}</button>
          ))}
        </div>
        <select value={sizeIdx} onChange={e => setSizeIdx(+e.target.value)} className="bg-neutral-800 text-white px-3 py-1.5 rounded-lg text-sm">
          {activeSizes.map((s, i) => <option key={i} value={i}>{device === "ipad" ? "iPad" : "iPhone"} {s.label} ({s.w}×{s.h})</option>)}
        </select>
        <span className="text-neutral-500 text-xs">Click a slide to export</span>
        <button onClick={exportAll} disabled={exporting} className="ml-auto bg-[#B48CFF] text-black px-5 py-2 rounded-lg text-sm font-bold hover:bg-[#c5a3ff] disabled:opacity-40">{exporting ? "Exporting…" : "Export All"}</button>
      </div>
      <div className="grid gap-4 grid-cols-2 md:grid-cols-4 lg:grid-cols-7">
        {Array.from({ length: SLIDE_COUNT }, (_, i) => (
          <ScreenshotPreview key={`${device}-${i}-${locale}`} index={i} locale={locale} device={device} onExport={exportSlide} />
        ))}
      </div>
      <p className="text-white/20 text-xs mt-6">Exports at {activeSizes[sizeIdx].w}×{activeSizes[sizeIdx].h}px · canvas {canvasW}×{canvasH}.</p>
    </div>
  );
}
