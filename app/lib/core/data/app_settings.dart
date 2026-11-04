import 'dart:convert';

import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/ride/guide.dart';

/// The rider's choices that follow their account (docs/PLAN.md, Settings and
/// updates): the app's language and the alert stages. Kept in this phone's
/// settings first and marked pending until the settings sync has sent them.
class AppSettings {
  AppSettings(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SettingsStore _store;
  final DateTime Function() _clock;

  static const languageKey = 'app.language';
  static const stagesKey = 'app.stages';
  static const pendingKey = 'app.pending';
  static const languages = ['en', 'ta'];

  /// Called after every change (the settings sync sends it).
  void Function()? onChange;

  /// The saved language; null until the rider chooses one.
  Stream<String?> watchLanguage() => _store
      .watch(languageKey)
      .map((code) => languages.contains(code) ? code : null);

  Stream<List<GuideStage>> watchStages() =>
      _store.watch(stagesKey).map(_stages);

  Future<String> language() async => _language(await _store.read(languageKey));

  Future<List<GuideStage>> stages() async =>
      _stages(await _store.read(stagesKey));

  Future<void> setLanguage(String code) async {
    if (!languages.contains(code)) return;
    await _change(languageKey, code);
  }

  Future<void> setStages(List<GuideStage> stages) async {
    final tidy = tidyStages(stages);
    if (tidy.isEmpty) return;
    await _change(stagesKey, jsonEncode([for (final s in tidy) s.toJson()]));
  }

  /// What the server says, unless a change here is still going up.
  Future<void> take({Object? language, Object? stages}) async {
    if (await _store.read(pendingKey) != null) return;
    if (language is String && languages.contains(language)) {
      await _store.write(languageKey, language);
    }
    if (stages is List) {
      final tidy = stagesFromJson(stages);
      await _store.write(
        stagesKey,
        jsonEncode([for (final s in tidy) s.toJson()]),
      );
    }
  }

  Future<void> _change(String key, String value) async {
    await _store.write(key, value);
    await _store.write(pendingKey, '${_clock().microsecondsSinceEpoch}');
    onChange?.call();
  }

  static String _language(String? code) =>
      languages.contains(code) ? code! : 'en';

  static List<GuideStage> _stages(String? json) {
    if (json == null) return defaultStages;
    try {
      return stagesFromJson(jsonDecode(json));
    } on FormatException {
      return defaultStages;
    }
  }
}
