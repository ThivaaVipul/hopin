import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/l10n/app_localizations.dart';
import 'package:hopin/l10n/time_left.dart';

void main() {
  test('time left in minutes, and in hours on a long trip', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.timeLeft(12), '12 min');
    expect(en.timeLeft(59), '59 min');
    expect(en.timeLeft(60), '1 h 0 min');
    expect(en.timeLeft(889), '14 h 49 min');
    final ta = lookupAppLocalizations(const Locale('ta'));
    expect(ta.timeLeft(889), '14 மணி 49 நிமி');
  });
}
