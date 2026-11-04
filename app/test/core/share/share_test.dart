import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/share/share.dart';
import 'package:hopin/core/share/shares.dart';

void main() {
  test("a share's id is long, plain and new each time", () {
    final ids = {for (var i = 0; i < 50; i++) newShareId()};
    expect(ids, hasLength(50));
    for (final id in ids) {
      // As firebase/firestore.rules takes them.
      expect(id, matches(RegExp(r'^[A-Za-z0-9]{20,40}$')));
    }
    expect(newShareId(Random(1)), newShareId(Random(1)));
    expect(shareLink('abc'), 'https://hopin-riders.web.app/r/abc');
  });

  group('the pace of a share', () {
    const here = GeoPoint(6.9101, 79.8523);
    final t0 = DateTime.utc(2026, 1, 1, 8);
    GeoPoint north(double metres) =>
        GeoPoint(here.lat + metres / 111195, here.lng);

    test('writes at once, then every 10 s while moving', () {
      final pacer = SharePacer();
      expect(pacer.due(here, t0), isTrue);
      pacer.sent(here, t0);
      final soon = t0.add(const Duration(seconds: 5));
      expect(pacer.due(north(60), soon), isFalse);
      final later = t0.add(const Duration(seconds: 10));
      expect(pacer.due(north(60), later), isTrue);
    });

    test('once a minute while halted', () {
      final pacer = SharePacer()..sent(here, t0);
      expect(pacer.due(north(5), t0.add(const Duration(seconds: 30))), isFalse);
      expect(pacer.due(north(5), t0.add(const Duration(minutes: 1))), isTrue);
    });
  });

  group('a share as Home reads it', () {
    test('with its position, stop and time left', () {
      final share = liveShareFrom('s1', {
        'uid': 'r2',
        'lat': 6.9101,
        'lng': 79.8523,
        'toName': 'Fort',
        'toTa': 'கோட்டை',
        'toLat': 6.9344,
        'toLng': 79.8501,
        'leftMin': 12,
        'metresLeft': 2400,
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1, 8)),
      })!;
      expect(share.uid, 'r2');
      expect(share.at, const GeoPoint(6.9101, 79.8523));
      expect(share.goal?.name, 'Fort');
      expect(share.goal?.nameTa, 'கோட்டை');
      expect(share.goal?.minutesLeft, 12);
      expect(share.goal?.metresLeft, 2400);
      expect(share.updatedAt?.toUtc(), DateTime.utc(2026, 1, 1, 8));
    });

    test('a noticed ride has no stop; a stranger document is none', () {
      final share = liveShareFrom('s1', {
        'uid': 'r2',
        'lat': null,
        'lng': null,
        'toName': null,
        'toLat': null,
        'toLng': null,
      })!;
      expect(share.at, isNull);
      expect(share.goal, isNull);
      expect(liveShareFrom('s2', {'lat': 6.9}), isNull);
    });
  });
}
