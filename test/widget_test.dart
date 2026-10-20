import 'package:flutter_test/flutter_test.dart';
import 'package:payday_mobile/src/model.dart';

void main() {
  test('DEMO file is fixed, not the outdated official tracker', () {
    expect(demoSpreadsheetId, '1lu6JabfKowbZhHXrGD9rJeQdbpXNc9_YnTPucSr9_Yg');
  });
}
