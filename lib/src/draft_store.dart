import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'model.dart';

/// Local encrypted FIFO: keep original UUID until a verified Google write.
class PendingExpenses {
  PendingExpenses({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'payday_pending_queue_v1';

  Future<List<Expense>> all() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    final value = jsonDecode(raw);
    if (value is! List) throw StateError('Queue storage is invalid; do not clear app data.');
    return value.map((v) => Expense.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<void> put(Expense entry) async {
    final entries = await all();
    if (entries.any((v) => v.id == entry.id)) return;
    if (entries.length >= 500) throw StateError('Pending queue is full.');
    entries.add(entry);
    await _write(entries);
  }

  Future<void> removeConfirmed(String id) async {
    final entries = await all();
    if (!entries.any((v) => v.id == id)) throw StateError('Pending ID is missing.');
    await _write(entries.where((v) => v.id != id).toList());
  }

  Future<void> _write(List<Expense> entries) async {
    await _storage.write(key: _key,
      value: jsonEncode(entries.map((v) => v.toJson()).toList()));
  }
}
