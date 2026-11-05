import 'dart:convert';

import 'package:hopin/core/ride/routes.dart';
import 'package:http/http.dart' as http;

/// One answer for a route file: its body when it changed (200), nothing when
/// it hasn't (304) or on any other status.
class RouteFileAnswer {
  const RouteFileAnswer(this.status, {this.body, this.etag});

  final int status;
  final String? body;
  final String? etag;
}

/// The route files on the repo's `data` release (docs/ARCHITECTURE.md, Route
/// data), straight from github.com: no API and so no API limit. A file that
/// hasn't changed since [etag] comes back as a 304 with no body.
class RouteFiles {
  RouteFiles({http.Client? client}) : _client = client ?? http.Client();

  static const base =
      'https://github.com/ThivaaVipul/hopin/releases/download/data';

  final http.Client _client;

  static Uri urlOf(RouteSource source) =>
      Uri.parse('$base/${source.name}-routes.json');

  Future<RouteFileAnswer> fetch(RouteSource source, {String? etag}) async {
    final response = await _client.get(
      urlOf(source),
      headers: {'User-Agent': 'Hopin', 'If-None-Match': ?etag},
    );
    return RouteFileAnswer(
      response.statusCode,
      body: response.statusCode == 200 ? utf8.decode(response.bodyBytes) : null,
      etag: response.headers['etag'],
    );
  }
}
