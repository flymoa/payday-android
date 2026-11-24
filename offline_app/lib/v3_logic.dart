import 'dart:convert';
import 'finance.dart';

/// Amount typed as a small sum, e.g. "85+40" or "3x12,50". Returns cents, or null when
/// the text is not a valid positive amount. Plain numbers go through [parseMoneyCents].
int? evalAmountCents(String input) {
  final text = normalizeDigits(input).replaceAll(' ', '').replaceAll(' ', '').replaceAll('×', '*').replaceAll('x', '*')
      .replaceAll('X', '*').replaceAll('÷', '/').replaceAll('−', '-');
  if (text.isEmpty) return null;
  if (!RegExp(r'[+\-*/]').hasMatch(text.substring(1))) return parseMoneyCents(text);
  if (!RegExp(r'^[0-9.,+\-*/]+$').hasMatch(text)) return null;
  // Numbers and operators; × and ÷ before + and −.
  final tokens = RegExp(r'(\d+(?:[.,]\d{1,2})?)|([+\-*/])').allMatches(text).map((m) => m.group(0)!).toList();
  if (tokens.join() != text) return null;
  final values = <double>[];
  final ops = <String>[];
  var expectNumber = true;
  for (final t in tokens) {
    final isOp = '+-*/'.contains(t);
    if (expectNumber == isOp) return null;
    if (isOp) {
      ops.add(t);
    } else {
      values.add(double.parse(t.replaceAll(',', '.')));
    }
    expectNumber = isOp;
  }
  if (expectNumber) return null;
  // First pass: * and /.
  final v = <double>[values.first];
  final o = <String>[];
  for (var i = 0; i < ops.length; i++) {
    final next = values[i + 1];
    if (ops[i] == '*') {
      v[v.length - 1] = v.last * next;
    } else if (ops[i] == '/') {
      if (next == 0) return null;
      v[v.length - 1] = v.last / next;
    } else {
      o.add(ops[i]);
      v.add(next);
    }
  }
  var total = v.first;
  for (var i = 0; i < o.length; i++) {
    total = o[i] == '+' ? total + v[i + 1] : total - v[i + 1];
  }
  final cents = (total * 100).round();
  return cents > 0 && cents <= 100000000000 ? cents : null;
}

/// True when the text is a sum to work out rather than a plain amount.
bool isAmountExpression(String input) {
  final t = input.trim();
  return t.length > 1 && RegExp(r'[+\-*/×÷x−]').hasMatch(t.substring(1));
}

/// What Payday can read from a bank or wallet SMS that the user pastes.
class BankMessage {
  const BankMessage({required this.amountCents, required this.merchant, required this.income, this.date});
  final int amountCents;
  final String merchant;
  final bool income;
  final DateTime? date;
}

/// Reads amount, shop and date from a pasted bank message (French or English, MAD/DH/DHS).
/// Returns null when no amount is found. Nothing leaves the phone.
BankMessage? parseBankMessage(String text, {DateTime? now}) {
  final t = text.replaceAll(' ', ' ').replaceAll('\n', ' ');
  final amount = RegExp(r'(\d{1,3}(?:[ .]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:MAD|DHS?|dh|Dhs?|dirhams?)\b', caseSensitive: false)
          .firstMatch(t) ??
      RegExp(r'(?:MAD|DHS?)\s*(\d{1,3}(?:[ .]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)', caseSensitive: false).firstMatch(t);
  if (amount == null) return null;
  var raw = amount.group(1)!;
  // "2 011,00" or "2.011,00": spaces/dots before 3 digits are thousands.
  raw = raw.replaceAllMapped(RegExp(r'[ .](?=\d{3}(?:\D|$))'), (_) => '');
  final cents = parseMoneyCents(raw.replaceAll(' ', ''));
  if (cents == null) return null;
  final lower = t.toLowerCase();
  final income = RegExp(r'\b(virement re[çc]u|cr[ée]dit(?:é)?|re[çc]u|received|credited|versement)\b').hasMatch(lower) &&
      !RegExp(r'\b(paiement|achat|retrait|d[ée]bit|payment|purchase)\b').hasMatch(lower);
  final shop = RegExp(r'\b(?:chez|aupr[eè]s de|at|à|a)\s+([A-Z0-9][A-Za-z0-9&\x27 .\-]{1,40}?)(?=\s+(?:le|on|du|en date|à \d|a \d)\b|[.,;]|\s*$)', caseSensitive: true)
      .firstMatch(t);
  var merchant = shop?.group(1)?.trim() ?? '';
  if (RegExp(r'^\d').hasMatch(merchant)) merchant = '';
  if (merchant.isNotEmpty) {
    merchant = merchant.split(' ').map((w) => w.length <= 3 && w == w.toUpperCase() && w.length > 1 ? w : (w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())).join(' ');
  }
  DateTime? date;
  final d = RegExp(r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b').firstMatch(t);
  if (d != null) {
    final n = now ?? DateTime.now();
    final day = int.parse(d.group(1)!), month = int.parse(d.group(2)!);
    var year = d.group(3) == null ? n.year : int.parse(d.group(3)!);
    if (year < 100) year += 2000;
    if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      date = DateTime(year, month, day);
      if (d.group(3) == null && date.isAfter(n)) date = DateTime(year - 1, month, day);
      if (date.isAfter(n)) date = null;
    }
  }
  return BankMessage(amountCents: cents, merchant: merchant, income: income, date: date);
}

