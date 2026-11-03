import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Shown for the moment it takes to learn who is signed in. The board colour
/// matches Android's launch screen, so the start is seamless.
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.board,
      body: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: context.text.displayMedium?.copyWith(color: colors.onBoard),
        ),
      ),
    );
  }
}
