import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/features/home/view/home_page.dart';
import 'package:hopin/features/rides/view/ride_page.dart';
import 'package:hopin/features/rides/view/rides_page.dart';
import 'package:hopin/features/routes/view/route_editor_page.dart';
import 'package:hopin/features/routes/view/route_page.dart';
import 'package:hopin/features/routes/view/routes_page.dart';
import 'package:hopin/features/search/view/search_page.dart';
import 'package:hopin/features/settings/view/settings_page.dart';
import 'package:hopin/features/sign_in/view/sign_in_page.dart';
import 'package:hopin/features/start/start_page.dart';

abstract final class Routes {
  static const start = '/start';
  static const signIn = '/sign-in';
  static const home = '/';
  static const search = '/search';
  static const settings = '/settings';
  static const rides = '/rides';
  static String ride(String id) => '/rides/$id';
  static const routes = '/routes';
  static const addRoute = '/routes/add';

  /// A route's page; its id ("ntc:15-87:SL") goes in as one path segment.
  static String route(String id) => '/routes/${Uri.encodeComponent(id)}';

  /// A route added by hand, to change its towns.
  static String editRoute(String id) => '${route(id)}/edit';
}

/// What the search looks for when it isn't a place to go: a route's town.
typedef SearchFor = ({GeoPoint? near, String hint});

/// Where the session says you belong: the start screen until it knows, then
/// sign-in or home.
String? sessionRedirect(
  SessionStatus status,
  String location,
) => switch (status) {
  SessionStatus.unknown => location == Routes.start ? null : Routes.start,
  SessionStatus.signedOut => location == Routes.signIn ? null : Routes.signIn,
  SessionStatus.signedIn =>
    location == Routes.start || location == Routes.signIn ? Routes.home : null,
};

GoRouter buildRouter(SessionCubit session, Listenable refresh) => GoRouter(
  initialLocation: Routes.start,
  refreshListenable: refresh,
  redirect: (context, state) =>
      sessionRedirect(session.state.status, state.matchedLocation),
  routes: [
    GoRoute(path: Routes.start, builder: (context, state) => const StartPage()),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(path: Routes.rides, builder: (context, state) => const RidesPage()),
    GoRoute(
      path: '/rides/:id',
      builder: (context, state) => RidePage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.routes,
      builder: (context, state) => const RoutesPage(),
    ),
    // Before the route's own page, which would take "add" for an id.
    GoRoute(
      path: Routes.addRoute,
      builder: (context, state) => const RouteEditorPage(),
    ),
    GoRoute(
      path: '/routes/:id',
      builder: (context, state) => RoutePage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/routes/:id/edit',
      builder: (context, state) =>
          RouteEditorPage(routeId: state.pathParameters['id']),
    ),
    GoRoute(
      path: Routes.search,
      builder: (context, state) => switch (state.extra) {
        (:final GeoPoint? near, :final String hint) => SearchPage(
          near: near,
          hint: hint,
        ),
        final GeoPoint near => SearchPage(near: near),
        _ => const SearchPage(),
      },
    ),
  ],
);

/// Tells the router to look again whenever the session changes.
class SessionListenable extends ChangeNotifier {
  SessionListenable(Stream<SessionState> changes) {
    _subscription = changes.listen((_) => notifyListeners());
  }

  late final StreamSubscription<SessionState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