/// One row read from a bank CSV export.
class CsvEntry {
  const CsvEntry(this.date, this.description, this.amountCents, this.income);
  final String date; // yyyy-mm-dd
  final String description;
  final int amountCents;
  final bool income;
}

/// Reads a bank statement CSV: finds the date, label and amount columns by their headers
/// (French or English; one signed amount column, or Débit/Crédit columns). Separator , ; or tab.
List<CsvEntry> parseBankCsv(String text) {
  final lines = const LineSplitter().convert(text.replaceAll('﻿', '')).where((l) => l.trim().isNotEmpty).toList();
  if (lines.length < 2) return const [];
  final header = lines.first;
  final sep = [';', '\t', ','].reduce((a, b) => header.split(a).length >= header.split(b).length ? a : b);
  List<String> cells(String l) {
    final out = <String>[];
    var cur = StringBuffer();
    var quoted = false;
    for (final ch in l.split('')) {
      if (ch == '"') {
        quoted = !quoted;
      } else if (ch == sep && !quoted) {
        out.add(cur.toString().trim());
        cur = StringBuffer();
      } else {
        cur.write(ch);
      }
    }
    out.add(cur.toString().trim());
    return out;
  }
  final h = cells(header).map((c) => c.toLowerCase()).toList();
  int find(List<String> keys) => h.indexWhere((c) => keys.any((k) => c.contains(k)));
  final di = find(['date']);
  final li = find(['libell', 'description', 'label', 'details', 'détail', 'operation', 'opération', 'narration']);
  final debit = find(['débit', 'debit', 'retrait', 'withdrawal']);
  final credit = find(['crédit', 'credit', 'versement', 'deposit']);
  final amountI = find(['montant', 'amount', 'somme']);
  if (di < 0 || (amountI < 0 && debit < 0 && credit < 0)) return const [];
  int? money(String s) {
    var v = s.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (v.isEmpty) return null;
    final neg = v.startsWith('-');
    v = v.replaceAll('-', '');
    if (v.contains(',') && v.contains('.')) {
      v = v.lastIndexOf(',') > v.lastIndexOf('.') ? v.replaceAll('.', '') : v.replaceAll(',', '');
    }
    v = v.replaceAll(RegExp(r'[.,](?=\d{3}(?:[.,]|$))'), '');
    final c = parseMoneyCents(v);
    return c == null ? null : (neg ? -c : c);
  }
  String? isoDate(String s) {
    final a = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})').firstMatch(s);
    if (a != null) {
      var y = int.parse(a.group(3)!);
      if (y < 100) y += 2000;
      final m = int.parse(a.group(2)!), d = int.parse(a.group(1)!);
      if (m < 1 || m > 12 || d < 1 || d > 31) return null;
      return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    }
    final b = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    return b == null ? null : '${b.group(1)}-${b.group(2)}-${b.group(3)}';
  }
  final out = <CsvEntry>[];
  for (final l in lines.skip(1)) {
    final c = cells(l);
    String at(int i) => i >= 0 && i < c.length ? c[i] : '';
    final date = isoDate(at(di));
    if (date == null) continue;
    int? cents;
    bool income;
    if (debit >= 0 || credit >= 0) {
      final dv = money(at(debit)), cv = money(at(credit));
      if (cv != null && cv.abs() > 0) {
        cents = cv.abs();
        income = true;
      } else if (dv != null && dv.abs() > 0) {
        cents = dv.abs();
        income = false;
      } else {
        continue;
      }
    } else {
      final v = money(at(amountI));
      if (v == null || v == 0) continue;
      cents = v.abs();
      income = v > 0;
    }
    out.add(CsvEntry(date, at(li), cents, income));
  }
  return out;
}

