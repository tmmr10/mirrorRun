import {
  AbsoluteFill,
  Img,
  OffthreadVideo,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
  staticFile,
} from "remotion";

// Apple App Preview Video Spec (akzeptierte iPhone-Hochformat-Groesse): 886 x 1920
export const FPS = 30;
export const WIDTH = 886;
export const HEIGHT = 1920;
export const DURATION_FRAMES = 840; // 28 s @ 30fps

const FONT_HEAD = `"Inter", -apple-system, system-ui, sans-serif`;

// Branding
const ACCENT = "#B48CFF"; // Akzent-Lila
const GOLD = "#FFC23E"; // Sterne
const WHITE = "#FFFFFF";

// Quelle ist 60fps -> startFrom in Quell-Frames. Ab Sekunde 40.
const VIDEO_START_FROM = Math.round(40 * 60); // 2400

// Intro-Overlay-Fenster (Frames)
const INTRO_IN_START = 0;
const INTRO_IN_END = 12; // 0.4s Einblendung
const INTRO_HOLD_END = 68; // halten
const INTRO_OUT_END = 80; // ~2.7s ausgeblendet

// Outro-Overlay-Fenster (Frames)
const OUTRO_START = 750; // letzte ~3s
const OUTRO_IN_END = 780; // 1s sanftes Einblenden

// Event-Caption-Fenster (Frames). Timings beziehen sich auf den fertigen Clip.
const CAP_FADE = 11; // ~0.35s Ein-/Ausblendung @ 30fps
const BLACKOUT_FROM = 90; // ~3.0s
const BLACKOUT_TO = 174; // ~5.8s
const SYNCLOCK_FROM = 390; // ~13.0s
const SYNCLOCK_TO = 474; // ~15.8s
const COINS_FROM = 600; // ~20.0s
const COINS_TO = 684; // ~22.8s

type EventCaptionProps = {
  fromFrame: number;
  toFrame: number;
  accent: string;
  title: string;
  desc: string;
  icon: React.ReactNode;
};

const EventCaption: React.FC<EventCaptionProps> = ({
  fromFrame,
  toFrame,
  accent,
  title,
  desc,
  icon,
}) => {
  const frame = useCurrentFrame();
  if (frame < fromFrame || frame > toFrame) return null;

  // opacity 0 -> 1 (Einblenden) -> halten -> 0 (Ausblenden am Fensterende)
  const opacity = interpolate(
    frame,
    [fromFrame, fromFrame + CAP_FADE, toFrame - CAP_FADE, toFrame],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const rise = interpolate(opacity, [0, 1], [20, 0]); // 20px Y-Slide nach oben

  return (
    <>
      {/* Abdunkel-Verlauf oben fuer Lesbarkeit (gleicher Look wie Intro-Overlay) */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: HEIGHT * 0.32,
          opacity,
          background:
            "linear-gradient(180deg, rgba(4,4,10,0.7) 0%, rgba(4,4,10,0.45) 45%, rgba(4,4,10,0) 100%)",
          zIndex: 24,
          pointerEvents: "none",
        }}
      />
      <div
        style={{
          position: "absolute",
          top: HEIGHT * 0.12,
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "center",
          opacity,
          transform: `translateY(${rise}px)`,
          fontFamily: FONT_HEAD,
          zIndex: 25,
          pointerEvents: "none",
        }}
      >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 26,
          width: WIDTH * 0.86,
          maxWidth: WIDTH * 0.86,
        }}
      >
        <div
          style={{
            flex: "0 0 auto",
            width: 78,
            height: 78,
            borderRadius: "50%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            border: `3.5px solid ${accent}`,
            boxShadow: `0 0 28px ${accent}cc`,
          }}
        >
          {icon}
        </div>
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div
            style={{
              fontSize: 52,
              fontWeight: 800,
              color: WHITE,
              letterSpacing: "0.04em",
              lineHeight: 1.04,
              textShadow: "0 2px 12px rgba(0,0,0,0.8)",
            }}
          >
            {title}
          </div>
          <div
            style={{
              marginTop: 8,
              fontSize: 30,
              fontWeight: 500,
              color: "#cfd2e6",
              lineHeight: 1.15,
              textShadow: "0 2px 12px rgba(0,0,0,0.8)",
            }}
          >
            {desc}
          </div>
        </div>
      </div>
      </div>
    </>
  );
};

