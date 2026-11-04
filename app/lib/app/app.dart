import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/language.dart';
import 'package:hopin/app/ride_config_follower.dart';
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
import 'package:hopin/core/update/updates.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
import 'package:hopin/features/update/cubit/update_cubit.dart';
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
    required this.updates,
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
  final UpdateService updates;
  final Locale locale;

  @override
  State<HopinApp> createState() => _HopinAppState();
}

class _HopinAppState extends State<HopinApp> {
  late final AppLanguage _language = AppLanguage(widget.locale.languageCode)
    ..addListener(() => _session.languageChanged());
  late final SessionCubit _session = SessionCubit(
    widget.auth,
    widget.profiles,
    language: () => _language.value,
  );
  late final SessionListenable _refresh = SessionListenable(_session.stream);
  late final GoRouter _router = buildRouter(_session, _refresh);
  late final UpdateCubit _update = UpdateCubit(widget.updates);

  @override
  void initState() {
    super.initState();
    unawaited(_update.check());
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    _language.dispose();
    unawaited(_session.close());
    unawaited(_update.close());
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
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _update),
      ],
      child: ValueListenableBuilder<String>(
        valueListenable: _language,
        builder: (context, language, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: hopinTheme(Brightness.light),
          darkTheme: hopinTheme(Brightness.dark),
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
          builder: (context, child) => WorkspaceScope(
            open: widget.openDatabase,
            remote: widget.remote,
            child: LanguageFollower(
              language: _language,
              child: RideConfigFollower(
                guide: widget.guide,
                language: _language,
                child: child ?? const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
