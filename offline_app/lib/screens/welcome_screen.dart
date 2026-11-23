// First open: a welcome page, then a few quick choices (language, currency,
// expected income). Shown once, only on a phone with no records yet.
// ignore_for_file: invalid_use_of_protected_member
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

  /// One setup choice: a label and its pills, directly on the page. Spacing, not
  /// boxes, separates the choices. [raw]: option labels are shown as written
  /// (each language in its own name, whatever language the app is in).
  Widget choice(String title, List<(String, String)> options, String current, ValueChanged<String> pick, {bool raw = false}) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: PaydaySpace.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LText(title, style: const TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w800, fontSize: PaydayType.section)),
        const SizedBox(height: PaydaySpace.xs),
        Wrap(spacing: PaydaySpace.sm, children: [
          for (final o in options) PaydayPill(key: ValueKey('welcome-${o.$1}'), label: o.$2, raw: raw, selected: current == o.$1, onTap: () => pick(o.$1)),
        ]),
      ]));

  Future<void> start() async {
    setState(() => busy = true);
    final cents = parseMoneyCents(income.text);
    await widget.onFinish(cents, wallets);
    if (mounted) setState(() => busy = false);
  }

  /// The tagline as a poster: display size, start-aligned. If one word of a
  /// translation is wider than the screen ("aujourd’hui,"), the size steps down
  /// just enough for that word, never below the title size.
  Widget headline(String text, Color color) => LayoutBuilder(builder: (context, box) {
        final arabic = widget.preferences.language == 'ar';
        TextStyle style(double size) => TextStyle(fontFamily: arabic ? 'PlexArabic' : 'Bricolage', fontSize: size,
            fontWeight: arabic ? FontWeight.w700 : FontWeight.w800, height: arabic ? 1.3 : 1.0, letterSpacing: arabic ? 0 : -1.5, color: color);
        final scaler = MediaQuery.textScalerOf(context);
        final widest = text.split(' ').map((w) => (TextPainter(text: TextSpan(text: w, style: style(PaydayType.display)),
            textDirection: Directionality.of(context), textScaler: scaler)..layout()).width).fold<double>(0, (a, b) => a > b ? a : b);
        final size = widest <= box.maxWidth ? PaydayType.display
            : (PaydayType.display * box.maxWidth / widest).clamp(PaydayType.title, PaydayType.display).toDouble();
        return Text(text, style: style(size));
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final prefs = widget.preferences;
    if (step == 0) {
      // Left-aligned like a printed page: the mark at the top-start corner, then
      // the tagline as the headline, one sentence, and the two buttons at the thumb.
      return Scaffold(body: SafeArea(child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(PaydaySpace.xl, PaydaySpace.xl, PaydaySpace.xl, PaydaySpace.lg + PaydaySpace.xs),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PaydayMark(size: 56),
            Expanded(child: Align(alignment: AlignmentDirectional.bottomStart, child: SingleChildScrollView(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              headline(translateMessage(paydaySlogan, prefs.language), dark ? PaydayColors.darkText : PaydayColors.ink),
              const SizedBox(height: PaydaySpace.lg),
              LText('Your money stays on this phone. No account.', style: TextStyle(fontSize: PaydayType.body, color: scheme.onSurfaceVariant)),
              const SizedBox(height: PaydaySpace.xl + PaydaySpace.lg),
            ])))),
            SizedBox(width: double.infinity, child: FilledButton(key: const ValueKey('welcome-start'),
                onPressed: () => setState(() => step = 1), child: LText('Get started'))),
            const SizedBox(height: PaydaySpace.sm),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(key: const ValueKey('welcome-restore'),
                onPressed: busy ? null : widget.onRestore, icon: const PaydayAppIcon(Icons.file_open), label: LText('Restore a backup'))),
          ]))));
    }
    final unit = currencyLabel(prefs.currency, prefs.language);
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) {
      if (!didPop) setState(() => step = 0);
    }, child: Scaffold(
      appBar: AppBar(leading: IconButton(tooltip: translateMessage('Back', prefs.language), onPressed: () => setState(() => step = 0),
          icon: const PaydayAppIcon(Icons.arrow_back)),
          title: LText('Set up Payday', style: const TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w800, fontSize: PaydayType.title))),
      body: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsetsDirectional.fromSTEB(PaydaySpace.lg + PaydaySpace.xs, 0, PaydaySpace.lg + PaydaySpace.xs, PaydaySpace.lg), children: [
          Padding(padding: const EdgeInsets.only(bottom: PaydaySpace.xl),
              child: LText('A few quick choices. You can change them later.', style: TextStyle(color: scheme.onSurfaceVariant))),
          choice('Language', [for (final l in paydayLanguages.entries) (l.key, l.value)], prefs.language,
              (v) => widget.onPreferences(prefs.copyWith(language: v)), raw: true),
          choice('Currency', [for (final c in paydayCurrencies.keys) (c, c)], prefs.currency,
              (v) => widget.onPreferences(prefs.copyWith(currency: v)), raw: true),
          TextField(key: const ValueKey('welcome-income'), controller: income,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: PaydayType.body, fontFeatures: PaydayText.tabular),
              decoration: InputDecoration(labelText: translateMessage('Monthly income', prefs.language),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: localizedNumber(0, prefs.language), suffixText: unit,
                  helperText: translateMessage('Salary and any regular income. Used to plan your budgets.', prefs.language), helperMaxLines: 2)),
          const SizedBox(height: PaydaySpace.xl),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LText('Track Cash & Bank separately', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              LText('Optional. You can turn it on later in Money > Wallets.', style: TextStyle(fontSize: PaydayType.caption, color: scheme.onSurfaceVariant)),
            ])),
            const SizedBox(width: PaydaySpace.md),
            Switch(key: const ValueKey('welcome-wallets'), value: wallets, onChanged: (v) => setState(() => wallets = v)),
          ]),
        ])),
        Padding(padding: const EdgeInsetsDirectional.fromSTEB(PaydaySpace.lg + PaydaySpace.xs, PaydaySpace.sm, PaydaySpace.lg + PaydaySpace.xs, PaydaySpace.lg), child: SizedBox(width: double.infinity,
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
