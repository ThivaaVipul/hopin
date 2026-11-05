import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/board_names.dart';
import 'package:hopin/app/widgets/number_chip.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/features/routes/cubit/route_cubit.dart';
import 'package:hopin/features/routes/cubit/routes_cubit.dart';
import 'package:hopin/features/routes/widgets/route_map.dart';
import 'package:hopin/features/routes/widgets/route_parts.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// One route (docs/PLAN.md, Which bus): its road on the map (or its towns),
/// its ends and where it comes from, each direction's board with Edit, and
/// Remove or Put back.
class RoutePage extends StatelessWidget {
  const RoutePage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey('${workspace.uid}/$id'),
      create: (context) => RouteCubit(workspace.routes, id)..start(),
      child: const _RouteView(),
    );
  }
}

class _RouteView extends StatelessWidget {
  const _RouteView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<RouteCubit, RouteState>(
      listenWhen: (before, now) => before.route != null && now.route == null,
      listener: (context, state) {
        if (context.canPop()) context.pop();
      },
      builder: (context, state) {
        final route = state.route;
        return Scaffold(
          appBar: AppBar(
            title: route == null ? null : Text(route.number),
            backgroundColor: colors.page,
            foregroundColor: colors.ink,
            surfaceTintColor: Colors.transparent,
          ),
          body: route == null
              ? const SizedBox.shrink()
              : _Route(route: route, hand: state.hand),
        );
      },
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.route, required this.hand});

  final KnownRoute route;

  /// The route as added by hand, for one that was.
  final HandRoute? hand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final mapBuilder = context.read<RouteMapBuilder>();
    final props = routeMapProps(
      route,
      dark: Theme.of(context).brightness == Brightness.dark,
    );
    final height = MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        if (props.roads.isNotEmpty || props.marks.length > 1)
          SizedBox(
            height: (height * 0.38).clamp(180, 340),
            child: mapBuilder(props),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Summary(
                route: route,
                hand: hand,
                guessed: props.guessed.isNotEmpty,
              ),
              const SizedBox(height: 16),
              _Boards(route: route),
              const SizedBox(height: 12),
              if (hand case final hand?)
                _HandActions(hand: hand)
              else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: route.removed
                      ? TextButton.icon(
                          onPressed: () => unawaited(
                            context.read<RouteCubit>().setRemoved(
                              removed: false,
                            ),
                          ),
                          icon: const Icon(Icons.undo),
                          label: Text(l.putBackRoute),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.amber,
                            minimumSize: const Size(0, 48),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () => unawaited(_remove(context)),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: Text(l.removeRoute),
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

  /// Asked first: it hides the route's buses for both riders.
  Future<void> _remove(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<RouteCubit>();
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.removeRouteQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.removeRoute),
          ),
        ],
      ),
    );
    if (sure ?? false) await cubit.setRemoved(removed: true);
  }
}

/// A route added by hand: Edit towns, and Delete for both riders.
class _HandActions extends StatelessWidget {
  const _HandActions({required this.hand});

  final HandRoute hand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      children: [
        TextButton.icon(
          onPressed: () =>
              unawaited(context.push<void>(Routes.editRoute(hand.routeId))),
          icon: const Icon(Icons.edit_road),
          label: Text(l.editTowns),
          style: TextButton.styleFrom(
            foregroundColor: colors.amber,
            minimumSize: const Size(0, 48),
          ),
        ),
        TextButton.icon(
          onPressed: () => unawaited(_delete(context)),
          icon: const Icon(Icons.delete_outline),
          label: Text(l.delete),
          style: TextButton.styleFrom(
            foregroundColor: colors.urgent,
            minimumSize: const Size(0, 48),
          ),
        ),
      ],
    );
  }

  /// Asked first: it goes for both riders.
  Future<void> _delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<RouteCubit>();
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.deleteRouteQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (sure ?? false) await cubit.delete();
  }
}

/// The number, the ends, where it comes from and the towns between.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.route,
    required this.hand,
    required this.guessed,
  });

  final KnownRoute route;
  final HandRoute? hand;
  final bool guessed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final first = route.first;
    final between = switch (hand) {
      final hand? => [
        for (final town in hand.via)
          ?(town.names.inLanguage(language) ?? town.names.si),
      ],
      null => townsBetween(first),
    };
    final muted = context.text.bodyMedium?.copyWith(color: colors.onBoardMuted);
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NumberChip(
                  number: first.number,
                  picked: !route.removed,
                  note: numberNote(l, first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeEnds(l, route, language),
                        style: context.text.titleMedium?.copyWith(
                          color: colors.onBoard,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          routeSource(l, first.source),
                          if (route.removed) l.routeRemoved,
                        ].join(', '),
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (between.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l.routeVia(between.join(', ')),
                style: context.text.bodyMedium?.copyWith(color: colors.onBoard),
              ),
            ],
            if (guessed) ...[
              const SizedBox(height: 8),
              Text(l.guessedDashed, style: muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Each direction's board as on the bus, with Edit.
class _Boards extends StatelessWidget {
  const _Boards({required this.route});

  final KnownRoute route;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, noted) in route.directions.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colors.onBoardMuted.withValues(alpha: 0.25),
              ),
            _BoardRow(noted: noted),
          ],
        ],
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.noted});

  final NotedDirection noted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: () => unawaited(_edit(context)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoardNames(
                    noted.direction.board,
                    size: BoardSize.row,
                    rest: colors.onBoard,
                  ),
                  if (noted.edited)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.boardEdited,
                        style: context.text.labelSmall?.copyWith(
                          color: colors.onBoardMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.editBoard,
              onPressed: () => unawaited(_edit(context)),
              icon: Icon(Icons.edit_outlined, color: colors.amber),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<RouteCubit>();
    final lines = await showDialog<PlaceNames>(
      context: context,
      builder: (context) => BoardLinesDialog(
        lines: noted.direction.board,
        file: noted.file.board,
      ),
    );
    if (lines != null) await cubit.setBoard(noted, lines);
  }
}