/// Kridi: money owed between the user and a person, a shop's carnet, or an instalment loan.
/// Stored in settings as JSON. It tracks who owes what; spending itself is recorded as usual.
class Kridi {
  Kridi({required this.id, required this.name, required this.kind, required this.moves, this.monthly = 0, this.months = 0, this.remind = true, this.dueDate, this.limit = 0, this.payDay = 0, this.autoThrough});
  final int id;
  String name;
  /// borrowed (I owe a person), lent (a person owes me), shop (carnet: I owe the shop), loan (instalments I pay).
  final String kind;
  /// date, amount (cents, + adds to the debt, − pays it back), note.
  final List<Map<String, Object>> moves;
  int monthly; // loan: instalment amount
  int months; // loan: number of instalments
  bool remind;
  /// borrowed / lent: the day the money should be paid back (YYYY-MM-DD), optional.
  String? dueDate;
  /// shop: carnet credit limit in cents, 0 = no limit.
  int limit;
  /// loan: day of the month the bank takes the instalment (1–31), 0 = not set.
  int payDay;
  /// loan: last day already checked for an automatic bank payment (YYYY-MM-DD).
  String? autoThrough;
  bool get overLimit => kind == 'shop' && limit > 0 && balance > limit;
  bool get iOwe => kind != 'lent';
  int get balance => moves.fold<int>(0, (n, m) => n + (m['amount'] as int));
  int get paidCount => kind == 'loan' && monthly > 0 ? moves.where((m) => (m['amount'] as int) < 0).length : 0;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'kind': kind, 'moves': moves, 'monthly': monthly, 'months': months, 'remind': remind,
      if (dueDate != null) 'due': dueDate!, if (limit > 0) 'limit': limit, if (payDay > 0) 'payDay': payDay, if (autoThrough != null) 'auto': autoThrough!};
  static Kridi fromJson(Map<String, dynamic> j) => Kridi(
      id: j['id'] as int, name: j['name'] as String, kind: j['kind'] as String,
      moves: [for (final m in (j['moves'] as List)) {'date': m['date'] as String, 'amount': m['amount'] as int, 'note': (m['note'] ?? '') as String}],
      monthly: (j['monthly'] ?? 0) as int, months: (j['months'] ?? 0) as int, remind: (j['remind'] ?? true) as bool,
      dueDate: j['due'] as String?, limit: (j['limit'] ?? 0) as int, payDay: (j['payDay'] ?? 0) as int, autoThrough: j['auto'] as String?);
}

