import 'package:flutter/material.dart';

/// Central design tokens for Mirror Runners.
///
/// The game renders its own widgets (no global [ThemeData]), so this is a flat
/// set of constants rather than a Material theme. Every value here is the exact
/// literal that was previously duplicated across the UI — swapping a literal for
/// the matching token is a behaviour-preserving change.
class MR {
  MR._();

  // ── Brand colors ──
  /// Primary accent (violet). Was `0xFFB48CFF`.
  static const Color accent = Color(0xFFB48CFF);

  /// Reward / premium gold. Was `0xFFFFD700`.
  static const Color gold = Color(0xFFFFD700);

  /// Secondary highlight (cyan). Was `0xFF44DDFF`.
  static const Color cyan = Color(0xFF44DDFF);

  /// Warning / energetic orange. Was `0xFFFF6B35`.
  static const Color danger = Color(0xFFFF6B35);

  /// Error / alert red. Was `0xFFFF4444`.
  static const Color alert = Color(0xFFFF4444);

  // ── Background gradient (dark violet) ──
  /// Top gradient stop. Was `0xF00A0A0F`.
  static const Color bgTop = Color(0xF00A0A0F);

  /// Middle gradient stop. Was `0xF0080812`.
  static const Color bgMid = Color(0xF0080812);

  /// Bottom gradient stop. Was `0xF00F0A14`.
  static const Color bgBottom = Color(0xF00F0A14);

  /// The shared full-screen background gradient.
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
  );

  // ── Spacing scale ──
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  /// Minimum touch-target edge (Apple HIG / WCAG 2.5.5).
  static const double minTouchTarget = 44;
}