// Akzentfarben Event-Captions
const BLACKOUT_ACCENT = "#8FA3B8"; // Grau-Blau
const SYNCLOCK_ACCENT = "#B48CFF"; // Lila
const COINS_ACCENT = "#FFC23E"; // Gold

// ---- Lokalisierte Overlay-Texte ----
export type Locale = "en" | "de";

type Copy = {
  introEyebrow: string;
  introHeadline: string; // mit \n
  blackoutTitle: string;
  blackoutDesc: string;
  synclockTitle: string;
  synclockDesc: string;
  coinsTitle: string;
  coinsDesc: string;
  outroCta: string;
};

const COPY: Record<Locale, Copy> = {
  en: {
    introEyebrow: "MIRROR RUNNERS",
    introHeadline: "One move.\nTwo runners.",
    blackoutTitle: "BLACKOUT",
    blackoutDesc: "One side goes dark",
    synclockTitle: "SYNC-LOCK",
    synclockDesc: "Both runners move together",
    coinsTitle: "COINS",
    coinsDesc: "Collect & unlock skins",
    outroCta: "Get it free",
  },
  de: {
    introEyebrow: "MIRROR RUNNERS",
    introHeadline: "Eine Bewegung.\nZwei Runner.",
    blackoutTitle: "BLACKOUT",
    blackoutDesc: "Eine Seite wird dunkel",
    synclockTitle: "SYNC-LOCK",
    synclockDesc: "Beide Runner laufen gleich",
    coinsTitle: "COINS",
    coinsDesc: "Sammeln & Skins kaufen",
    outroCta: "Jetzt gratis holen.",
  },
};

type MirrorRunnersPreviewProps = {
  locale?: Locale;
};