const kridiKey = 'kridi_v1';
List<Kridi> decodeKridi(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    return [for (final j in jsonDecode(raw) as List) Kridi.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}
String encodeKridi(List<Kridi> list) => jsonEncode([for (final k in list) k.toJson()]);

/// Share of monthly income that goes to instalment repayments, in percent.
int repaymentShare(List<Kridi> list, int monthlyIncome) {
  if (monthlyIncome <= 0) return 0;
  final monthly = list.where((k) => k.kind == 'loan' && k.balance > 0).fold<int>(0, (n, k) => n + k.monthly);
  return (monthly * 100 / monthlyIncome).round();
}

/// Daret (rotating savings): each member pays the same amount each month; one member takes the pot.
class Daret {
  Daret({required this.id, required this.name, required this.members, required this.amount, required this.start, required this.myTurn, required this.paid, this.received = false});
  final int id;
  String name;
  int members;
  int amount; // cents per member per month
  String start; // yyyy-mm of the first round
  int myTurn; // 1-based round when the user takes the pot
  final List<String> paid; // months (yyyy-mm) the user has paid
  bool received;
  int get pot => members * amount;
  String monthOf(int round) {
    final y = int.parse(start.substring(0, 4)), m = int.parse(start.substring(5, 7));
    final d = DateTime(y, m + round - 1);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  }
  int get paidIn => paid.length * amount;
  bool get finished => paid.length >= members;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'members': members, 'amount': amount, 'start': start, 'myTurn': myTurn, 'paid': paid, 'received': received};
  static Daret fromJson(Map<String, dynamic> j) => Daret(id: j['id'] as int, name: j['name'] as String, members: j['members'] as int, amount: j['amount'] as int,
      start: j['start'] as String, myTurn: j['myTurn'] as int, paid: List<String>.from(j['paid'] as List), received: (j['received'] ?? false) as bool);
}

const daretKey = 'daret_v1';
List<Daret> decodeDarets(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    return [for (final j in jsonDecode(raw) as List) Daret.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}
String encodeDarets(List<Daret> list) => jsonEncode([for (final d in list) d.toJson()]);

/// A quick add: one tap on Home records this expense today.
class QuickAdd {
  const QuickAdd(this.name, this.amount, this.category, this.wallet);
  final String name;
  final int amount;
  final String category;
  final String? wallet;
  Map<String, Object?> toJson() => {'name': name, 'amount': amount, 'category': category, 'wallet': wallet};
  static QuickAdd fromJson(Map<String, dynamic> j) => QuickAdd(j['name'] as String, j['amount'] as int, j['category'] as String, j['wallet'] as String?);
}

const quickAddKey = 'quick_adds_v1';
List<QuickAdd> decodeQuickAdds(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    return [for (final j in jsonDecode(raw) as List) QuickAdd.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}
String encodeQuickAdds(List<QuickAdd> list) => jsonEncode([for (final q in list) q.toJson()]);

const lastExpenseCategoryKey = 'last_expense_category';

/// Moroccan notes and coins for counting cash, in cents.
const cashDenominations = [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50];

/// Next date the bank takes a loan instalment, from today (today counts). Short months use their last day.
DateTime? nextInstalmentDate(Kridi k, DateTime now) {
  if (k.kind != 'loan' || k.payDay <= 0 || k.balance <= 0) return null;
  final today = DateTime(now.year, now.month, now.day);
  DateTime onMonth(int y, int m) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, k.payDay > last ? last : k.payDay);
  }
  final here = onMonth(today.year, today.month);
  return here.isBefore(today) ? onMonth(today.year, today.month + 1) : here;
}

/// Loans whose instalment is taken within [days] days (0 = today), soonest first.
List<(Kridi, DateTime)> instalmentsDueSoon(List<Kridi> all, DateTime now, {int days = 3}) {
  final today = DateTime(now.year, now.month, now.day);
  final out = <(Kridi, DateTime)>[];
  for (final k in all) {
    final next = nextInstalmentDate(k, now);
    if (next != null && next.difference(today).inDays <= days) out.add((k, next));
  }
  out.sort((a, b) => a.$2.compareTo(b.$2));
  return out;
}

/// Instalment dates the bank has taken since the loan was last checked, up to today, oldest first.
List<DateTime> instalmentsTaken(Kridi k, DateTime now) {
  if (k.kind != 'loan' || k.payDay <= 0 || k.monthly <= 0) return [];
  final today = DateTime(now.year, now.month, now.day);
  final from = DateTime.tryParse(k.autoThrough ?? '');
  if (from == null) return [];
  final out = <DateTime>[];
  var y = from.year, m = from.month;
  while (true) {
    final last = DateTime(y, m + 1, 0).day;
    final d = DateTime(y, m, k.payDay > last ? last : k.payDay);
    if (d.isAfter(today)) break;
    if (d.isAfter(from)) out.add(d);
    m++;
    if (m > 12) { m = 1; y++; }
  }
  return out;
}
