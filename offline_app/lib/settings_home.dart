import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'localization.dart';

/// Settings opens as its own full page, like a normal app, from the button
/// next to More. [refresh] rebuilds it when preferences or records change.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key, required this.refresh, required this.builder});
  final Listenable refresh;
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
              tooltip: tr(context, 'Close settings'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const PaydayAppIcon(Icons.arrow_back)),
          title: LText('Settings', style: TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w800, fontSize: 24)),
        ),
        body: SafeArea(
            child: ListenableBuilder(
                listenable: refresh,
                builder: (context, _) => ListView(
                    key: const ValueKey('settings-list'),
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 32),
                    children: [builder(context)]))),
      );
}
