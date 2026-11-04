import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// This build's number. The release workflow sets it (`HOPIN_BUILD`); other
/// builds have 0 and never look for updates.
const installedBuild = int.fromEnvironment('HOPIN_BUILD');

/// A release's build number, as the release workflow numbers them:
/// major * 1,000,000 + minor * 1,000 + patch. Null for anything else.
int? buildOf(String version) {
  final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(version.trim());
  if (match == null) return null;
  final [major, minor, patch] = [
    for (var i = 1; i <= 3; i++) int.parse(match.group(i)!),
  ];
  if (minor >= 1000 || patch >= 1000) return null;
  return major * 1000000 + minor * 1000 + patch;
}

/// "0.4.0" for build 4000.
String versionOf(int build) =>
    '${build ~/ 1000000}.${build ~/ 1000 % 1000}.${build % 1000}';

/// A published version and its APK.
class Release extends Equatable {
  const Release({required this.build, required this.apk, required this.size});

  final int build;
  final Uri apk;

  /// In bytes.
  final int size;

  String get version => versionOf(build);

  @override
  List<Object?> get props => [build, apk, size];
}

/// The latest release from GitHub's answer, if it carries Hopin's APK.
Release? parseRelease(Object? json) {
  if (json is! Map) return null;
  final tag = json['tag_name'];
  final build = tag is String ? buildOf(tag) : null;
  if (build == null) return null;
  final name = 'hopin-${versionOf(build)}.apk';
  for (final asset in json['assets'] is List ? json['assets'] as List : []) {
    if (asset is Map && asset['name'] == name) {
      final url = asset['browser_download_url'];
      final size = asset['size'];
      if (url is String && size is int) {
        return Release(build: build, apk: Uri.parse(url), size: size);
      }
    }
  }
  return null;
}

/// Updates from GitHub Releases (docs/PLAN.md, Settings and updates): what is
/// out, the download, and Android's installer.
abstract interface class UpdateService {
  /// This build; 0 for builds that don't update.
  int get installed;

  /// The latest release; throws when GitHub can't be reached.
  Future<Release?> latest();

  /// Downloads [release]'s APK, telling [progress] from 0 to 1; returns its
  /// file.
  Future<String> download(Release release, void Function(double) progress);

  /// Opens Android's installer for [file]. False when Hopin may not install
  /// apps yet: Android's page to allow it opens instead.
  Future<bool> install(String file);
}

class GitHubUpdates implements UpdateService {
  GitHubUpdates({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _latest =
      'https://api.github.com/repos/ThivaaVipul/hopin/releases/latest';
  static const _phone = MethodChannel('app.hopin/phone');

  @override
  int get installed => installedBuild;

  @override
  Future<Release?> latest() async {
    final response = await _client.get(
      Uri.parse(_latest),
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Hopin/${versionOf(installed)}',
      },
    );
    if (response.statusCode != 200) {
      throw HttpException('GitHub answered ${response.statusCode}');
    }
    return parseRelease(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  @override
  Future<String> download(
    Release release,
    void Function(double) progress,
  ) async {
    // The installer reads it through the app's file provider
    // (res/xml/update_paths.xml).
    final folder = Directory('${(await getTemporaryDirectory()).path}/updates');
    if (folder.existsSync()) folder.deleteSync(recursive: true);
    folder.createSync(recursive: true);
    final file = File('${folder.path}/hopin-${release.version}.apk');
    final response = await _client.send(http.Request('GET', release.apk));
    if (response.statusCode != 200) {
      throw HttpException('Download answered ${response.statusCode}');
    }
    final total = response.contentLength ?? release.size;
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) progress((received / total).clamp(0, 1));
      }
    } finally {
      await sink.close();
    }
    if (received != release.size) {
      throw HttpException('Got $received of ${release.size} bytes');
    }
    return file.path;
  }

  @override
  Future<bool> install(String file) async =>
      await _phone.invokeMethod<bool>('installApk', {'path': file}) ?? false;
}
