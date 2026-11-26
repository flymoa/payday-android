// Renders the main PAYDAY screens to PNG files so a design change can be
// looked at without a phone. Not part of the normal test run:
//   flutter test --update-goldens tool/previews/previews_test.dart
// Images are written to tool/previews/shots/.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/add_button.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';

class PreviewStore extends OfflineStore {
  @override
  Future<Map<String, List<RowData>>> snapshot() async => sample();
  @override
  Future<List<Map<String, Object?>>> table(String name) async => sample()[name] ?? [];
  @override
  Future<void> close() async {}
}

Map<String, List<RowData>> sample() {
  final now = DateTime.now();
  final m = monthKey(now);
  final today = dayKey(now), yesterday = dayKey(DateTime(now.year, now.month, now.day - 1));
  return {
    'transactions': [
      {'id': 1, 'date': '$m-01', 'type': 'Income', 'category': 'Salary', 'description': 'Monthly salary', 'amount': 1250000, 'note': '', 'bill_id': ''},
      {'id': 2, 'date': yesterday, 'type': 'Expense', 'category': 'Groceries', 'description': 'Marjane', 'amount': 64050, 'note': '', 'bill_id': ''},
      {'id': 3, 'date': today, 'type': 'Expense', 'category': 'Eating out', 'description': 'Lunch with Yassine', 'amount': 23500, 'note': '', 'bill_id': ''},
      {'id': 4, 'date': today, 'type': 'Expense', 'category': 'Transport', 'description': '', 'amount': 4000, 'note': '', 'bill_id': ''},
      {'id': 5, 'date': '$m-01', 'type': 'Expense', 'category': 'Housing', 'description': 'Rent', 'amount': 350000, 'note': '', 'bill_id': ''},
      {'id': 6, 'date': '$m-01', 'type': 'Savings out', 'category': 'Savings', 'description': '', 'amount': 100000, 'note': '', 'bill_id': ''},
    ],
    'budgets': [
      {'month': m, 'category': 'Income plan', 'amount': 1250000},
      {'month': m, 'category': 'Savings goal', 'amount': 150000},
      {'month': m, 'category': 'Housing', 'amount': 350000},
      {'month': m, 'category': 'Groceries', 'amount': 180000},
      {'month': m, 'category': 'Eating out', 'amount': 20000},
      {'month': m, 'category': 'Transport', 'amount': 60000},
    ],
    'categories': [
      {'name': 'Housing', 'group_name': 'Essential'},
      {'name': 'Groceries', 'group_name': 'Essential'},
      {'name': 'Transport', 'group_name': 'Essential'},
      {'name': 'Eating out', 'group_name': 'Flexible'},
      {'name': 'Leisure', 'group_name': 'Flexible'},
    ],
    'goals': [
      {'id': 1, 'name': 'Emergency fund', 'target': 2000000},
      {'id': 2, 'name': 'New laptop', 'target': 900000},
    ],
    'allocations': [
      {'id': 1, 'goal_id': 1, 'month': m, 'amount': 60000},
    ],
    'bills': [
      {'id': 1, 'code': 'NET', 'name': 'Internet', 'due': '$m-20', 'amount': 30000, 'category': 'Utilities', 'note': ''},
    ],
    'reserves': [
      {'id': 1, 'name': 'Eid al-Adha', 'target': 450000, 'funded': 260000, 'due': dayKey(DateTime(now.year + 1, 5, 15)), 'start_month': m},
    ],
    'reserve_movements': [],
    'month_closes': [],
    'settings': [
      {'key': 'wallet_setup', 'value': '{"cash":124000,"bank":986000,"after_id":99,"date":"$m-01"}'},
    ],
  };
}

