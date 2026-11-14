import 'package:flutter/material.dart';

/// PAYDAY design tokens — the single source of truth for colours, corner
/// radii, spacing and type sizes. Screens should reference these instead of
/// writing hex values or magic numbers inline.
///
/// Values were extracted from the existing UI without change, so adopting the
/// tokens is visually neutral. Adjust a token here to restyle the whole app.
abstract final class PaydayColors {
  // Brand ("Pay Slot" direction).
  static const emerald = Color(0xff0E5A47);
  static const saffron = Color(0xffF4A62A);
  static const saffronPressed = Color(0xffE99A1D);
  static const sand = Color(0xffFBF6EA);
  static const ink = Color(0xff12261F);

  // Light neutrals.
  static const textSecondary = Color(0xff344B45);
  static const muted = Color(0xff50695E);
  static const line = Color(0xffE6DDC6);
  static const surfaceLow = Color(0xffF5F1E7);
  static const surfaceHigh = Color(0xffEEE8DA);
  static const mintTint = Color(0xffDDEBE2); // icon discs, light
  static const trackLight = Color(0xffE9F0EB); // progress track, light

  // Dark palette: neutral charcoal, with emerald and saffron as accents.
  static const darkBackground = Color(0xff131516);
  static const darkSurface = Color(0xff1D2022);
  static const darkSurfaceLow = Color(0xff25292B);
  static const darkSurfaceHigh = Color(0xff2E3336);
  static const darkLine = Color(0xff353A3D);
  static const darkText = Color(0xffF3F2ED);
  static const darkMuted = Color(0xffA9B0B3);
  static const darkPrimary = Color(0xff5FD3A9); // bright emerald, readable on charcoal
  static const darkOnPrimary = Color(0xff06241B);
  static const darkIcon = Color(0xffE6E9E7);
  static const darkIconDisc = Color(0xff22332D);
  static const darkBudgetDisc = Color(0xff22332D);
  static const darkOpeningMark = Color(0xff8CC8AD);
  static const darkCopper = Color(0xffF6B95A);
  static const darkStatusOver = Color(0xffF08A7C); // readable red on charcoal
  static const darkStatusOverBorder = Color(0xff6B3A35);
  static const darkStatusOverTrack = Color(0xff4A2B28);
  static const darkStatusNear = Color(0xffE5B56E);

  // Hero card (emerald background).
  static const heroMuted = Color(0xffB8D0BF);
  static const heroTop = Color(0xff137259);
  static const heroBottom = Color(0xff0B4A3B);

  // Budget status.
  static const statusGood = Color(0xff2C8979);
  static const statusNear = Color(0xffD2A15A);
  static const statusNearText = Color(0xff996522); // readable on white
  static const statusOver = Color(0xffCA554A);
  static const statusOverBorder = Color(0xffE9BEB8);
  static const statusOverTrack = Color(0xffF4D9D4);
  static const amber = Color(0xff986318);
}

/// Corner radii. Prefer these steps over new values.
abstract final class PaydayRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 20.0;
  static const sheet = 26.0;
  static const dialog = 28.0;
  static const card = 22.0;
  static const hero = 28.0;
  static const pill = 999.0;
}

/// Spacing scale (4-pt grid).
abstract final class PaydaySpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Type sizes. `caption` is the smallest size text should use.
abstract final class PaydayType {
  static const caption = 12.0;
  static const small = 13.0;
  static const body = 14.0;
  static const title = 16.0;
  static const section = 23.0;
  static const hero = 48.0;
}
