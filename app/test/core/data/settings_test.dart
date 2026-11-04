import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/app_settings.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/data/settings_sync.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';

import '../../helpers/fakes.dart';

void main() {
  late HopinDatabase db;
  late SettingsStore store;
  late AppSettings settings;
  late FakeRemote remote;
  late SettingsSync sync;
  const collection = 'people/r1/settings';

  setUp(() {
    db = memoryDatabase();
    store = SettingsStore(db);
    settings = AppSettings(store);
    remote = FakeRemote();
    sync = SettingsSync(settings, store, remote, 'r1');
    settings.onChange = sync.push;
  });

  tearDown(() async {
    await sync.stop();
    await db.close();
  });

  test('starts in English with the default stages', () async {
    expect(await settings.language(), 'en');
    expect(await settings.stages(), defaultStages);
  });

  test('sorts stages, one per distance, three at most', () async {
    await settings.setStages(const [
      GuideStage(300, AlertPattern.tripleKnock),
      GuideStage(3000, AlertPattern.waves),
      GuideStage(1000, AlertPattern.heartbeat),
      GuideStage(1000, AlertPattern.rising),
      GuideStage(150, AlertPattern.gentleDoubleTap),
    ]);
    expect(await settings.stages(), const [
      GuideStage(3000, AlertPattern.waves),
      GuideStage(1000, AlertPattern.rising),
      GuideStage(300, AlertPattern.tripleKnock),
    ]);

    await settings.setStages(const [GuideStage(450, AlertPattern.waves)]);
    expect(await settings.stages(), hasLength(3), reason: 'no known distance');
  });

  test('sends a change, then forgets it is pending', () async {
    await sync.start();
    await settings.setLanguage('ta');
    await sync.push();
    final (path, data, _) = remote.puts.single;
    expect(path, '$collection/app');
    expect(data['language'], 'ta');
    expect(data['stages'], [for (final stage in defaultStages) stage.toJson()]);
    expect(data.containsKey('deletedAt'), isFalse);
    expect(await store.read(AppSettings.pendingKey), isNull);
  });

  test('keeps a change pending while offline, and sends it later', () async {
    await sync.start();
    remote.offline = true;
    final errors = <Object>[];
    sync.onError = (error, _) => errors.add(error);
    await settings.setLanguage('ta');
    await sync.push();
    expect(errors, hasLength(1));
    expect(await store.read(AppSettings.pendingKey), isNotNull);

    remote.offline = false;
    await sync.push();
    expect(remote.puts.single.$2['language'], 'ta');
    expect(await store.read(AppSettings.pendingKey), isNull);
  });

  test('takes the server\'s settings, as after a reinstall', () async {
    await sync.start();
    remote.push(collection, [
      const RemoteDoc('app', {
        'language': 'ta',
        'stages': [
          {'metres': 700, 'pattern': 'heartbeat'},
        ],
      }, 5),
    ]);
    await pumpEventQueue();
    expect(await settings.language(), 'ta');
    expect(await settings.stages(), const [
      GuideStage(700, AlertPattern.heartbeat),
    ]);
    expect(await store.read('cursor.settings'), '5');
  });

  test('a change still going up wins over the server', () async {
    await sync.start();
    remote.offline = true;
    await settings.setLanguage('ta');
    remote.push(collection, [
      const RemoteDoc('app', {'language': 'en', 'stages': []}, 9),
    ]);
    await pumpEventQueue();
    expect(await settings.language(), 'ta');
  });

  test('watches the saved language, none until chosen', () async {
    final seen = <String?>[];
    final watching = settings.watchLanguage().listen(seen.add);
    await pumpEventQueue();
    await settings.setLanguage('ta');
    await pumpEventQueue();
    expect(seen, [null, 'ta']);
    await watching.cancel();
  });
}