Future<void> loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadFont('DMSans', 'assets/fonts/DMSans.ttf');
    await loadFont('PlexArabic', 'assets/fonts/IBMPlexSansArabic-Regular.ttf');
    await loadFont('Bricolage', 'assets/fonts/Bricolage.ttf');
  });
  for (final (mode, language) in [(ThemeMode.light, 'en'), (ThemeMode.dark, 'en'), (ThemeMode.light, 'fr'), (ThemeMode.dark, 'fr'), (ThemeMode.light, 'ar'), (ThemeMode.dark, 'ar')]) {
    testWidgets('render ${mode.name} $language previews', (t) async {
      t.view.physicalSize = const Size(780, 1688);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      debugDisableShadows = false;
      try {
        await t.pumpWidget(PaydayLocal(
            initialData: Future.value(sample()),
            store: PreviewStore(),
            preferencesWriter: (_) async {},
            initialPreferences: AppPreferences(appearance: mode, language: language)));
        await t.pumpAndSettle();
        Future<void> shot(String name) =>
            expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/${language == 'en' ? '' : '${language}_'}${mode.name}_$name.png'));
        await shot('1_home');
        await t.drag(find.byType(ListView).first, const Offset(0, -560));
        await t.pumpAndSettle();
        await shot('2_home_lower');
        for (final tab in [(2, '3_budgets'), (3, '4_savings'), (1, '5_records')]) {
          await t.tap(find.byKey(ValueKey('bottom-${tab.$1}')));
          await t.pumpAndSettle();
          await shot(tab.$2);
        }
        await t.tap(find.byKey(const ValueKey('bottom-2')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('subtab-2-1')));
        await t.pumpAndSettle();
        await shot('6_bills_tab');
        for (final tab in [(2, 2, '6b_recurring'), (3, 1, '6c_reserves'), (3, 4, '6d_cash_bank'), (3, 2, '6h_kridi'), (3, 3, '6i_daret'), (1, 3, '6e_review'), (1, 1, '6f_calendar'), (1, 2, '6g_reports')]) {
          await t.tap(find.byKey(ValueKey('bottom-${tab.$1}')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(ValueKey('subtab-${tab.$1}-${tab.$2}')));
          await t.pumpAndSettle();
          await shot(tab.$3);
          if (tab.$3 == '6e_review') {
            // The "Check before closing" card sits below the fold.
            await t.drag(find.byType(ListView).first, const Offset(0, -900));
            await t.pumpAndSettle();
            await shot('6e2_review_lower');
            await t.drag(find.byType(ListView).first, const Offset(0, 900));
            await t.pumpAndSettle();
          }
        }
        await t.tap(find.byKey(const ValueKey('bottom-0')));
        await t.pumpAndSettle();
        await t.tap(find.byType(PaydayAddButton));
        await t.pumpAndSettle();
        await shot('7_new_transaction');
        await t.tap(find.byKey(const ValueKey('close-transaction')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('home-settings-button')));
        await t.pumpAndSettle();
        await shot('8_settings');
      } finally {
        debugDisableShadows = true;
      }
    });
  }

  // Overspent month: safe to spend goes negative, to check how negative amounts read (RTL too).
  for (final (mode, language) in [(ThemeMode.light, 'en'), (ThemeMode.light, 'ar'), (ThemeMode.dark, 'ar')]) {
    testWidgets('render negative ${mode.name} $language previews', (t) async {
      t.view.physicalSize = const Size(780, 1688);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final data = sample();
      final m = monthKey(DateTime.now());
      data['transactions']!.add({'id': 7, 'date': '$m-02', 'type': 'Expense', 'category': 'Leisure', 'description': 'Voyage Marrakech', 'amount': 1100000, 'note': '', 'bill_id': ''});
      await t.pumpWidget(PaydayLocal(
          initialData: Future.value(data),
          store: PreviewStore(),
          preferencesWriter: (_) async {},
          initialPreferences: AppPreferences(appearance: mode, language: language)));
      await t.pumpAndSettle();
      Future<void> shot(String name) =>
          expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/${language == 'en' ? '' : '${language}_'}${mode.name}_$name.png'));
      await shot('9_negative_home');
      await t.tap(find.byKey(const ValueKey('home-hero')));
      await t.pumpAndSettle();
      await shot('9b_negative_details');
      await t.tapAt(const Offset(20, 40));
      await t.pumpAndSettle();
      for (final tab in [(2, '9c_negative_budgets'), (1, '9d_negative_records')]) {
        await t.tap(find.byKey(ValueKey('bottom-${tab.$1}')));
        await t.pumpAndSettle();
        await shot(tab.$2);
      }
    });
  }

  // Whole home screen in one tall image, in all three languages.
  for (final mode in [ThemeMode.light, ThemeMode.dark])
  for (final language in ['en', 'fr', 'ar']) {
    testWidgets('render full home ${mode.name} $language', (t) async {
      t.view.physicalSize = const Size(780, 2560);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(PaydayLocal(
          initialData: Future.value(sample()),
          store: PreviewStore(),
          preferencesWriter: (_) async {},
          initialPreferences: AppPreferences(appearance: mode, language: language)));
      await t.pumpAndSettle();
      final dark = mode == ThemeMode.dark ? '_dark' : '';
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/home_full_$language$dark.png'));
    });
  }

  // Budgets "left to spend" card: plenty, not much left (< 100 DH a day), all spent — in all three languages.
  for (final mode in [ThemeMode.light, ThemeMode.dark])
  for (final language in ['en', 'fr', 'ar']) {
    for (final (state, groceries, transport) in [('plenty', 0, 0), ('low', 115950, 50000), ('empty', 115950, 56000)]) {
      testWidgets('render budget card ${mode.name} $state $language', (t) async {
        t.view.physicalSize = const Size(780, 1688);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final data = sample();
        final m = monthKey(DateTime.now());
        if (groceries > 0) data['transactions']!.add({'id': 20, 'date': '$m-03', 'type': 'Expense', 'category': 'Groceries', 'description': '', 'amount': groceries, 'note': '', 'bill_id': ''});
        if (transport > 0) data['transactions']!.add({'id': 21, 'date': '$m-03', 'type': 'Expense', 'category': 'Transport', 'description': '', 'amount': transport, 'note': '', 'bill_id': ''});
        await t.pumpWidget(PaydayLocal(
            initialData: Future.value(data),
            store: PreviewStore(),
            preferencesWriter: (_) async {},
            initialPreferences: AppPreferences(appearance: mode, language: language)));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('bottom-2')));
        await t.pumpAndSettle();
        final dark = mode == ThemeMode.dark ? '_dark' : '';
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/budget_card_${language}_$state$dark.png'));
      });
    }
  }
}
