import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The first release's home: who you are and whether rider access is on.
/// M1a2 replaces it with the map.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Rider access is switched on outside the app; coming back to it is the
    // natural moment to look again.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<SessionCubit>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final motion = context.motion;
    final account = context.select((SessionCubit cubit) => cubit.state.account);
    if (account == null) return const SizedBox.shrink();
    final isRider = account.isRider;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.hello(account.firstName),
                style: context.text.headlineLarge,
              ),
              const SizedBox(height: 20),
              AnimatedContainer(
                duration: motion.base,
                curve: motion.ease,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  color: colors.board,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LedDots(count: 5, lit: isRider ? 5 : 1),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: motion.base,
                            child: Text(
                              isRider ? l.riderOn : l.riderWaiting,
                              key: ValueKey(isRider),
                              style: context.text.titleLarge?.copyWith(
                                color: colors.onBoard,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isRider)
                      const SizedBox(height: 8)
                    else
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: context.read<SessionCubit>().refresh,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.amber,
                          ),
                          child: Text(l.checkAgain),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.mapNext,
                style: context.text.bodyLarge?.copyWith(color: colors.inkMuted),
              ),
              const Spacer(),
              TextButton(
                onPressed: context.read<SessionCubit>().signOut,
                style: TextButton.styleFrom(foregroundColor: colors.inkMuted),
                child: Text(l.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
