import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'design_tokens.dart';
import 'localization.dart';

/// Shared building blocks for the PAYDAY screens. Every widget reads its
/// colours from the active theme, so light and dark mode stay in step.

/// Rounded surface for a grouped block. Deliberately a plain decorated box,
/// not a Card: rows inside keep their own transparent ink surface.
class PaydayPanel extends StatelessWidget {
  const PaydayPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero, this.color, this.borderColor, this.radius = PaydayRadius.card});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double radius;
  @override
  Widget build(BuildContext context) {
    // Deliberate boxes (close-the-month, year chart, prompts) match the content cards.
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? (dark ? PaydayCard.surfaceDark : PaydayCard.surfaceLight),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? (dark ? PaydayCard.borderDark : PaydayCard.borderLight))),
      child: child);
  }
}

/// Rounded progress bar. Safe with zero targets: invalid values show as empty.
class PaydayProgress extends StatelessWidget {
  const PaydayProgress({super.key, required this.value, this.color, this.trackColor, this.height = 8});
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return ExcludeSemantics(child: ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(width: double.infinity, height: height, child: Stack(fit: StackFit.expand, children: [
        ColoredBox(color: trackColor ?? scheme.surfaceContainerHigh),
        FractionallySizedBox(alignment: AlignmentDirectional.centerStart, widthFactor: shown,
          child: DecoratedBox(decoration: BoxDecoration(
            color: color ?? scheme.primary, borderRadius: BorderRadius.circular(height)))),
      ]))));
  }
}

/// Horizontal inset for list rows. Rows inside a bordered card sit 14 in from
/// its edge; rows directly on the page line up with the section headings.
class PaydayRowInset extends InheritedWidget {
  const PaydayRowInset({super.key, required this.horizontal, required super.child});
  final double horizontal;
  static const card = PaydaySpace.md + 2;
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaydayRowInset>()?.horizontal ?? card;
  @override
  bool updateShouldNotify(PaydayRowInset oldWidget) => oldWidget.horizontal != horizontal;
}

/// Filter or quick-choice pill. Selected: mint fill, emerald text and a 1.5px
/// emerald edge. A solid fill is kept for the one primary action (Save).
class PaydayPill extends StatelessWidget {
  const PaydayPill({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.raw = false});
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  /// Show [label] as written (a language name in its own script), never translated.
  final bool raw;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = selected ? (dark ? PaydayColors.darkIconDisc : PaydayColors.mintTint) : (dark ? PaydayControl.fillDark : PaydayControl.fillLight);
    final text = selected ? (dark ? PaydayColors.darkText : PaydayColors.emerald) : scheme.onSurface;
    final style = TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: PaydayType.body);
    return Semantics(button: true, selected: selected, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap,
     child: Padding(padding: const EdgeInsets.symmetric(vertical: (PaydayControl.target - PaydayControl.chipHeight) / 2), child: Material(
      color: fill,
      shape: StadiumBorder(side: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PaydayControl.chipHeight),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: PaydaySpace.md + 2, vertical: PaydaySpace.sm),
          child: Center(widthFactor: 1, heightFactor: 1, child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[PaydayAppIcon(icon!, size: 17, color: text), const SizedBox(width: 6)],
            Flexible(child: raw ? Text(label, style: style) : LText(label, style: style)),
          ])))))))));
  }
}

/// Placeholder for a list with nothing in it yet. With [title] and [action] it
/// becomes a page-level empty state: a headline, one sentence and one button,
/// left-aligned like the rest of the page.
class PaydayEmpty extends StatelessWidget {
  const PaydayEmpty({super.key, required this.icon, required this.message, this.title, this.action});
  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disc = Container(width: 48, height: 48,
      decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: .12)),
      child: Center(child: PaydayAppIcon(icon, size: 24, color: scheme.primary)));
    if (title != null) {
      return Padding(padding: const EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs, PaydaySpace.xl, PaydaySpace.xs, PaydaySpace.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          disc,
          const SizedBox(height: PaydaySpace.lg),
          LText(title!, style: TextStyle(fontFamily: 'Bricolage', fontSize: PaydayType.title, fontWeight: FontWeight.w800, color: scheme.onSurface)),
          const SizedBox(height: PaydaySpace.xs),
          LText(message, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (action != null) ...[const SizedBox(height: PaydaySpace.lg), action!],
        ]));
    }
    // Empty states sit on the page, start-aligned like the headings above them;
    // a box around "nothing here" adds weight without content.
    return SizedBox(width: double.infinity, child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs, PaydaySpace.lg, PaydaySpace.xl, PaydaySpace.lg),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        disc,
        const SizedBox(width: PaydaySpace.md),
        Expanded(child: LText(message, style: TextStyle(color: scheme.onSurfaceVariant))),
        if (action != null) ...[const SizedBox(width: PaydaySpace.sm), action!],
      ])));
  }
}

/// Small rounded label, used for counts and status notes.
class PaydayTag extends StatelessWidget {
  const PaydayTag(this.label, {super.key, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PaydaySpace.sm + 2, vertical: PaydaySpace.xs),
      decoration: BoxDecoration(color: tone.withValues(alpha: .12), borderRadius: BorderRadius.circular(PaydayRadius.md)),
      child: LText(label, style: TextStyle(color: tone, fontSize: PaydayType.caption, fontWeight: FontWeight.w700)));
  }
}
