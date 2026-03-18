"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import { toPng } from "html-to-image";

// === CONSTANTS ===
const W = 1320;
const H = 2868;

const IPAD_W = 2064;
const IPAD_H = 2752;

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

// Mockup measurements
const MK_W = 1022, MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

// === LOCALES ===
const LOCALES = ["en", "de"] as const;
type Locale = (typeof LOCALES)[number];

const COPY: Record<Locale, { slides: { label: string; headline: string }[] }> = {
  en: {
    slides: [
      { label: "Split-Screen Runner", headline: "One move.\nTwo runners." },
      { label: "11 Worlds to Explore", headline: "Run further.\nDiscover more." },
      { label: "Phantom Event", headline: "Stay alert.\nThey vanish." },
      { label: "Mirror Swap", headline: "Expect chaos.\nControls flip." },
      { label: "Unlock Skins", headline: "Earn them\nby playing." },
      { label: "Skin Creator", headline: "Be unique.\nBuild yours." },
    ],
  },
  de: {
    slides: [
      { label: "Splitscreen Runner", headline: "Eine Bewegung.\nZwei Runner." },
      { label: "11 Welten entdecken", headline: "Lauf weiter.\nEntdecke mehr." },
      { label: "Phantom Event", headline: "Bleib wachsam.\nSie verschwinden." },
      { label: "Spiegel-Tausch", headline: "Erwarte Chaos.\nSteuerung flippt." },
      { label: "Skins freispielen", headline: "Erspiele sie\ndurch Spielen." },
      { label: "Skin Creator", headline: "Sei einzigartig.\nBaue deinen." },
    ],
  },
};

const THEME = {
  fg: "#F0F0F8",
  accent1: "#B48CFF",
  accent2: "#50C8FF",
  muted: "#7A7A9A",
  gradients: [
    "linear-gradient(170deg, #08080F 0%, #120A24 45%, #0A0E1A 100%)",
    "linear-gradient(170deg, #08080F 0%, #0A1A1A 50%, #081018 100%)",
    "linear-gradient(170deg, #08080F 0%, #1A0A20 50%, #140820 100%)",
    "linear-gradient(170deg, #08080F 0%, #1A0A08 50%, #201008 100%)",
    "linear-gradient(170deg, #08080F 0%, #180C10 50%, #120A14 100%)",
    "linear-gradient(170deg, #08080F 0%, #081A18 50%, #0A0820 100%)",
  ],
};

const SHOTS = ["01_menu.png", "02_gameplay.png", "03_phantom.png", "04_swap.png", "05_skins.png", "06_creator.png"];

// === COMPONENTS ===