export const MirrorRunnersPreview: React.FC<MirrorRunnersPreviewProps> = ({
  locale = "en",
}) => {
  const t = COPY[locale];
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ---- Intro opacity (0 -> 1 -> halten -> 0) ----
  const introOpacity = interpolate(
    frame,
    [INTRO_IN_START, INTRO_IN_END, INTRO_HOLD_END, INTRO_OUT_END],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const introRise = interpolate(introOpacity, [0, 1], [18, 0]);

  // ---- Outro overlay ----
  const outroT = interpolate(
    frame,
    [OUTRO_START, OUTRO_IN_END],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const outroDim = outroT * 0.9; // schwarzer Layer bis 0.9
  const outroContentRise = interpolate(outroT, [0, 1], [22, 0]);

  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {/* Gameplay-Video full-bleed, randlos */}
      <OffthreadVideo
        src={staticFile("gameplay.mov")}
        startFrom={VIDEO_START_FROM}
        muted
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          objectFit: "cover",
        }}
      />

      {/* Spiegel-Mittellinie ueber das ganze Video (dezentes Lila-Glow) */}
      <div
        style={{
          position: "absolute",
          top: 0,
          bottom: 0,
          left: WIDTH / 2 - 1,
          width: 2,
          background:
            "linear-gradient(180deg, rgba(180,140,255,0) 0%, rgba(180,140,255,0.45) 18%, rgba(180,140,255,0.55) 50%, rgba(180,140,255,0.45) 82%, rgba(180,140,255,0) 100%)",
          boxShadow: "0 0 14px rgba(180,140,255,0.6)",
          zIndex: 5,
          pointerEvents: "none",
        }}
      />

      {/* ===== EVENT-CAPTIONS ===== */}
      <EventCaption
        fromFrame={BLACKOUT_FROM}
        toFrame={BLACKOUT_TO}
        accent={BLACKOUT_ACCENT}
        title={t.blackoutTitle}
        desc={t.blackoutDesc}
        icon={
          <svg width={40} height={40} viewBox="0 0 26 26">
            <circle
              cx={13}
              cy={13}
              r={10}
              fill="none"
              stroke={BLACKOUT_ACCENT}
              strokeWidth={2}
            />
            <path
              d="M13 3 A10 10 0 0 0 13 23 Z"
              fill={BLACKOUT_ACCENT}
            />
          </svg>
        }
      />
      <EventCaption
        fromFrame={SYNCLOCK_FROM}
        toFrame={SYNCLOCK_TO}
        accent={SYNCLOCK_ACCENT}
        title={t.synclockTitle}
        desc={t.synclockDesc}
        icon={
          <svg width={40} height={40} viewBox="0 0 26 26">
            <path
              d="M9 4 L9 22 M9 4 L5.5 7.5 M9 4 L12.5 7.5"
              fill="none"
              stroke={SYNCLOCK_ACCENT}
              strokeWidth={2}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M17 4 L17 22 M17 4 L13.5 7.5 M17 4 L20.5 7.5"
              fill="none"
              stroke={SYNCLOCK_ACCENT}
              strokeWidth={2}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        }
      />
      <EventCaption
        fromFrame={COINS_FROM}
        toFrame={COINS_TO}
        accent={COINS_ACCENT}
        title={t.coinsTitle}
        desc={t.coinsDesc}
        icon={
          <svg width={40} height={40} viewBox="0 0 26 26">
            <circle
              cx={13}
              cy={13}
              r={10}
              fill="none"
              stroke={COINS_ACCENT}
              strokeWidth={2}
            />
            <circle
              cx={13}
              cy={13}
              r={4.5}
              fill="none"
              stroke={COINS_ACCENT}
              strokeWidth={2}
            />
          </svg>
        }
      />

      {/* ===== INTRO-OVERLAY ===== */}
      {introOpacity > 0.001 && (
        <>
          {/* Abdunkel-Verlauf oben fuer Lesbarkeit */}
          <div
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              right: 0,
              height: HEIGHT * 0.5,
              opacity: introOpacity,
              background:
                "linear-gradient(180deg, rgba(6,4,12,0.92) 0%, rgba(6,4,12,0.72) 45%, rgba(6,4,12,0) 100%)",
              zIndex: 10,
              pointerEvents: "none",
            }}
          />
          <div
            style={{
              position: "absolute",
              top: HEIGHT * 0.08,
              left: WIDTH * 0.07,
              right: WIDTH * 0.07,
              opacity: introOpacity,
              transform: `translateY(${introRise}px)`,
              fontFamily: FONT_HEAD,
              textAlign: "center",
              zIndex: 20,
            }}
          >
            <div
              style={{
                fontSize: 26,
                fontWeight: 700,
                color: ACCENT,
                letterSpacing: "0.2em",
                textTransform: "uppercase",
                marginBottom: 18,
                textShadow: "0 2px 18px rgba(0,0,0,0.7)",
              }}
            >
              {t.introEyebrow}
            </div>
            <div
              style={{
                fontSize: 64,
                fontWeight: 800,
                lineHeight: 1.02,
                color: WHITE,
                whiteSpace: "pre-line",
                letterSpacing: "-0.03em",
                textShadow: "0 4px 28px rgba(0,0,0,0.85)",
              }}
            >
              {t.introHeadline}
            </div>
          </div>
        </>
      )}

      {/* ===== OUTRO-OVERLAY ===== */}
      {outroT > 0.001 && (
        <>
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: "#050308",
              opacity: outroDim,
              zIndex: 30,
            }}
          />
          <div
            style={{
              position: "absolute",
              inset: 0,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              opacity: outroT,
              transform: `translateY(${outroContentRise}px)`,
              fontFamily: FONT_HEAD,
              textAlign: "center",
              zIndex: 40,
            }}
          >
            <Img
              src={staticFile("app-icon.png")}
              style={{
                width: 120,
                height: 120,
                borderRadius: 28,
                boxShadow:
                  "0 0 38px rgba(180,140,255,0.65), 0 8px 24px rgba(0,0,0,0.6)",
                marginBottom: 36,
              }}
            />
            <div
              style={{
                fontSize: 58,
                fontWeight: 800,
                lineHeight: 1.0,
                letterSpacing: "-0.02em",
              }}
            >
              <span style={{ color: WHITE }}>MIRROR</span>
              <br />
              <span style={{ color: ACCENT }}>RUNNERS</span>
            </div>
            <div
              style={{
                marginTop: 34,
                fontSize: 30,
                fontWeight: 700,
                color: WHITE,
              }}
            >
              {t.outroCta}
            </div>
            <div
              style={{
                marginTop: 14,
                fontSize: 32,
                color: GOLD,
                letterSpacing: "0.12em",
              }}
            >
              {"★★★★★"}
            </div>
          </div>
        </>
      )}
    </AbsoluteFill>
  );
};
