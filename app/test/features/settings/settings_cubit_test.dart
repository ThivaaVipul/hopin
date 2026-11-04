import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/features/settings/cubit/settings_cubit.dart';

import '../../helpers/fakes.dart';

const fort = Destination(point: GeoPoint(6.9344, 79.8501));

void main() {
  late Workspace workspace;
  late FakeGuide guide;

  setUp(() {
    workspace = Workspace('r1', memoryDatabase(), FakeRemote());
    guide = FakeGuide()..notifications = true;
  });

  tearDown(() => workspace.close());

  Future<SettingsCubit> started() async {
    final settings = SettingsCubit(workspace, guide);
    await settings.start();
    await pumpEventQueue();
    return settings;
  }

  test('shows the phone as it is', () async {
    final settings = await started();
    expect(settings.state.notificationsOn, isTrue);
    expect(settings.state.runsInBackground, isFalse);
    expect(settings.state.maker, PhoneMaker.xiaomi);

    guide.background = true;
    await settings.checkPhone();
    expect(settings.state.runsInBackground, isTrue);
    await settings.close();
  });

  test('reorders places where they were dropped', () async {
    for (final name in ['A', 'B', 'C']) {
      await workspace.places.add(fort, name: name, kind: PlaceKind.other);
    }
    final settings = await started();
    await settings.reorder(2, 0);
    await pumpEventQueue();
    expect(settings.state.places.map((p) => p.name), ['C', 'A', 'B']);
    await settings.reorder(0, 2);
    await pumpEventQueue();
    expect(settings.state.places.map((p) => p.name), ['A', 'B', 'C']);
    await settings.close();
  });

  test('edits, adds and removes stages, keeping at least one', () async {
    final settings = await started();
    expect(settings.state.stages, defaultStages);

    await settings.saveStage(1, const GuideStage(700, AlertPattern.waves));
    await settings.saveStage(null, settings.nextStage());
    await pumpEventQueue();
    expect(settings.state.stages, const [
      GuideStage(3000, AlertPattern.gentleDoubleTap),
      GuideStage(1500, AlertPattern.gentleDoubleTap),
      GuideStage(700, AlertPattern.waves),
    ]);

    await settings.removeStage(0);
    await settings.removeStage(0);
    await settings.removeStage(0);
    await pumpEventQueue();
    expect(settings.state.stages, const [GuideStage(700, AlertPattern.waves)]);
    await settings.close();
  });

  test('tries a pattern as the alert plays it', () async {
    final settings = await started();
    await settings.tryPattern(AlertPattern.heartbeat);
    expect(
      guide.played.single.length,
      AlertPattern.heartbeat.buzz.repeated(2).length,
    );
    await settings.close();
  });

  test('opens the app settings when notifications stay off', () async {
    guide
      ..notifications = false
      ..allowOnAsk = false;
    final settings = await started();
    await settings.turnOnNotifications();
    expect(guide.notificationAsks, 1);
    expect(guide.appSettingsOpened, 1);
    await settings.close();
  });
}
