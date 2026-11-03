import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/core/profile/profile_repository.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The app shell: theme, language, session and routes.
///
/// English by default; Tamil once the person picks it in Settings (M1a4),
/// independent of the phone's language.
class HopinApp extends StatefulWidget {
  const HopinApp({
    super.key,
    required this.auth,
    required this.profiles,
    this.locale = const Locale('en'),
  });

  final AuthRepository auth;
  final ProfileRepository profiles;
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
  Widget build(BuildContext context) =>
      RepositoryProvider<AuthRepository>.value(
        value: widget.auth,
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
          ),
        ),
      );
}
