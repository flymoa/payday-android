import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';
import 'large_text_test.dart' as lt;

// Temporary: finds which frame hangs on Savings in Arabic at double text size.
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('ar savings frames at $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(360, 780));
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await t.pumpWidget(PaydayLocal(initialData: Future.value(lt.sample()), store: lt.SampleStore(),
          preferencesWriter: (_) async {}, initialPreferences: const AppPreferences(language: 'ar')));
      for (var i = 0; i < 30; i++) { await t.pump(const Duration(milliseconds: 100)); }
      debugPrint('ar-debug $scale: home pumped');
      await t.tap(find.byKey(const ValueKey('bottom-3')).first);
      debugPrint('ar-debug $scale: tapped savings');
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 50));
        if (i == 15) debugPrintScheduleFrameStacks = true;
        debugPrint('ar-debug $scale: frame $i scheduled=${t.binding.hasScheduledFrame} transient=${SchedulerBinding.instance.transientCallbackCount}');
        if (i == 17) debugPrintScheduleFrameStacks = false;
      }
      await t.tap(find.byKey(const ValueKey('subtab-3-1')));
      for (var i = 0; i < 5; i++) { await t.pump(const Duration(milliseconds: 50)); debugPrint('ar-debug $scale: reserves frame $i'); }
      await t.tap(find.byKey(const ValueKey('subtab-3-2')));
      for (var i = 0; i < 5; i++) { await t.pump(const Duration(milliseconds: 50)); debugPrint('ar-debug $scale: wallets frame $i'); }
    }, timeout: const Timeout(Duration(seconds: 90)));
  }
}
