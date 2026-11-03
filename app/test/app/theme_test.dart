import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/theme.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', HopinColors.light),
    ('dark', HopinColors.dark),
  ]) {
    group('$name colours are readable', () {
      // WCAG AA: 4.5 for text, 7 where it carries the main reading load.
      test('text on the board', () {
        expect(contrast(c.onBoard, c.board), greaterThanOrEqualTo(7));
        expect(contrast(c.onBoardMuted, c.board), greaterThanOrEqualTo(4.5));
        expect(contrast(c.amber, c.board), greaterThanOrEqualTo(7));
      });

      test('text on the page', () {
        expect(contrast(c.ink, c.page), greaterThanOrEqualTo(7));
        expect(contrast(c.inkMuted, c.page), greaterThanOrEqualTo(4.5));
      });

      test('text on amber, at the alert', () {
        expect(contrast(c.onAmber, c.amber), greaterThanOrEqualTo(7));
      });
    });
  }

  test('the theme carries the Board colours and motion', () {
    for (final brightness in Brightness.values) {
      final theme = hopinTheme(brightness);
      expect(
        theme.extension<HopinColors>(),
        brightness == Brightness.light ? HopinColors.light : HopinColors.dark,
      );
      expect(theme.extension<HopinMotion>(), isNotNull);
      expect(theme.textTheme.displayLarge?.fontFamily, 'Barlow Semi Condensed');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Barlow');
      expect(
        theme.textTheme.bodyLarge?.fontFamilyFallback,
        contains(sinhalaFamily),
      );
    }
  });
}
