import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/home_widget.dart';
import 'package:payday_local/offline_store.dart';

void main() {
  String t(String s) => s;
  test('amount appears only when opted in and App lock is off', () {
    final shown = homeWidgetText(showAmount: true, appLock: false, safeToSpend: '1,200.00 MAD', translate: t);
    expect(shown.title, 'Safe to spend');
    expect(shown.body, '1,200.00 MAD');
    for (final hidden in [
      homeWidgetText(showAmount: false, appLock: false, safeToSpend: '1,200.00 MAD', translate: t),
      homeWidgetText(showAmount: true, appLock: true, safeToSpend: '1,200.00 MAD', translate: t),
    ]) {
      expect(hidden.body, 'Tap to open');
      expect(hidden.title, 'Payday');
    }
  });
  test('the widget choice stays on this phone and is not restored from backups', () {
    expect(deviceLocalSettingKeys, contains(homeWidgetAmountKey));
  });
}
