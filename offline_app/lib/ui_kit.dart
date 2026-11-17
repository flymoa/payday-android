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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? scheme.outlineVariant)),
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

/// Filter or quick-choice pill. Selected pills are filled so the choice is obvious.
class PaydayPill extends StatelessWidget {
  const PaydayPill({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(button: true, selected: selected, child: Material(
      color: selected ? scheme.primary : scheme.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Center(widthFactor: 1, heightFactor: 1, child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[PaydayAppIcon(icon!, size: 17, color: selected ? scheme.onPrimary : scheme.onSurface), const SizedBox(width: 6)],
            Flexible(child: LText(label, style: TextStyle(color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w700, fontSize: PaydayType.small))),
          ])))))));
  }
}

/// Friendly placeholder for a list with nothing in it yet.
class PaydayEmpty extends StatelessWidget {
  const PaydayEmpty({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PaydayPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: .12)),
          child: Center(child: PaydayAppIcon(icon, size: 24, color: scheme.primary))),
        const SizedBox(height: 12),
        LText(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
      ]));
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.withValues(alpha: .12), borderRadius: BorderRadius.circular(PaydayRadius.md)),
      child: LText(label, style: TextStyle(color: tone, fontSize: PaydayType.caption, fontWeight: FontWeight.w700)));
  }
}
