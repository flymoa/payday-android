import 'package:flutter/material.dart';
import 'localization.dart';
import 'settings_pages.dart';

/// Settings opens as its own full page, like a normal app, from the button
/// next to More. [refresh] rebuilds it when preferences or records change.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key, required this.refresh, required this.builder, this.title = 'Settings', this.closeTooltip = 'Close settings', this.listKey = 'settings-list'});
  final Listenable refresh;
  final String title, closeTooltip, listKey;
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          centerTitle: false,
          titleSpacing: 12,
          leadingWidth: 56,
          leading: SettingsBackButton(tooltip: closeTooltip, onPressed: () => Navigator.of(context).maybePop()),
          title: LText(title, style: TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w800, fontSize: 24)),
        ),
        body: SafeArea(
            child: ListenableBuilder(
                listenable: refresh,
                builder: (context, _) => ListView(
                    key: ValueKey(listKey),
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 32),
                    children: [builder(context)]))),
      );
}
