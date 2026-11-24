import 'dart:convert';

/// Optional Cash and Bank wallets. Turned on by entering today's balances;
/// only entries recorded after that moment (higher ids) move the balances,
/// so older records never need a wallet. Kept in settings as JSON, so
/// backups carry it without a format change.
const walletSetupKey = 'wallet_setup';
const walletTransfersKey = 'wallet_transfers';
const walletLastKey = 'wallet_last';
const walletNames = ['Cash', 'Bank'];

class WalletSetup {
  const WalletSetup({required this.cash, required this.bank, required this.afterId, required this.date});
  final int cash, bank, afterId;
  final String date;
  Map<String, Object?> toJson() => {'cash': cash, 'bank': bank, 'after_id': afterId, 'date': date};
  static WalletSetup? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      return WalletSetup(cash: (m['cash'] as num).toInt(), bank: (m['bank'] as num).toInt(),
          afterId: (m['after_id'] as num).toInt(), date: '${m['date'] ?? ''}');
    } catch (_) {
      return null;
    }
  }
}

class WalletTransfer {
  const WalletTransfer({required this.id, required this.date, required this.from, required this.amount});
  final String id, date, from;
  final int amount;
  String get to => from == 'Cash' ? 'Bank' : 'Cash';
  Map<String, Object?> toJson() => {'id': id, 'date': date, 'from': from, 'amount': amount};
  bool get valid => walletNames.contains(from) && amount > 0 && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);
}

List<WalletTransfer> decodeTransfers(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final v = jsonDecode(raw);
    if (v is! List) return [];
    return v.whereType<Map>().map((m) => WalletTransfer(id: '${m['id']}', date: '${m['date']}',
        from: '${m['from']}', amount: (m['amount'] as num).toInt())).where((t) => t.valid).toList();
  } catch (_) {
    return [];
  }
}

String encodeTransfers(List<WalletTransfer> list) => jsonEncode(list.map((t) => t.toJson()).toList());

/// Current balance of each wallet: today's starting amount, plus income and
/// money taken from savings, minus expenses and money moved to savings,
/// plus or minus transfers. Entries without a wallet count as Cash.
Map<String, int> walletBalances(WalletSetup setup, Iterable<Map<String, Object?>> transactions, List<WalletTransfer> transfers) {
  final out = {'Cash': setup.cash, 'Bank': setup.bank};
  for (final t in transactions) {
    final id = (t['id'] as num?)?.toInt() ?? 0;
    if (id <= setup.afterId) continue;
    final wallet = t['account']?.toString() == 'Bank' ? 'Bank' : 'Cash';
    final amount = (t['amount'] as num?)?.toInt() ?? 0;
    switch (t['type']?.toString()) {
      case 'Income':
      case 'Savings in':
      case 'Kridi in':
        out[wallet] = out[wallet]! + amount;
        break;
      case 'Expense':
      case 'Savings out':
      case 'Kridi out':
        out[wallet] = out[wallet]! - amount;
        break;
    }
  }
  for (final t in transfers) {
    out[t.from] = out[t.from]! - t.amount;
    out[t.to] = out[t.to]! + t.amount;
  }
  return out;
}
