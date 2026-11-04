import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/features/update/cubit/update_cubit.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The calm note on Home that a newer version is out (docs/PLAN.md, Settings
/// and updates), with Update and the download's progress.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) => AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : motion.base,
        curve: motion.ease,
        alignment: AlignmentDirectional.topStart,
        child: state.offered
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _Banner(state: state),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final downloading = state.phase == UpdatePhase.downloading;
    final message = switch (state.phase) {
      UpdatePhase.downloading => l.downloading((state.progress * 100).floor()),
      UpdatePhase.needsPermission => l.allowInstalls,
      UpdatePhase.downloadFailed => l.updateFailed,
      _ => l.updateReady(state.latest!.version),
    };
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
            child: Row(
              children: [
                Icon(Icons.system_update_outlined, color: colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: text.bodyLarge?.copyWith(color: colors.onBoard),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: downloading
                      ? null
                      : () => context.read<UpdateCubit>().update(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.amber,
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l.update),
                ),
              ],
            ),
          ),
          if (downloading)
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 3,
              color: colors.amber,
              backgroundColor: colors.amberDim,
            ),
        ],
      ),
    );
  }
}
