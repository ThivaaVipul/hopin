import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hopin/app/workspace.dart';

/// The app's language: the signed-in rider's choice (Settings, Language), or
/// [fallback] (English) before sign-in and until they choose.
class AppLanguage extends ValueNotifier<String> {
  AppLanguage(this.fallback) : super(fallback);

  final String fallback;

  void reset() => value = fallback;
}

/// Keeps [AppLanguage] on the signed-in rider's saved choice, which can also
/// arrive later from their other phone or a reinstall's sync.
class LanguageFollower extends StatefulWidget {
  const LanguageFollower({
    super.key,
    required this.language,
    required this.child,
  });

  final AppLanguage language;
  final Widget child;

  @override
  State<LanguageFollower> createState() => _LanguageFollowerState();
}

class _LanguageFollowerState extends State<LanguageFollower> {
  Workspace? _workspace;
  StreamSubscription<String?>? _saved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == _workspace) return;
    _workspace = workspace;
    unawaited(_saved?.cancel());
    final language = widget.language;
    if (workspace == null) {
      // Not during the build that noticed it.
      scheduleMicrotask(language.reset);
      _saved = null;
      return;
    }
    _saved = workspace.appSettings.watchLanguage().listen(
      (code) => code == null ? language.reset() : language.value = code,
    );
  }

  @override
  void dispose() {
    unawaited(_saved?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
