import 'package:flutter/material.dart';

/// PAYDAY design tokens — the single source of truth for colours, corner
/// radii, spacing and type sizes. Screens should reference these instead of
/// writing hex values or magic numbers inline.
///
/// Values were extracted from the existing UI without change, so adopting the
/// tokens is visually neutral. Adjust a token here to restyle the whole app.
abstract final class PaydayColors {
  // Brand: palette from the Bank Al-Maghrib 200 DH note.
  static const emerald = Color(0xff2A47A8);
  static const saffron = Color(0xffF5A02B);
  static const saffronPressed = Color(0xffE98F1C);
  static const sand = Color(0xffEAF6FB);
  static const ink = Color(0xff0F1E4A);

  // Light neutrals.
  static const textSecondary = Color(0xff2A3D6B);
  static const muted = Color(0xff4A5F8C);
  static const line = Color(0xffC5DCEA);
  static const surfaceLow = Color(0xffE1F0F7);
  static const surfaceHigh = Color(0xffD4E8F2);
  static const mintTint = Color(0xffCFE0F7); // icon discs, light
  static const trackLight = Color(0xffDCE9F5); // progress track, light

  // Note: the names `emerald` (royal blue), `sand` (pale sky) and `mintTint` are
  // kept from the old palette so call sites don't churn; the values are the 200 DH note.

  // Dark palette: deep navy, with periwinkle blue and orange as accents.
  static const darkBackground = Color(0xff0E1428);
  static const darkSurface = Color(0xff151C36);
  static const darkSurfaceLow = Color(0xff1C2442);
  static const darkSurfaceHigh = Color(0xff252E50);
  static const darkLine = Color(0xff2E3860);
  static const darkText = Color(0xffF1F4FA);
  static const darkMuted = Color(0xffA9B3CC);
  static const darkPrimary = Color(0xff8FB0FF); // periwinkle: 8.55:1 on darkBackground, 7.29:1 on the dark card
  static const darkOnPrimary = Color(0xff0A1840); // 8.07:1 on darkPrimary
  static const darkIcon = Color(0xffE4E9F5);
  static const darkIconDisc = Color(0xff34467F); // 1.73:1 on the dark card; darkIcon on it 7.42:1, darkPrimary 4.22:1 (icons/bold glyphs only)
  static const darkBudgetDisc = darkIconDisc;
  static const darkOpeningMark = Color(0xff9DB6EE);
  static const darkCopper = Color(0xffF6B95A);
  static const darkStatusOver = Color(0xffF08A7C); // 6.41:1 on the dark card. Not for the hero: only 3.36:1 on royal blue
  static const darkStatusOverBorder = Color(0xff6B3A35);
  static const darkStatusOverTrack = Color(0xff4A2B28);
  static const darkStatusNear = Color(0xffE5B56E);

  // Hero card (royal blue background, same in both themes).
  // sand on hero 7.44:1, white 8.19:1, heroMuted 6.16:1.
  static const hero = emerald;
  static const heroMuted = Color(0xffD3E0FA);
  // Overspent number, icon and bar on the hero: 4.94:1 on royal blue, so the
  // 24px decimals and the 18px icon read too (darkStatusOver was 3.36:1).
  static const heroOver = Color(0xffFFB8A8);

  // Budget status. statusGood (teal) is 3.56:1 on sand: fills and chart slices only, not text.
  static const statusGood = Color(0xff1F8F8A);
  static const statusNear = Color(0xffD2A15A); // fills only (2.34:1 on white)
  // Orange-coloured text and thin strokes. Raw saffron (~1.9:1 on sand) is fills only.
  static const saffronText = Color(0xff8A5A12); // 5.37:1 on sand, 5.91:1 on white
  static const darkSaffronText = Color(0xffF6B95A); // 10.45:1 on darkBackground, 9.59:1 on darkSurface
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
/// flat tonal fill with no border; only the primary action is filled royal blue.
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
  static const borderLight = Color(0xff7F9BB8); // 2.62:1 on sand, 2.88:1 on the white card
  static const surfaceDark = Color(0xff1A2240);
  static const borderDark = Color(0xff5E6C96); // 3.53:1 on darkBackground, 3.02:1 on the dark card
  static const gap = 8.0;
}

/// Year chart series. Income is the brand primary; spending is a neutral slate,
/// never saffron (saffron is reserved for the add button).
abstract final class PaydayChart {
  static const spentLight = Color(0xff6B7FA3); // 4.05:1 on the white card
  static const spentDark = Color(0xff8590AD); // 4.89:1 on the dark card; darker than periwinkle Income so the series differ by lightness
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
