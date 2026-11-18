import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/pay_cycle.dart';
import 'package:payday_local/payday_settings_page.dart';

class PaydayStore extends OfflineStore {
  final settings = <String, String>{};
  @override
  Future<Map<String, List<RowData>>> snapshot() async => {
        'settings': [for (final e in settings.entries) {'key': e.key, 'value': e.value}],
      };
  @override
  Future<void> setSetting(String key, String value) async => settings[key] = value;
  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('payday is chosen in Settings and saved as two settings', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final store = PaydayStore();
    await t.pumpWidget(MaterialApp(home: FinanceScreen(store: store, initialData: store.snapshot())));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('home-settings-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('payday-setting')), findsOneWidget, reason: 'payday sits at the top of Settings');
    await t.tap(find.byKey(const ValueKey('payday-setting')));
    await t.pumpAndSettle();
    expect(find.byType(PaydaySettingsPage), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('payday-day-last')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('payday-weekend-after')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('payday-save')));
    await t.tap(find.byKey(const ValueKey('payday-save')));
    await t.pumpAndSettle();
    expect(store.settings[PaydayRule.dayKey], 'last');
    expect(store.settings[PaydayRule.weekendKey], 'after');
    expect(find.byType(PaydaySettingsPage), findsNothing, reason: 'the page closes after saving');
    expect(t.takeException(), isNull);
  });

  testWidgets('the preview follows the chosen rule before saving', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    PaydayRule? saved;
    await t.pumpWidget(MaterialApp(
        home: PaydaySettingsPage(
            initial: const PaydayRule(),
            today: DateTime(2026, 11, 18),
            onChanged: (r) async {
              saved = r;
              return true;
            })));
    await t.pumpAndSettle();
    // 28 Nov 2026 is a Saturday: paid the Friday before.
    expect(find.text('Next payday: 27 Nov'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('payday-weekend-keep')));
    await t.pumpAndSettle();
    expect(find.text('Next payday: 28 Nov'), findsOneWidget);
    expect(saved, isNull, reason: 'nothing is saved until Save');
    expect(t.takeException(), isNull);
  });
}
