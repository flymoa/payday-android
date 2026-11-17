// First open: a welcome page, then three quick choices (language, currency,
// expected income). Shown once, only on a phone with no records yet.
part of '../main.dart';

class _WelcomeFlow extends StatefulWidget {
  const _WelcomeFlow({required this.preferences, required this.onPreferences, required this.onFinish, required this.onRestore});
  final AppPreferences preferences;
  final Future<void> Function(AppPreferences) onPreferences;
  final Future<void> Function(int? incomeCents, bool wallets) onFinish;
  final Future<void> Function() onRestore;
  @override
  State<_WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<_WelcomeFlow> {
  var step = 0;
  var wallets = false;
  var busy = false;
  final income = TextEditingController();
  @override
  void dispose() {
    income.dispose();
    super.dispose();
  }

  Widget point(IconData icon, String text, ColorScheme scheme, bool dark) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: dark ? PaydayColors.darkIconDisc : PaydayColors.mintTint, borderRadius: BorderRadius.circular(PaydayRadius.md)),
            child: Center(child: PaydayAppIcon(icon, size: 19))),
        const SizedBox(width: 12),
        Expanded(child: LText(text, style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface))),
      ]));

  Widget choice(String title, List<(String, String)> options, String current, ValueChanged<String> pick) => PaydayPanel(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LText(title, style: const TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in options) PaydayPill(key: ValueKey('welcome-${o.$1}'), label: o.$2, selected: current == o.$1, onTap: () => pick(o.$1)),
        ]),
      ]));

  Future<void> start() async {
    setState(() => busy = true);
    final cents = parseMoneyCents(income.text);
    await widget.onFinish(cents, wallets);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final prefs = widget.preferences;
    if (step == 0) {
      return Scaffold(body: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(children: [
            Expanded(child: Center(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const PaydayMark(size: 96),
              const SizedBox(height: 18),
              LText('Payday', style: TextStyle(fontFamily: 'Bricolage', fontSize: 40, fontWeight: FontWeight.w800,
                  color: dark ? PaydayColors.darkPrimary : PaydayColors.emerald)),
              const SizedBox(height: 6),
              LText(paydaySlogan, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 28),
              PaydayPanel(child: Column(children: [
                point(Icons.lock_outline, 'Your money stays on this phone. No account.', scheme, dark),
                point(Icons.pie_chart_outline, 'Give every dirham a job before the month starts.', scheme, dark),
                point(Icons.beach_access_outlined, 'Put money aside for Eid, Ramadan and the rentrée.', scheme, dark),
              ])),
            ])))),
            SizedBox(width: double.infinity, child: FilledButton(key: const ValueKey('welcome-start'),
                onPressed: () => setState(() => step = 1), child: LText('Get started'))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(key: const ValueKey('welcome-restore'),
                onPressed: busy ? null : widget.onRestore, icon: const PaydayAppIcon(Icons.download_outlined), label: LText('Restore a backup'))),
          ]))));
    }
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) {
      if (!didPop) setState(() => step = 0);
    }, child: Scaffold(
      appBar: AppBar(leading: IconButton(tooltip: translateMessage('Back', prefs.language), onPressed: () => setState(() => step = 0),
          icon: const PaydayAppIcon(Icons.arrow_back)),
          title: LText('Set up Payday', style: const TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w800, fontSize: 24))),
      body: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          Padding(padding: const EdgeInsets.only(bottom: 14),
              child: LText('Three quick choices. You can change them later.', style: TextStyle(color: scheme.onSurfaceVariant))),
          choice('Language', const [('en', 'English'), ('fr', 'Français'), ('ar', 'العربية')], prefs.language,
              (v) => widget.onPreferences(prefs.copyWith(language: v))),
          choice('Currency', [for (final c in paydayCurrencies.keys) (c, c)], prefs.currency,
              (v) => widget.onPreferences(prefs.copyWith(currency: v))),
          PaydayPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(key: const ValueKey('welcome-income'), controller: income,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: translateMessage('Income you expect each month ({0})', prefs.language).replaceAll('{0}', prefs.currency),
                    helperText: translateMessage('Salary and any regular income. Used to plan your budgets.', prefs.language), helperMaxLines: 2)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LText('Track Cash & Bank separately', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                LText('Optional. You can turn it on later in Savings.', style: TextStyle(fontSize: PaydayType.caption, color: scheme.onSurfaceVariant)),
              ])),
              Switch(key: const ValueKey('welcome-wallets'), value: wallets, onChanged: (v) => setState(() => wallets = v)),
            ]),
          ])),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 16), child: SizedBox(width: double.infinity,
            child: FilledButton(key: const ValueKey('welcome-finish'), onPressed: busy ? null : start, child: LText('Start using Payday')))),
      ])),
    ));
  }
}

extension _Welcome on _FinanceState {
  /// A phone with nothing recorded and no welcome shown before.
  bool firstRun(Map<String, List<RowData>> d) =>
      Ledger(d).setting('onboarding_done') == null &&
      ['transactions', 'budgets', 'goals', 'bills', 'reserves'].every((t) => list(d, t).isEmpty);

  Widget welcomeFlow() => _WelcomeFlow(
        preferences: widget.preferences,
        onPreferences: (p) async {
          await widget.onPreferencesChanged?.call(p);
        },
        onRestore: () async {
          await importBackup();
          final d = await store.snapshot();
          if (mounted && !firstRun(d)) {
            await store.setSetting('onboarding_done', '1');
            setState(() => welcome = false);
          }
        },
        onFinish: (income, wallets) async {
          final ok = await execute(() async {
            if (income != null && income > 0) await store.setBudget(monthKey(DateTime.now()), 'Income plan', income);
            await store.setSetting('onboarding_done', '1');
          }, saved: 'Welcome to Payday.');
          if (!ok || !mounted) return;
          setState(() => welcome = false);
          if (wallets) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(walletSetupForm(null));
            });
          }
        },
      );
}
