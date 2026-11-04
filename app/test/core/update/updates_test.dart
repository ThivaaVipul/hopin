import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/update/updates.dart';

void main() {
  test('numbers builds as the release workflow does', () {
    expect(buildOf('v0.4.0'), 4000);
    expect(buildOf('1.2.3'), 1002003);
    expect(buildOf('v0.4'), isNull);
    expect(buildOf('v0.1000.0'), isNull);
    expect(versionOf(4000), '0.4.0');
    expect(versionOf(1002003), '1.2.3');
  });

  test("finds Hopin's APK in GitHub's latest release", () {
    final release = parseRelease({
      'tag_name': 'v0.4.0',
      'assets': [
        {'name': 'SHA256SUMS.txt', 'browser_download_url': 'x', 'size': 1},
        {
          'name': 'hopin-0.4.0.apk',
          'browser_download_url': 'https://example.com/hopin-0.4.0.apk',
          'size': 35300000,
        },
      ],
    });
    expect(
      release,
      Release(
        build: 4000,
        apk: Uri.parse('https://example.com/hopin-0.4.0.apk'),
        size: 35300000,
      ),
    );
    expect(release!.version, '0.4.0');
  });

  test('ignores releases without the APK or with an odd tag', () {
    expect(parseRelease({'tag_name': 'v0.4.0', 'assets': <Object>[]}), isNull);
    expect(
      parseRelease({
        'tag_name': 'latest',
        'assets': [
          {'name': 'hopin-0.4.0.apk', 'browser_download_url': 'x', 'size': 1},
        ],
      }),
      isNull,
    );
    expect(parseRelease('nope'), isNull);
  });
}
