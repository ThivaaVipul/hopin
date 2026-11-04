import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/board_choice.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/features/rides/cubit/ride_cubit.dart';
import 'package:hopin/features/rides/widgets/ride_map.dart';
import 'package:hopin/features/rides/widgets/ride_parts.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// One ride (docs/PLAN.md, Rides page): its path on the map, then its times,
/// duration and distance, its label and Delete.
class RidePage extends StatelessWidget {
  const RidePage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey('${workspace.uid}/$id'),
      create: (context) => RideCubit(workspace.rides, id)..start(),
      child: const _RideView(),
    );
  }
}

class _RideView extends StatelessWidget {
  const _RideView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<RideCubit, RideState>(
      listenWhen: (before, now) => !before.gone && now.gone,
      listener: (context, state) {
        if (context.canPop()) context.pop();
      },
      builder: (context, state) {
        final ride = state.ride;
        return Scaffold(
          appBar: AppBar(
            title: ride == null
                ? null
                : Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(ride.startedAt.toLocal()),
                  ),
            backgroundColor: colors.page,
            foregroundColor: colors.ink,
            surfaceTintColor: Colors.transparent,
          ),
          body: ride == null ? const SizedBox.shrink() : _Ride(ride: ride),
        );
      },
    );
  }
}

class _Ride extends StatelessWidget {
  const _Ride({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final mapBuilder = context.read<RideMapBuilder>();
    final height = MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        if (ride.path.isNotEmpty)
          SizedBox(
            height: (height * 0.4).clamp(200, 380),
            child: mapBuilder(
              RideMapProps(
                path: ride.path,
                halts: ride.halts,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Details(ride: ride),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => unawaited(_delete(context)),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.delete),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.urgent,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<RideCubit>();
    if (await _ask(context, l.deleteRideQuestion, l.delete)) {
      await cubit.delete();
    }
  }
}

/// Times, from and to, duration and distance, and the label, on one board.
class _Details extends StatelessWidget {
  const _Details({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final figure = context.text.headlineSmall?.copyWith(
      color: colors.onBoard,
      fontWeight: FontWeight.w600,
    );
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.timeRange(
                rideTime(context, ride.startedAt),
                rideTime(context, ride.endedAt),
              ),
              style: context.text.titleMedium?.copyWith(
                color: colors.onBoardMuted,
              ),
            ),
            if (ride.fromName != null && ride.toName != null) ...[
              const SizedBox(height: 6),
              RideNames(
                ride: ride,
                style: context.text.titleLarge?.copyWith(color: colors.onBoard),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 4,
              children: [
                Text(rideDuration(l, ride), style: figure),
                Text(rideDistance(l, ride), style: figure),
              ],
            ),
            const SizedBox(height: 18),
            _Label(ride: ride),
          ],
        ),
      ),
    );
  }
}

/// Bus, Not a bus, Unsure, side by side like the language choice.
class _Label extends StatelessWidget {
  const _Label({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // One height for all three, when a label wraps (Tamil, large text).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final verdict in RideVerdict.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: BoardChoice(
                  label: verdictLabel(l, verdict),
                  selected: verdict == ride.verdict,
                  onTap: () => unawaited(_relabel(context, verdict)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Not a bus keeps no path: asked first when the ride has one.
  Future<void> _relabel(BuildContext context, RideVerdict verdict) async {
    if (verdict == ride.verdict) return;
    final l = AppLocalizations.of(context);
    final cubit = context.read<RideCubit>();
    if (verdict == RideVerdict.notBus &&
        ride.path.isNotEmpty &&
        !await _ask(context, l.notBusQuestion, l.removePath)) {
      return;
    }
    await cubit.label(verdict);
  }
}

/// A short question with Cancel and [action]; true when [action] is tapped.
Future<bool> _ask(BuildContext context, String question, String action) async {
  final l = AppLocalizations.of(context);
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return answer ?? false;
}
