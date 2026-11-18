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
  static const darkIconDisc = Color(0xff3A5F51); // 2.03:1 on the dark card; icon E6E9E7 on it 5.85:1
  static const darkBudgetDisc = darkIconDisc;
  static const darkOpeningMark = Color(0xff8CC8AD);
  static const darkCopper = Color(0xffF6B95A);
  static const darkStatusOver = Color(0xffF08A7C); // readable red on charcoal
  static const darkStatusOverBorder = Color(0xff6B3A35);
  static const darkStatusOverTrack = Color(0xff4A2B28);
  static const darkStatusNear = Color(0xffE5B56E);

  // Hero card (emerald background).
  // Flat emerald, no gradient. heroMuted on emerald = 6.6:1.
  static const hero = emerald;
  static const heroMuted = Color(0xffCFE2D5);

  // Budget status.
  static const statusGood = Color(0xff2C8979);
  static const statusNear = Color(0xffD2A15A);
  // Saffron-coloured text and thin strokes. Raw saffron (1.88:1 on sand) is fills only.
  static const saffronText = Color(0xff8A5A12); // 5.48:1 on sand, 5.91:1 on white
  static const darkSaffronText = Color(0xffF6B95A); // 10.47:1 on darkBackground, 9.37:1 on darkSurface
  static const statusNearText = saffronText;
  static const statusOver = Color(0xffA63A30);
  static const statusOverBorder = Color(0xffE9BEB8);
  static const statusOverTrack = Color(0xffF6DCD7);
  static const amber = saffronText;
}

/// Corner radii. The app uses exactly two: [sm] (6) for small parts and
/// [lg] (14) for containers. The other names alias one of the two so older
/// call sites follow; `pill` is kept only for full-round progress tracks.
abstract final class PaydayRadius {
  static const sm = 6.0;
  static const lg = 14.0;
  static const xs = sm;
  static const md = sm;
  static const xl = lg;
  static const sheet = lg;
  static const dialog = lg;
  static const card = lg;
  static const hero = lg;
  static const pill = 999.0;
}

/// Spacing scale (4-pt grid).
/// Secondary controls (search, chips, month switcher, secondary buttons) sit on a
/// flat tonal fill with no border; only the primary action is filled emerald.
abstract final class PaydayControl {
  static const fillLight = PaydayColors.surfaceHigh;
  static const fillDark = PaydayColors.darkSurfaceHigh;
  static const target = 48.0;
  static const chipHeight = 40.0;
}

/// Cards for list content (budget categories, records, goals, bills): a surface
/// that is clearly not the page colour, a 1px border, radius 14, no shadow.
abstract final class PaydayCard {
  static const surfaceLight = Color(0xffFFFFFF);
  static const borderLight = Color(0xffAE9F7C); // 2.42:1 on sand, 2.61:1 on the white card
  static const surfaceDark = Color(0xff252A2D);
  static const borderDark = Color(0xff646D70); // 3.46:1 on darkBackground, 2.74:1 on the dark card
  static const gap = 8.0;
}

/// Year chart series. Income is the brand primary; spending is a neutral slate,
/// never saffron (saffron is reserved for the add button).
abstract final class PaydayChart {
  static const spentLight = Color(0xff6B7F86); // 4.2:1 on the white card
  static const spentDark = Color(0xff7D8689); // ~3.9:1 on the dark card; darker than mint Income so the series differ by lightness
}

abstract final class PaydaySpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Type sizes. `caption` is the smallest size text should use.
abstract final class PaydayType {
  static const caption = 13.0;
  static const small = 14.0;
  static const body = 14.0;
  static const title = 16.0;
  static const section = 23.0;
  static const sectionTitle = 19.0;
  static const amount = 16.0;
  static const figure = 20.0;
  static const display = 40.0;
  static const heroCurrency = 20.0;
  static const heroDecimals = 24.0;
  static const hero = 56.0;
}

/// Shared amount styles: tabular figures so columns of money line up.
abstract final class PaydayText {
  static const tabular = [FontFeature.tabularFigures()];
  static const amount = TextStyle(fontSize: PaydayType.amount,
    fontWeight: FontWeight.w600, fontFeatures: tabular);
  /// Summary figures above a list ("Still to pay", "Total saved" sub-figures).
  static const figure = TextStyle(fontSize: PaydayType.figure,
    fontWeight: FontWeight.w700, fontFeatures: tabular, letterSpacing: -.3);
}
