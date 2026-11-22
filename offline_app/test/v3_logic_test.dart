import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/v3_logic.dart';

void main() {
  test('amount sums work like a small calculator', () {
    expect(evalAmountCents('85+40'), 12500);
    expect(evalAmountCents('3×12,50'), 3750);
    expect(evalAmountCents('100−25.5'), 7450);
    expect(evalAmountCents('10+2*5'), 2000);
    expect(evalAmountCents('90÷3'), 3000);
    expect(evalAmountCents('12,50'), 1250);
    expect(evalAmountCents('5-10'), isNull);
    expect(evalAmountCents('5+'), isNull);
    expect(evalAmountCents('1/0'), isNull);
    expect(isAmountExpression('85+40'), isTrue);
    expect(isAmountExpression('85'), isFalse);
  });

  test('a Moroccan bank SMS gives the amount, the shop and the date', () {
    final m = parseBankMessage('CIH BANK: Paiement par carte de 349,00 MAD chez MAROC TELECOM le 21/11 à 14:02. Solde: 2 011,00 MAD',
        now: DateTime(2026, 11, 22))!;
    expect(m.amountCents, 34900);
    expect(m.merchant, 'Maroc Telecom');
    expect(m.income, isFalse);
    expect(m.date, DateTime(2026, 11, 21));
    final r = parseBankMessage('Virement reçu de 1 500,00 DH le 20/11/2026', now: DateTime(2026, 11, 22))!;
    expect(r.amountCents, 150000);
    expect(r.income, isTrue);
    expect(parseBankMessage('Bonjour, rendez-vous demain'), isNull);
  });

  test('bank CSV with Débit and Crédit columns', () {
    const csv = 'Date opération;Libellé;Débit;Crédit\n21/11/2026;MAROC TELECOM;349,00;\n20/11/2026;VIREMENT SALAIRE;;9 500,00\nbad;row;;\n';
    final rows = parseBankCsv(csv);
    expect(rows.length, 2);
    expect(rows[0].date, '2026-11-21');
    expect(rows[0].amountCents, 34900);
    expect(rows[0].income, isFalse);
    expect(rows[1].amountCents, 950000);
    expect(rows[1].income, isTrue);
  });

  test('CSV with one signed amount column', () {
    final rows = parseBankCsv('date,description,amount\n2026-11-02,Coffee,-15.00\n2026-11-03,Refund,1,234.50\n');
    expect(rows.first.amountCents, 1500);
    expect(rows.first.income, isFalse);
  });

  test('kridi balances, repayment share and JSON round trip', () {
    final loan = Kridi(id: 1, name: 'Car', kind: 'loan', monthly: 145000, months: 10, moves: [
      {'date': '2026-11-01', 'amount': 1450000, 'note': ''},
      {'date': '2026-11-05', 'amount': -145000, 'note': ''},
    ]);
    final lent = Kridi(id: 2, name: 'Karim', kind: 'lent', moves: [{'date': '2026-10-01', 'amount': 100000, 'note': ''}]);
    expect(loan.balance, 1305000);
    expect(loan.paidCount, 1);
    expect(lent.iOwe, isFalse);
    expect(repaymentShare([loan, lent], 950000), 15);
    final back = decodeKridi(encodeKridi([loan, lent]));
    expect(back.length, 2);
    expect(back.first.balance, 1305000);
    expect(decodeKridi('broken'), isEmpty);
  });

  test('daret months, pot and payments', () {
    final d = Daret(id: 1, name: 'Office', members: 10, amount: 100000, start: '2026-09', myTurn: 7, paid: ['2026-09', '2026-10']);
    expect(d.pot, 1000000);
    expect(d.monthOf(7), '2027-03');
    expect(d.paidIn, 200000);
    expect(d.finished, isFalse);
    expect(decodeDarets(encodeDarets([d])).first.monthOf(7), '2027-03');
  });

  test('quick adds survive a round trip', () {
    final q = decodeQuickAdds(encodeQuickAdds([const QuickAdd('Bread', 1200, 'Groceries', 'Cash')]));
    expect(q.single.name, 'Bread');
    expect(q.single.amount, 1200);
  });
}
