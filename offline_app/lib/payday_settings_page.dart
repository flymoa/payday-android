import 'package:flutter/material.dart';
import 'app_language.dart';
import 'design_tokens.dart';
import 'localization.dart';
import 'pay_cycle.dart';
import 'settings_pages.dart';

/// Pick payday: a day of the month (or the last day) and what happens when it
/// lands on a weekend. A live preview shows the cycles the rule produces.
class PaydaySettingsPage extends StatefulWidget {
  const PaydaySettingsPage({super.key, required this.initial, required this.onChanged, this.today});
  final PaydayRule initial;
  final Future<bool> Function(PaydayRule) onChanged;
  final DateTime? today;
  @override
  State<PaydaySettingsPage> createState() => _PaydaySettingsPageState();
}

class _PaydaySettingsPageState extends State<PaydaySettingsPage> {
  late PaydayRule rule = widget.initial;
  bool saving = false;

  Future<void> save() async {
    if (saving) return;
    if (rule == widget.initial) {
      Navigator.pop(context);
      return;
    }
    setState(() => saving = true);
    try {
      final ok = await widget.onChanged(rule);
      if (mounted && ok) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: LText('Could not save payday. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final today = widget.today ?? DateTime.now();
    String day(DateTime d) => localizedShortDay(d, supportedLanguage(language));
    Widget label(String text) => Padding(
        padding: const EdgeInsetsDirectional.only(top: PaydaySpace.lg, bottom: PaydaySpace.sm),
        child: LText(text, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)));
    Widget cell(int value, String text, {Key? key}) {
      final selected = rule.day == value;
      return Semantics(
        selected: selected,
        button: true,
        child: Material(
          key: key,
          color: selected ? scheme.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PaydayRadius.md),
              side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: saving ? null : () => setState(() => rule = PaydayRule(day: value, weekend: rule.weekend)),
            child: SizedBox(
                height: 48,
                child: Center(
                    child: LText(text,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: selected ? scheme.onPrimary : scheme.onSurface)))),
          ),
        ),
      );
    }

    final cycles = upcomingCycles(today, rule);
    final next = payCycleFor(today, rule).nextPayday;
    return SettingsPageScaffold(
      title: 'Salary day',
      busy: saving,
      body: ListView(padding: settingsPagePadding, children: [
        if (saving) const LinearProgressIndicator(),
        LText('Every amount in Payday runs from one payday to the next.', style: TextStyle(color: scheme.onSurfaceVariant)),
        label('Which day is payday?'),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 6 * PaydaySpace.xs) / 7;
          return Wrap(spacing: PaydaySpace.xs, runSpacing: PaydaySpace.xs, children: [
            for (var d = 1; d <= 31; d++) SizedBox(width: w, child: cell(d, '$d', key: ValueKey('payday-day-$d'))),
          ]);
        }),
        const SizedBox(height: PaydaySpace.xs),
        cell(0, 'Last day of the month', key: const ValueKey('payday-day-last')),
        label('If payday falls on a weekend'),
        RadioGroup<WeekendRule>(
          groupValue: rule.weekend,
          onChanged: (w) {
            if (w != null && !saving) setState(() => rule = PaydayRule(day: rule.day, weekend: w));
          },
          child: const Column(children: [
            RadioListTile<WeekendRule>(key: ValueKey('payday-weekend-before'), value: WeekendRule.before, title: LText('Paid the Friday before'), contentPadding: EdgeInsets.zero),
            RadioListTile<WeekendRule>(key: ValueKey('payday-weekend-after'), value: WeekendRule.after, title: LText('Paid the Monday after'), contentPadding: EdgeInsets.zero),
            RadioListTile<WeekendRule>(key: ValueKey('payday-weekend-keep'), value: WeekendRule.keep, title: LText('Keep the date'), contentPadding: EdgeInsets.zero),
          ]),
        ),
        label('Your next cycles'),
        LText('Next payday: ${day(next)}', key: const ValueKey('payday-next'), style: const TextStyle(fontWeight: FontWeight.w700)),
        for (final c in cycles)
          Padding(
            padding: const EdgeInsets.only(top: PaydaySpace.xs),
            child: Text('${day(c.start)} – ${day(c.end)}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        const SizedBox(height: PaydaySpace.md),
        LText('If your salary arrives up to 5 days early or late, the cycle starts on the day you log it.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: PaydayType.caption)),
        const SizedBox(height: PaydaySpace.lg),
        FilledButton(
            key: const ValueKey('payday-save'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: saving ? null : save,
            child: const LText('Save payday')),
      ]),
    );
  }
}
