import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/features/rides/cubit/rides_cubit.dart';
import 'package:hopin/features/rides/widgets/ride_parts.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Every logged ride, newest first, under its day (docs/PLAN.md, Rides page).
class RidesPage extends StatelessWidget {
  const RidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey(workspace.uid),
      create: (context) =>
          RidesCubit(workspace, context.read<Nominatim>())..start(),
      child: const _RidesView(),
    );
  }
}

class _RidesView extends StatelessWidget {
  const _RidesView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.rides),
        backgroundColor: colors.page,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<RidesCubit, RidesState>(
        builder: (context, state) {
          if (!state.loaded) return const SizedBox.shrink();
          if (state.rides.isEmpty) {
            return Center(
              child: Text(
                l.noRides,
                style: context.text.bodyLarge?.copyWith(color: colors.inkMuted),
              ),
            );
          }
          final days = _byDay(state.rides);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              for (final (day, rides) in days)
                _Day(title: _dayTitle(context, day), rides: rides),
            ],
          );
        },
      ),
    );
  }

  /// Newest day first; the rides keep their order (newest first).
  static List<(DateTime, List<RideRecord>)> _byDay(List<RideRecord> rides) {
    final days = <(DateTime, List<RideRecord>)>[];
    for (final ride in rides) {
      final at = ride.startedAt.toLocal();
      final day = DateTime(at.year, at.month, at.day);
      if (days.isNotEmpty && days.last.$1 == day) {
        days.last.$2.add(ride);
      } else {
        days.add((day, [ride]));
      }
    }
    return days;
  }

  static String _dayTitle(BuildContext context, DateTime day) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return l.today;
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return l.yesterday;
    }
    return MaterialLocalizations.of(context).formatMediumDate(day);
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.title, required this.rides});

  final String title;
  final List<RideRecord> rides;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Text(
              title,
              style: context.text.titleMedium?.copyWith(
                color: colors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Material(
            color: colors.board,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, ride) in rides.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colors.onBoardMuted.withValues(alpha: 0.25),
                    ),
                  _RideRow(ride: ride),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The start time, from and to (the distance until named), then the
/// duration and the label on a line that wraps (Tamil, large text).
class _RideRow extends StatelessWidget {
  const _RideRow({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final named = ride.fromName != null && ride.toName != null;
    final strong = context.text.bodyLarge?.copyWith(color: colors.onBoard);
    final muted = context.text.bodyMedium?.copyWith(color: colors.onBoardMuted);
    return InkWell(
      onTap: () => unawaited(context.push<void>(Routes.ride(ride.id))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 56,
                maxWidth: MediaQuery.sizeOf(context).width * 0.3,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Text(
                  rideTime(context, ride.startedAt),
                  style: context.text.titleMedium?.copyWith(
                    color: colors.onBoard,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (named)
                    RideNames(ride: ride, style: strong)
                  else
                    Text(rideDistance(l, ride), style: strong),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(rideDuration(l, ride), style: muted),
                      if (named) Text(rideDistance(l, ride), style: muted),
                      VerdictTag(verdict: ride.verdict),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
