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
  /// Saffron in the dark theme: lifted so it does not vibrate on charcoal.
  /// Raw [saffron] (#F4A62A) is used in the light theme only.
  static const darkSaffron = darkCopper;
  /// Edge on the saffron add button (light): 5.48:1 on sand, so the button
  /// shape reads at 3:1 even though the fill itself is 1.88:1.
  static const saffronEdge = Color(0xff8A5A12);

  // Tinted surfaces for one-line notices (near-limit banner, report insight).
  static const nearTintLight = Color(0xffFCEBD0);
  static const nearTintDark = Color(0xff3A2E1C);
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

/// Category slices in Reports: emerald tones, darkest first, then a neutral
/// grey for "Other". No saffron: it is reserved for the add button and badge.
abstract final class PaydayReport {
  static const light = [Color(0xff0B4537), Color(0xff1F7A62), Color(0xff3B9A7E), Color(0xff7FB39C), Color(0xffB7D6C6), Color(0xff8A9398)];
  static const dark = [Color(0xffC4EEDC), Color(0xff8FD6BC), Color(0xff5FD3A9), Color(0xff579B82), Color(0xff3A5F51), Color(0xff7D8689)];
}

/// Records calendar: three spending steps, no per-day borders. Every step is
/// at least 3:1 against the card; the day number on it stays at 4.5:1 or more.
///   light (card #FFFFFF): 3.23 / 5.16 / 10.9 ; numbers ink 4.92, sand 4.78, sand 10.14
///   dark  (card #252A2D): 4.43 / 9.8 / 12.6  ; numbers #06241B 5.03 / 9.81 / 13.02
abstract final class PaydayCalendar {
  static const light = [Color(0xff5F9B83), Color(0xff2F7A60), Color(0xff0B4537)];
  static const lightOn = [PaydayColors.ink, PaydayColors.sand, PaydayColors.sand];
  static const dark = [Color(0xff579B82), Color(0xff8FD6BC), Color(0xffC4EEDC)];
  static const darkOn = [PaydayColors.darkOnPrimary, PaydayColors.darkOnPrimary, PaydayColors.darkOnPrimary];
}

abstract final class PaydaySpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// The five text sizes of the app. Nothing else should set a font size.
///   display 56 · hero amounts, the add-sheet amount
///   title   24 · page and sheet titles, hero decimals and currency
///   section 19 · section headings, summary sub-figures
///   body    15 · rows, buttons, list amounts
///   caption 13 · secondary lines; the smallest size text may use
abstract final class PaydayType {
  static const display = 56.0;
  static const title = 24.0;
  static const section = 19.0;
  static const body = 15.0;
  static const caption = 13.0;
  /// The one summary figure on a planning page ("Not assigned"). Sits between
  /// title and display on purpose: bigger than any row, far below the hero.
  static const figure = 28.0;

  // Older names, kept so call sites read the same; each is one of the five.
  static const small = body;
  static const sectionTitle = section;
  static const amount = body;
  static const hero = display;
  static const heroDecimals = title;
  static const heroCurrency = title;
}

/// Shared amount styles: tabular figures so columns of money line up.
abstract final class PaydayText {
  static const tabular = [FontFeature.tabularFigures()];
  static const amount = TextStyle(fontSize: PaydayType.body,
    fontWeight: FontWeight.w600, fontFeatures: tabular);
  /// Sub-figures in a summary ("Still to pay", Cash and Bank).
  static const figure = TextStyle(fontSize: PaydayType.section,
    fontWeight: FontWeight.w700, fontFeatures: tabular, letterSpacing: -.3);
  /// Row titles in every list.
  static const rowTitle = TextStyle(fontSize: PaydayType.body, fontWeight: FontWeight.w700);
}

/// The full colour scheme, built from tokens only (no seed, no generated tints).
ColorScheme paydayColorScheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return ColorScheme(
    brightness: brightness,
    primary: dark ? PaydayColors.darkPrimary : PaydayColors.emerald,
    onPrimary: dark ? PaydayColors.darkOnPrimary : const Color(0xffFFFFFF),
    primaryContainer: dark ? PaydayColors.emerald : PaydayColors.mintTint,
    onPrimaryContainer: dark ? PaydayColors.sand : PaydayColors.emerald,
    secondary: dark ? PaydayColors.darkPrimary : PaydayColors.emerald,
    onSecondary: dark ? PaydayColors.darkOnPrimary : const Color(0xffFFFFFF),
    secondaryContainer: dark ? PaydayColors.darkIconDisc : PaydayColors.mintTint,
    onSecondaryContainer: dark ? PaydayColors.darkText : PaydayColors.emerald,
    tertiary: dark ? PaydayColors.darkSaffron : PaydayColors.saffronText,
    onTertiary: dark ? PaydayColors.ink : const Color(0xffFFFFFF),
    tertiaryContainer: dark ? PaydayColors.nearTintDark : PaydayColors.nearTintLight,
    onTertiaryContainer: dark ? PaydayColors.darkSaffronText : PaydayColors.saffronText,
    error: dark ? PaydayColors.darkStatusOver : PaydayColors.statusOver,
    onError: dark ? PaydayColors.ink : const Color(0xffFFFFFF),
    errorContainer: dark ? PaydayColors.darkStatusOverTrack : PaydayColors.statusOverTrack,
    onErrorContainer: dark ? PaydayColors.darkStatusOver : PaydayColors.statusOver,
    surface: dark ? PaydayColors.darkSurface : PaydayCard.surfaceLight,
    onSurface: dark ? PaydayColors.darkText : PaydayColors.ink,
    onSurfaceVariant: dark ? PaydayColors.darkMuted : PaydayColors.muted,
    surfaceDim: dark ? PaydayColors.darkBackground : PaydayColors.surfaceHigh,
    surfaceBright: dark ? PaydayColors.darkSurfaceHigh : PaydayCard.surfaceLight,
    surfaceContainerLowest: dark ? PaydayColors.darkBackground : PaydayCard.surfaceLight,
    surfaceContainerLow: dark ? PaydayColors.darkSurfaceLow : PaydayColors.surfaceLow,
    surfaceContainer: dark ? PaydayColors.darkSurfaceLow : PaydayColors.surfaceLow,
    surfaceContainerHigh: dark ? PaydayColors.darkSurfaceHigh : PaydayColors.surfaceHigh,
    surfaceContainerHighest: dark ? PaydayColors.darkLine : PaydayColors.line,
    outline: dark ? PaydayCard.borderDark : PaydayCard.borderLight,
    outlineVariant: dark ? PaydayColors.darkLine : PaydayColors.line,
    shadow: const Color(0xff000000),
    scrim: const Color(0xff000000),
    inverseSurface: dark ? PaydayColors.darkText : PaydayColors.ink,
    onInverseSurface: dark ? PaydayColors.ink : PaydayColors.sand,
    inversePrimary: dark ? PaydayColors.emerald : PaydayColors.darkPrimary,
    surfaceTint: const Color(0x00000000),
  );
}
