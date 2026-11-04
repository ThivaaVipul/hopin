import 'dart:async';

import 'package:hopin/core/data/app_settings.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/data/remote/remote.dart';

/// Keeps [AppSettings] and the rider's private settings document,
/// `people/{uid}/settings/app`, in step: a change here goes up, the server's
/// comes down unless one from here is still pending (like places).
class SettingsSync {
  SettingsSync(this._settings, this._store, this._remote, this._uid);

  final AppSettings _settings;
  final SettingsStore _store;
  final Remote _remote;
  final String _uid;
  StreamSubscription<List<RemoteDoc>>? _subscription;
  Future<void>? _running;
  bool _pushAgain = false;

  static const _cursorKey = 'cursor.settings';

  /// Changes are read from a minute before the cursor, so a write the server
  /// stamped late is not missed.
  static const _margin = 60 * 1000 * 1000;

  /// Told about uploads that failed; the change stays pending.
  void Function(Object error, StackTrace stack)? onError;

  String get _collection => 'people/$_uid/settings';

  Future<void> start() async {
    if (_subscription != null) return;
    final cursor = int.tryParse(await _store.read(_cursorKey) ?? '') ?? 0;
    _subscription = _remote
        .changes(_collection, cursor == 0 ? 0 : cursor - _margin)
        .listen(
          (docs) => unawaited(_apply(docs)),
          // Refused (rules) or dropped: told, not thrown; the next start
          // listens again.
          onError: (Object error, StackTrace stack) {
            onError?.call(error, stack);
            unawaited(_subscription?.cancel());
            _subscription = null;
          },
        );
    await push();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Sends a pending change. A call while one is going up makes it go round
  /// once more, and waits for it.
  Future<void> push() {
    if (_subscription == null) return Future.value();
    final running = _running;
    if (running != null) {
      _pushAgain = true;
      return running;
    }
    return _running = _upload().whenComplete(() => _running = null);
  }

  Future<void> _upload() async {
    do {
      _pushAgain = false;
      final pending = await _store.read(AppSettings.pendingKey);
      if (pending == null) return;
      try {
        await _remote.put('$_collection/app', {
          'language': await _settings.language(),
          'stages': [for (final s in await _settings.stages()) s.toJson()],
        });
      } on Object catch (error, stack) {
        onError?.call(error, stack);
        return;
      }
      if (await _store.read(AppSettings.pendingKey) == pending) {
        await _store.remove(AppSettings.pendingKey);
      }
    } while (_pushAgain);
  }

  Future<void> _apply(List<RemoteDoc> docs) async {
    var newest = int.tryParse(await _store.read(_cursorKey) ?? '') ?? 0;
    for (final doc in docs) {
      if (doc.updatedAt > newest) newest = doc.updatedAt;
      if (doc.id != 'app') continue;
      await _settings.take(
        language: doc.data['language'],
        stages: doc.data['stages'],
      );
    }
    await _store.write(_cursorKey, '$newest');
  }
}
