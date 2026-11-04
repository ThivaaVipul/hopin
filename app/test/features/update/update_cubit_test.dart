import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/update/updates.dart';
import 'package:hopin/features/update/cubit/update_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeUpdates updates;
  late DateTime now;
  final newer = Release(
    build: 4000,
    apk: Uri.parse('https://example.com/hopin-0.4.0.apk'),
    size: 10,
  );

  setUp(() {
    updates = FakeUpdates(installed: 3000, release: newer);
    now = DateTime.utc(2026, 1, 1, 8);
  });

  UpdateCubit cubit() => UpdateCubit(updates, clock: () => now);

  test('offers a newer version, looking at most every 6 hours', () async {
    final update = cubit();
    await update.check();
    expect(update.state.offered, isTrue);
    expect(update.state.latest, newer);

    now = now.add(const Duration(hours: 5));
    await update.check();
    expect(updates.checks, 1);

    now = now.add(const Duration(hours: 2));
    await update.check();
    expect(updates.checks, 2);

    await update.check(now: true);
    expect(updates.checks, 3, reason: 'Check in Settings looks now');
    await update.close();
  });

  test('is up to date when nothing newer is out', () async {
    updates.release = Release(build: 3000, apk: newer.apk, size: 10);
    final update = cubit();
    await update.check(now: true);
    expect(update.state.phase, UpdatePhase.upToDate);
    expect(update.state.offered, isFalse);
    await update.close();
  });

  test('says so when a check from Settings fails, not otherwise', () async {
    updates.offline = true;
    final update = cubit();
    await update.check();
    expect(update.state.phase, UpdatePhase.idle);
    await update.check(now: true);
    expect(update.state.phase, UpdatePhase.checkFailed);
    await update.close();
  });

  test('test builds never look', () async {
    updates.installed = 0;
    final update = cubit();
    await update.check(now: true);
    expect(updates.checks, 0);
    await update.close();
  });

  test('downloads once, then opens the installer', () async {
    final update = cubit();
    await update.check();
    updates.mayInstall = false;
    await update.update();
    expect(update.state.phase, UpdatePhase.needsPermission);
    expect(update.state.offered, isTrue);

    updates.mayInstall = true;
    await update.update();
    expect(updates.downloads, 1, reason: 'the file is kept');
    expect(updates.installs, hasLength(2));
    await update.close();
  });

  test('a failed download can be tried again', () async {
    final update = cubit();
    await update.check();
    updates.downloadFails = true;
    await update.update();
    expect(update.state.phase, UpdatePhase.downloadFailed);
    expect(update.state.offered, isTrue);

    updates.downloadFails = false;
    await update.update();
    expect(updates.installs, hasLength(1));
    await update.close();
  });
}
