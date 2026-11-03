import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/profile/profile_repository.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The app shell: theme, language, session, the signed-in person's workspace,
/// and routes. Everything that reaches the outside world comes in here, so
/// tests can pass fakes.
///
/// English by default; Tamil once the person picks it in Settings (M1a4),
/// independent of the phone's language.
class HopinApp extends StatefulWidget {
  const HopinApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.remote,
    required this.openDatabase,
    required this.location,
    required this.nominatim,
    required this.mapBuilder,
    required this.guide,
    this.locale = const Locale('en'),
  });

  final AuthRepository auth;
  final ProfileRepository profiles;
  final Remote remote;
  final DatabaseOpener openDatabase;
  final LocationService location;
  final Nominatim nominatim;
  final MapBuilder mapBuilder;
  final GuideService guide;
  final Locale locale;

  @override
  State<HopinApp> createState() => _HopinAppState();
}

class _HopinAppState extends State<HopinApp> {
  late final SessionCubit _session = SessionCubit(
    widget.auth,
    widget.profiles,
    language: widget.locale.languageCode,
  );
  late final SessionListenable _refresh = SessionListenable(_session.stream);
  late final GoRouter _router = buildRouter(_session, _refresh);

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    unawaited(_session.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: widget.auth),
      RepositoryProvider<LocationService>.value(value: widget.location),
      RepositoryProvider<Nominatim>.value(value: widget.nominatim),
      RepositoryProvider<MapBuilder>.value(value: widget.mapBuilder),
      RepositoryProvider<GuideService>.value(value: widget.guide),
    ],
    child: BlocProvider.value(
      value: _session,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: hopinTheme(Brightness.light),
        darkTheme: hopinTheme(Brightness.dark),
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        builder: (context, child) => WorkspaceScope(
          open: widget.openDatabase,
          remote: widget.remote,
          child: child ?? const SizedBox(),
        ),
      ),
    ),
  );
}
