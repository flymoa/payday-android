import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';
import 'large_text_test.dart' as lt;

// Temporary: same path as the large-text check, frame by frame.
void main() {
  testWidgets('ar large text path frame by frame', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 780));
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() {
      t.binding.setSurfaceSize(null);
      t.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => debugPrint('ar-debug error: ${details.exceptionAsString().split('\n').first}');
    addTearDown(() => FlutterError.onError = previous);
    await t.pumpWidget(PaydayLocal(initialData: Future.value(lt.sample()), store: lt.SampleStore(),
        preferencesWriter: (_) async {}, initialPreferences: const AppPreferences(language: 'ar')));
    for (var i = 0; i < 40; i++) { await t.pump(const Duration(milliseconds: 100)); }
    for (final tab in [1, 2, 3]) {
      await t.tap(find.byKey(ValueKey('bottom-$tab')).first);
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (tab == 3 && i == 30) debugPrintScheduleFrameStacks = true;
        if (tab == 3 && i >= 28) debugPrint('ar-debug tab $tab frame $i scheduled=${t.binding.hasScheduledFrame} transient=${SchedulerBinding.instance.transientCallbackCount}');
        if (tab == 3 && i == 31) debugPrintScheduleFrameStacks = false;
      }
      debugPrint('ar-debug tab $tab done scheduled=${t.binding.hasScheduledFrame}');
    }
    FlutterError.onError = previous;
  }, timeout: const Timeout(Duration(seconds: 90)));
}
