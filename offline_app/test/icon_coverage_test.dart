import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/canvas_icons.dart';

// Every Material icon the app references must have a real drawing: either a
// design-canvas glyph or a case in the app's own painter (app_icon.dart).
// Anything else falls through to a lone placeholder dot on screen.
void main() {
  test('no icon falls back to the placeholder dot', () {
    final canvas = File('lib/canvas_icons.dart').readAsStringSync();
    final glyphMap = canvas.substring(canvas.indexOf('String? canvasGlyphForIcon'));
    final drawn = {
      ...RegExp(r'Icons\.(\w+):').allMatches(glyphMap).map((m) => m.group(1)!),
      ...RegExp(r'Icons\.(\w+)').allMatches(File('lib/app_icon.dart').readAsStringSync()).map((m) => m.group(1)!),
    };
    // circle_outlined is the deliberate neutral default of tile(): a ring with a dot.
    const allowed = {'circle_outlined'};
    final missing = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final source = f.readAsStringSync();
      if (f.path.endsWith('canvas_icons.dart') || f.path.endsWith('app_icon.dart')) continue;
      for (final m in RegExp(r'Icons\.(\w+)').allMatches(source)) {
        final name = m.group(1)!;
        if (allowed.contains(name) || drawn.contains(name)) continue;
        missing.add('$name (${f.path})');
      }
    }
    for (final icon in [Icons.widgets_outlined, Icons.delete_outline, Icons.table_chart_outlined]) {
      expect(canvasGlyphForIcon(icon), isNotNull);
    }
    expect(missing, isEmpty, reason: 'unmapped icons draw a placeholder dot: $missing');
  });
}
