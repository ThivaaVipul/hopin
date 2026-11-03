import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/features/sign_in/cubit/sign_in_cubit.dart';
import 'package:hopin/l10n/app_localizations.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SignInCubit(context.read<AuthRepository>()),
    child: const _SignInView(),
  );
}

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final motion = context.motion;
    final status = context.watch<SignInCubit>().state;
    final busy = status == SignInStatus.busy;
    return Scaffold(
      backgroundColor: colors.board,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                l.appTitle,
                style: context.text.displayLarge?.copyWith(
                  color: colors.onBoard,
                  height: 1,
                  fontSize: 72,
                ),
              ),
              const SizedBox(height: 18),
              const LedDots(count: 12, lightUp: true, size: 9),
              const SizedBox(height: 22),
              Text(
                l.tagline,
                style: context.text.titleLarge?.copyWith(
                  color: colors.onBoardMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 4),
              AnimatedSize(
                duration: motion.base,
                curve: motion.ease,
                child: status == SignInStatus.failed
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: colors.urgent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.signInFailed,
                                style: context.text.bodyLarge?.copyWith(
                                  color: colors.onBoard,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: busy ? null : context.read<SignInCubit>().signIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    disabledBackgroundColor: colors.amber,
                    disabledForegroundColor: colors.onAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: context.text.labelLarge,
                  ),
                  child: AnimatedSwitcher(
                    duration: motion.quick,
                    child: busy
                        ? SizedBox.square(
                            key: const ValueKey('busy'),
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colors.onAmber,
                            ),
                          )
                        : Text(
                            l.continueWithGoogle,
                            key: const ValueKey('label'),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
