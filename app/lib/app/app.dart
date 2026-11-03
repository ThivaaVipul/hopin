import 'package:flutter/material.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The app shell.
///
/// English by default; Tamil once the person picks it in Settings (M1a). The
/// theme and the first real screens come with the look pass before M1a.
class HopinApp extends StatelessWidget {
  const HopinApp({super.key, this.locale = const Locale('en')});

  /// The app's language, independent of the phone's.
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _StartPage(),
    );
  }
}

/// Stand-in until the look pass designs the first screens.
class _StartPage extends StatelessWidget {
  const _StartPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
