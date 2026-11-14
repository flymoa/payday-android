import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';

class RetryGoalStore extends OfflineStore {
  int attempts = 0;
  String? savedName;
  @override
  Future<Map<String, List<RowData>>> snapshot() async => {};
  @override
  Future<void> saveGoal({int? id, required String name, required int target}) async {
    attempts++;
    if (attempts == 1) throw StateError('Storage temporarily unavailable');
    savedName = name;
  }
  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('failed goal save preserves form values and allows retry', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = RetryGoalStore();
    await tester.pumpWidget(MaterialApp(home: FinanceScreen(
      store: store, initialData: Future.value(<String, List<RowData>>{}))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Savings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Goal name'), 'Emergency fund');
    await tester.enterText(find.widgetWithText(TextField, 'Target (MAD)'), '5000');
    final save = find.widgetWithText(FilledButton, 'Save goal');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(store.attempts, 1);
    expect(find.text('Add savings goal'), findsOneWidget);
    expect(find.text('Emergency fund'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(store.attempts, 2);
    expect(store.savedName, 'Emergency fund');
    expect(find.text('Add savings goal'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
