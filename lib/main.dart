import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'src/auth.dart';
import 'src/draft_store.dart';
import 'src/model.dart';
import 'src/sheets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaydayApp());
}

class PaydayApp extends StatelessWidget {
  const PaydayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Payday DEMO',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const PaydayScreen(),
  );
}

class PaydayScreen extends StatefulWidget {
  const PaydayScreen({super.key});
  @override
  State<PaydayScreen> createState() => _PaydayScreenState();
}

class _PaydayScreenState extends State<PaydayScreen> {
  final _auth = GoogleAuth();
  final _pending = PendingExpenses();
  late final _sheets = DemoSheets(_auth.token);
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();
  final _billId = TextEditingController();
  Timer? _timer;

  DateTime _date = DateTime.now();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<String> _categories = [];
  List<Transaction> _transactions = [];
  String? _category;
  String _message = '';
  bool _busy = false;
  bool _online = false;
  int _queued = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_busy && _online) _syncAll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sheets.close();
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    _billId.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _queued = (await _pending.all()).length;
      await _auth.initialize();
      if (_auth.account != null) {
        await _auth.token();
        _online = true;
        await _load();
        await _flush();
      }
    } catch (e) {
      _message = '$e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {_busy = true; _message = '';});
    try {
      await _auth.connect();
      _online = true;
      await _load();
      await _flush();
      _message = 'Connected to the Payday DEMO.';
    } catch (e) {
      _message = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    await _sheets.verifyHeaders();
    final categories = await _sheets.categories();
    final entries = await _sheets.transactions(_month);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _category = categories.contains(_category) ? _category : categories.first;
      _transactions = entries;
    });
  }

  Future<void> _refresh() async {
    if (_busy || !_online) return;
    setState(() => _busy = true);
    try {
      await _load();
      _message = 'DEMO data refreshed.';
    } catch (e) {
      _message = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _flush() async {
    final list = await _pending.all();
    _queued = list.length;
    for (final entry in list) {
      if (entry.account != _auth.account?.email) {
        throw StateError('A pending entry belongs to another Google account.');
      }
      await _sheets.save(entry);
      await _pending.removeConfirmed(entry.id);
      _queued--;
    }
    await _load();
    if (mounted) setState(() {});
  }

  Future<void> _syncAll() async {
    if (_busy || !_online) return;
    setState(() => _busy = true);
    try {
      await _flush();
      _message = 'All pending expenses verified in the DEMO.';
    } catch (e) {
      _message = '$e';
      _queued = (await _pending.all()).length;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_online || _category == null) return;
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0 || !amount.isFinite || amount > 1000000000) {
      setState(() => _message = 'Enter a positive amount.');
      return;
    }
    setState(() {_busy = true; _message = '';});
    try {
      final email = _auth.account?.email;
      if (email == null) throw StateError('Sign in first.');
      final draft = Expense(
        id: const Uuid().v4(),
        account: email,
        date: _date,
        category: _category!,
        amount: amount,
        description: _description.text.trim(),
        note: _note.text.trim(),
        billId: _billId.text.trim(),
      );
      await _pending.put(draft); // Write locally BEFORE any network request.
      _queued = (await _pending.all()).length;
      _amount.clear();
      _description.clear();
      _note.clear();
      _billId.clear();
      await _flush();
      _message = 'Expense saved and verified.';
    } catch (e) {
      // Preserve local queue after network failures or uncertain writes.
      _message = '$e';
      _queued = (await _pending.all()).length;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (value != null && mounted) setState(() => _date = value);
  }

  void _changeMonth(int amount) async {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);
    });
    if (_online) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final income = _transactions.where((t) => t.type == 'Income')
        .fold<double>(0, (s, t) => s + t.amount);
    final spent = _transactions.where((t) => t.type == 'Expense')
        .fold<double>(0, (s, t) => s + t.amount);
    final savings = _transactions.where((t) => t.type == 'Savings out')
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payday · DEMO'), actions: [
        IconButton(onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('DEMO ONLY · Google Sheets access is for testing. '
              'The outdated official tracker is never contacted.'),
          )),
          if (_message.isNotEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SelectableText(_message),
          ),
          if (!_online) ...[
            const SizedBox(height: 16),
            const Text('Connect your Google account to begin.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _connect,
              child: const Text('Sign in with Google')),
          ] else ...[
            Row(children: [
              IconButton(onPressed: _busy ? null : () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left)),
              Expanded(child: Text(
                '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge)),
              IconButton(onPressed: _busy ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right)),
            ]),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income: ${income.toStringAsFixed(2)} MAD'),
                  Text('Expenses: ${spent.toStringAsFixed(2)} MAD'),
                  Text('Savings transferred: ${savings.toStringAsFixed(2)} MAD'),
                  Text('Unallocated: ${(income - spent - savings).toStringAsFixed(2)} MAD'),
                  Text('Pending sync: $_queued'),
                ]),
            )),
            if (_queued > 0) FilledButton.tonal(
              onPressed: _busy ? null : _syncAll,
              child: Text('Verify & Sync ($_queued)'),
            ),
            const Divider(height: 36),
            Text('Add expense', style: Theme.of(context).textTheme.titleLarge),
            TextField(controller: _amount, enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Amount (MAD)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_category) ? _category : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) =>
                DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _busy ? null : (v) => setState(() => _category = v),
            ),
            TextButton.icon(onPressed: _busy ? null : _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text('${_date.day}/${_date.month}/${_date.year}')),
            TextField(controller: _description, maxLength: 150,
              decoration: const InputDecoration(labelText: 'Description (optional)')),
            TextField(controller: _note, maxLength: 150,
              decoration: const InputDecoration(labelText: 'Note (optional)')),
            TextField(controller: _billId, maxLength: 40,
              decoration: const InputDecoration(labelText: 'Bill ID (optional)')),
            FilledButton(onPressed: _busy ? null : _submit,
              child: const Text('Save expense to DEMO')),
            const Divider(height: 36),
            Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
            if (_transactions.isEmpty) const Text('No entries for this month.'),
            for (final t in _transactions.take(100))
              ListTile(
                title: Text(t.description.isEmpty ? t.category : t.description),
                subtitle: Text('${t.category} · ${t.date.day}/${t.date.month}/${t.date.year}'),
                trailing: Text('${t.type == 'Income' ? '+' : '-'}${t.amount.toStringAsFixed(2)} MAD'),
              ),
          ],
        ],
      ),
    );
  }
}
