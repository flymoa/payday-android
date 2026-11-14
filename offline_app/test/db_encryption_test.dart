import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/db_encryption.dart';

void main() {
  test('recognises an unencrypted SQLite header only', () {
    final header = [...'SQLite format 3'.codeUnits, 0];
    expect(isPlainSqlite(header), isTrue);
    expect(isPlainSqlite([...header.sublist(0, 15), 1]), isFalse);
    expect(isPlainSqlite(List.filled(16, 0x5a)), isFalse);
    expect(isPlainSqlite([1, 2, 3]), isFalse);
  });
}