function Phone({ src, alt, style, className = "" }: { src: string; alt: string; style?: React.CSSProperties; className?: string }) {
  return (
    <div className={`relative ${className}`} style={{ aspectRatio: `${MK_W}/${MK_H}`, ...style }}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/mockup.png" alt="" className="block w-full h-full" draggable={false} />
      <div className="absolute z-10 overflow-hidden" style={{ left: `${SC_L}%`, top: `${SC_T}%`, width: `${SC_W}%`, height: `${SC_H}%`, borderRadius: `${SC_RX}% / ${SC_RY}%` }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={src} alt={alt} className="block w-full h-full object-cover object-top" draggable={false} />
      </div>
    </div>
  );
}

function Caption({ label, headline, canvasW, align = "center", accentColor = THEME.accent1 }: {
  label: string; headline: string; canvasW: number; align?: "center" | "left"; accentColor?: string;
}) {
  return (
    <div style={{ textAlign: align, fontFamily: "var(--font-inter)" }}>
      <div style={{ fontSize: canvasW * 0.028, fontWeight: 600, color: accentColor, letterSpacing: "0.12em", textTransform: "uppercase", marginBottom: canvasW * 0.016 }}>
        {label}
      </div>
      <div style={{ fontSize: canvasW * 0.09, fontWeight: 700, color: THEME.fg, lineHeight: 1.05, whiteSpace: "pre-line" }}>
        {headline}
      </div>
    </div>
  );
}

function Glow({ top, left, color = THEME.accent1, size = "60%", opacity = "15" }: {
  top: string; left: string; color?: string; size?: string; opacity?: string;
}) {
  return (
    <div style={{ position: "absolute", top, left, transform: "translate(-50%,-50%)", width: size, height: size, background: `radial-gradient(ellipse, ${color}${opacity} 0%, transparent 70%)`, pointerEvents: "none" }} />
  );
}

// === IPHONE SLIDES ===

function Slide1({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[0];
  return (
    <div style={{ width: W, height: H, background: THEME.gradients[0], position: "relative", overflow: "hidden" }}>
      <Glow top="40%" left="30%" color={THEME.accent1} size="80%" opacity="18" />
      <Glow top="50%" left="70%" color={THEME.accent2} size="60%" opacity="12" />
      <div style={{ position: "absolute", top: "4%", left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: W * 0.025, zIndex: 5 }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/app-icon.png" alt="Icon" style={{ width: W * 0.14, height: W * 0.14, borderRadius: W * 0.03 }} draggable={false} />
        <Caption label={c.label} headline={c.headline} canvasW={W} accentColor={THEME.accent1} />
      </div>
      <Phone src={`/screenshots/${SHOTS[0]}`} alt="Menu" style={{ position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%) translateY(16%)", width: "78%" }} />
    </div>
  );
}

function Slide2({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[1];
  return (
    <div style={{ width: W, height: H, background: THEME.gradients[1], position: "relative", overflow: "hidden" }}>
      <Glow top="55%" left="65%" color={THEME.accent2} size="80%" opacity="18" />
      <Glow top="30%" left="20%" color="#00DCA0" size="50%" opacity="10" />
      <div style={{ position: "absolute", top: "6%", left: "7%", zIndex: 5, width: "86%" }}>
        <Caption label={c.label} headline={c.headline} canvasW={W} align="left" accentColor={THEME.accent2} />
      </div>
      <Phone src={`/screenshots/${SHOTS[1]}`} alt="Gameplay" style={{ position: "absolute", bottom: 0, right: "-3%", transform: "translateY(14%)", width: "80%" }} />
    </div>
  );
}

function Slide3({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[2];
  return (
    <div style={{ width: W, height: H, background: THEME.gradients[2], position: "relative", overflow: "hidden" }}>
      <Glow top="50%" left="50%" color="#B44CFF" size="90%" opacity="16" />
      <Glow top="35%" left="60%" color="#FF50B4" size="50%" opacity="10" />
      <div style={{ position: "absolute", top: "5%", left: "50%", transform: "translateX(-50%)", zIndex: 5 }}>
        <Caption label={c.label} headline={c.headline} canvasW={W} accentColor="#D880FF" />
      </div>
      <Phone src={`/screenshots/${SHOTS[2]}`} alt="Phantom" style={{ position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%) translateY(14%)", width: "80%" }} />
    </div>
  );
}

function Slide4({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[3];
  return (
    <div style={{ width: W, height: H, background: THEME.gradients[3], position: "relative", overflow: "hidden" }}>
      <Glow top="55%" left="40%" color="#FF6444" size="80%" opacity="18" />
      <Glow top="40%" left="70%" color="#FFB428" size="60%" opacity="12" />
      <div style={{ position: "absolute", top: "5%", left: "50%", transform: "translateX(-50%)", zIndex: 5 }}>
        <Caption label={c.label} headline={c.headline} canvasW={W} accentColor="#FF8844" />
      </div>
      <Phone src={`/screenshots/${SHOTS[3]}`} alt="Swap" style={{ position: "absolute", bottom: 0, left: "-2%", transform: "translateY(14%)", width: "80%" }} />
    </div>
  );
}

function Slide5({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[4];
  return (
    <div style={{ width: W, height: H, background: THEME.gradients[4], position: "relative", overflow: "hidden" }}>
      <Glow top="45%" left="55%" color="#FF8C50" size="70%" opacity="14" />
      <Glow top="60%" left="30%" color="#FF508C" size="60%" opacity="10" />
      <div style={{ position: "absolute", top: "6%", left: "7%", zIndex: 5, width: "86%" }}>
        <Caption label={c.label} headline={c.headline} canvasW={W} align="left" accentColor="#FF9060" />
      </div>
      <Phone src={`/screenshots/${SHOTS[4]}`} alt="Skins" style={{ position: "absolute", bottom: 0, right: "-2%", transform: "translateY(16%)", width: "78%" }} />
    </div>
  );
}

function Slide6({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[5];
  return (
    <div style={{ width: W, height: H, background: THEME.gradients[5], position: "relative", overflow: "hidden" }}>
      <Glow top="45%" left="40%" color="#00DCA0" size="70%" opacity="14" />
      <Glow top="50%" left="65%" color={THEME.accent1} size="60%" opacity="12" />
      <div style={{ position: "absolute", top: "5%", left: "50%", transform: "translateX(-50%)", zIndex: 5 }}>
        <Caption label={c.label} headline={c.headline} canvasW={W} accentColor="#00DCA0" />
      </div>
      <Phone src={`/screenshots/${SHOTS[5]}`} alt="Creator" style={{ position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%) translateY(14%)", width: "80%" }} />
    </div>
  );
}

// === IPAD SLIDES ===

function IPadSlide1({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[0];
  return (
    <div style={{ width: IPAD_W, height: IPAD_H, background: THEME.gradients[0], position: "relative", overflow: "hidden" }}>
      <Glow top="40%" left="30%" color={THEME.accent1} size="80%" opacity="18" />
      <Glow top="50%" left="70%" color={THEME.accent2} size="60%" opacity="12" />
      <div style={{ position: "absolute", top: "3%", left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: IPAD_W * 0.02, zIndex: 5 }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/app-icon.png" alt="Icon" style={{ width: IPAD_W * 0.09, height: IPAD_W * 0.09, borderRadius: IPAD_W * 0.02 }} draggable={false} />
        <Caption label={c.label} headline={c.headline} canvasW={IPAD_W} accentColor={THEME.accent1} />
      </div>
      <Phone src={`/screenshots/${SHOTS[0]}`} alt="Menu" style={{ position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%) translateY(12%)", width: "50%" }} />
    </div>
  );
}

function IPadSlide2({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[1];
  return (
    <div style={{ width: IPAD_W, height: IPAD_H, background: THEME.gradients[1], position: "relative", overflow: "hidden" }}>
      <Glow top="55%" left="65%" color={THEME.accent2} size="80%" opacity="18" />
      <div style={{ position: "absolute", top: "5%", left: "6%", zIndex: 5, width: "50%" }}>
        <Caption label={c.label} headline={c.headline} canvasW={IPAD_W} align="left" accentColor={THEME.accent2} />
      </div>
      <Phone src={`/screenshots/${SHOTS[1]}`} alt="Gameplay" style={{ position: "absolute", bottom: 0, right: "5%", transform: "translateY(10%)", width: "50%" }} />
    </div>
  );
}

function IPadSlide3({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[2];
  return (
    <div style={{ width: IPAD_W, height: IPAD_H, background: THEME.gradients[2], position: "relative", overflow: "hidden" }}>
      <Glow top="50%" left="50%" color="#B44CFF" size="90%" opacity="16" />
      <div style={{ position: "absolute", top: "4%", left: "50%", transform: "translateX(-50%)", zIndex: 5 }}>
        <Caption label={c.label} headline={c.headline} canvasW={IPAD_W} accentColor="#D880FF" />
      </div>
      <Phone src={`/screenshots/${SHOTS[2]}`} alt="Phantom" style={{ position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%) translateY(10%)", width: "52%" }} />
    </div>
  );
}

function IPadSlide4({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[3];
  return (
    <div style={{ width: IPAD_W, height: IPAD_H, background: THEME.gradients[3], position: "relative", overflow: "hidden" }}>
      <Glow top="55%" left="40%" color="#FF6444" size="80%" opacity="18" />
      <div style={{ position: "absolute", top: "4%", left: "50%", transform: "translateX(-50%)", zIndex: 5 }}>
        <Caption label={c.label} headline={c.headline} canvasW={IPAD_W} accentColor="#FF8844" />
      </div>
      <Phone src={`/screenshots/${SHOTS[3]}`} alt="Swap" style={{ position: "absolute", bottom: 0, left: "5%", transform: "translateY(10%)", width: "52%" }} />
    </div>
  );
}

function IPadSlide5({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[4];
  return (
    <div style={{ width: IPAD_W, height: IPAD_H, background: THEME.gradients[4], position: "relative", overflow: "hidden" }}>
      <Glow top="45%" left="55%" color="#FF8C50" size="70%" opacity="14" />
      <div style={{ position: "absolute", top: "5%", left: "6%", zIndex: 5, width: "50%" }}>
        <Caption label={c.label} headline={c.headline} canvasW={IPAD_W} align="left" accentColor="#FF9060" />
      </div>
      <Phone src={`/screenshots/${SHOTS[4]}`} alt="Skins" style={{ position: "absolute", bottom: 0, right: "5%", transform: "translateY(10%)", width: "50%" }} />
    </div>
  );
}

function IPadSlide6({ locale }: { locale: Locale }) {
  const c = COPY[locale].slides[5];
  return (
    <div style={{ width: IPAD_W, height: IPAD_H, background: THEME.gradients[5], position: "relative", overflow: "hidden" }}>
      <Glow top="45%" left="40%" color="#00DCA0" size="70%" opacity="14" />
      <Glow top="50%" left="65%" color={THEME.accent1} size="60%" opacity="12" />
      <div style={{ position: "absolute", top: "4%", left: "50%", transform: "translateX(-50%)", zIndex: 5 }}>
        <Caption label={c.label} headline={c.headline} canvasW={IPAD_W} accentColor="#00DCA0" />
      </div>
      <Phone src={`/screenshots/${SHOTS[5]}`} alt="Creator" style={{ position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%) translateY(10%)", width: "52%" }} />
    </div>
  );
}

// === REGISTRIES ===
const IPHONE_SLIDES = [Slide1, Slide2, Slide3, Slide4, Slide5, Slide6];
const IPAD_SLIDES = [IPadSlide1, IPadSlide2, IPadSlide3, IPadSlide4, IPadSlide5, IPadSlide6];

// === PREVIEW ===
function ScreenshotPreview({ index, locale, device, onExport }: { index: number; locale: Locale; device: Device; onExport: (i: number) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.2);
  const slides = device === "ipad" ? IPAD_SLIDES : IPHONE_SLIDES;
  const cw = device === "ipad" ? IPAD_W : W;
  const ch = device === "ipad" ? IPAD_H : H;

  useEffect(() => {
    if (!ref.current) return;
    const parent = ref.current.parentElement;
    if (!parent) return;
    const ro = new ResizeObserver(() => setScale(parent.clientWidth / cw));
    ro.observe(parent);
    return () => ro.disconnect();
  }, [cw]);

  const Slide = slides[index];
  return (
    <div className="relative group cursor-pointer overflow-hidden rounded-xl" style={{ aspectRatio: `${cw}/${ch}` }} onClick={() => onExport(index)}>
      <div ref={ref} style={{ transform: `scale(${scale})`, transformOrigin: "top left" }}>
        <Slide locale={locale} />
      </div>
      <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center rounded-xl">
        <span className="text-white font-semibold text-sm">Export</span>
      </div>
    </div>
  );
}

// === HEADLESS SINGLE-SLIDE RENDER ===
function SingleSlide({ index, locale, device }: { index: number; locale: Locale; device: Device }) {
  const slides = device === "ipad" ? IPAD_SLIDES : IPHONE_SLIDES;
  const cw = device === "ipad" ? IPAD_W : W;
  const ch = device === "ipad" ? IPAD_H : H;
  const Slide = slides[index];
  if (!Slide) return null;
  return (
    <div id="capture" style={{ width: cw, height: ch, background: "#08080F", overflow: "hidden" }}>
      <Slide locale={locale} />
    </div>
  );
}

// === PAGE ===
export default function ScreenshotsPage() {
  const [locale, setLocale] = useState<Locale>("en");
  const [device, setDevice] = useState<Device>("iphone");
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exporting, setExporting] = useState(false);
  const [headlessSlide, setHeadlessSlide] = useState<number | null>(null);
  const [headlessLocale, setHeadlessLocale] = useState<Locale>("en");
  const [headlessDevice, setHeadlessDevice] = useState<Device>("iphone");

  const activeSlides = device === "ipad" ? IPAD_SLIDES : IPHONE_SLIDES;
  const activeSizes = device === "ipad" ? IPAD_SIZES : IPHONE_SIZES;
  const canvasW = device === "ipad" ? IPAD_W : W;
  const canvasH = device === "ipad" ? IPAD_H : H;

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const s = params.get("slide");
    const l = params.get("locale") as Locale | null;
    const d = params.get("device") as Device | null;
    if (s !== null) {
      setHeadlessSlide(parseInt(s, 10));
      if (l && LOCALES.includes(l)) setHeadlessLocale(l);
      if (d === "ipad") setHeadlessDevice("ipad");
    }
  }, []);

  useEffect(() => { setSizeIdx(0); }, [device]);

  const exportSlide = useCallback(async (index: number) => {
    if (exporting) return;
    setExporting(true);
    const size = activeSizes[sizeIdx];
    const Slide = activeSlides[index];

    const el = document.createElement("div");
    el.style.cssText = `position:absolute;left:-9999px;width:${canvasW}px;height:${canvasH}px;font-family:var(--font-inter);background:#08080F;overflow:hidden`;
    document.body.appendChild(el);

    const { createRoot } = await import("react-dom/client");
    const root = createRoot(el);
    root.render(<Slide locale={locale} />);
    await new Promise(r => setTimeout(r, 600));

    el.style.left = "0px";
    el.style.zIndex = "-1";

    try {
      const opts = { width: canvasW, height: canvasH, pixelRatio: 1, cacheBust: true };
      await toPng(el, opts);
      const url = await toPng(el, opts);

      if (size.w !== canvasW || size.h !== canvasH) {
        const img = new Image(); img.src = url;
        await new Promise(r => (img.onload = r));
        const c = document.createElement("canvas");
        c.width = size.w; c.height = size.h;
        c.getContext("2d")!.drawImage(img, 0, 0, size.w, size.h);
        dl(c.toDataURL("image/png"), index, size);
      } else {
        dl(url, index, size);
      }
    } finally {
      root.unmount();
      document.body.removeChild(el);
      setExporting(false);
    }
  }, [locale, sizeIdx, exporting, activeSlides, activeSizes, canvasW, canvasH]);

  const exportAll = useCallback(async () => {
    for (let i = 0; i < activeSlides.length; i++) {
      await exportSlide(i);
      await new Promise(r => setTimeout(r, 300));
    }
  }, [exportSlide, activeSlides]);

  if (headlessSlide !== null) {
    return <SingleSlide index={headlessSlide} locale={headlessLocale} device={headlessDevice} />;
  }

  return (
    <div className="min-h-screen bg-neutral-950 text-white p-8">
      <div className="flex items-center gap-4 mb-8 flex-wrap">
        <h1 className="text-xl font-bold mr-4">Mirror Runners Screenshots</h1>
        <div className="flex gap-1 bg-neutral-800 rounded-lg p-1">
          {(["iphone", "ipad"] as const).map(d => (
            <button key={d} onClick={() => setDevice(d)} className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${device === d ? "bg-neutral-600 text-white" : "text-neutral-400 hover:text-white"}`}>
              {d === "iphone" ? "iPhone" : "iPad"}
            </button>
          ))}
        </div>
        <div className="flex gap-1 bg-neutral-800 rounded-lg p-1">
          {LOCALES.map(l => (
            <button key={l} onClick={() => setLocale(l)} className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${locale === l ? "bg-neutral-600 text-white" : "text-neutral-400 hover:text-white"}`}>
              {l.toUpperCase()}
            </button>
          ))}
        </div>
        <select value={sizeIdx} onChange={e => setSizeIdx(+e.target.value)} className="bg-neutral-800 text-white px-3 py-1.5 rounded-lg text-sm">
          {activeSizes.map((s, i) => <option key={i} value={i}>{device === "ipad" ? "iPad" : "iPhone"} {s.label} ({s.w}x{s.h})</option>)}
        </select>
        <button onClick={exportAll} disabled={exporting} className="bg-purple-600 hover:bg-purple-500 disabled:opacity-50 px-4 py-1.5 rounded-lg text-sm font-medium">
          {exporting ? "Exporting..." : "Export All"}
        </button>
      </div>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {activeSlides.map((_, i) => <ScreenshotPreview key={`${device}-${i}-${locale}`} index={i} locale={locale} device={device} onExport={exportSlide} />)}
      </div>
    </div>
  );
}

function dl(url: string, i: number, s: { w: number; h: number }) {
  const a = document.createElement("a");
  a.href = url;
  a.download = `${String(i + 1).padStart(2, "0")}-mirror-runners-${s.w}x${s.h}.png`;
  a.click();
}
