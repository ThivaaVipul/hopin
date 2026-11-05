import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/number_chip.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/features/routes/cubit/routes_cubit.dart';
import 'package:hopin/features/routes/widgets/route_parts.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Settings > Routes (docs/PLAN.md, Which bus): every route on the phone, in
/// number order, searched by number.
class RoutesPage extends StatelessWidget {
  const RoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey(workspace.uid),
      create: (context) => RoutesCubit(workspace.routes)..start(),
      child: const _RoutesView(),
    );
  }
}

class _RoutesView extends StatelessWidget {
  const _RoutesView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.routes),
        backgroundColor: colors.page,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<RoutesCubit, RoutesState>(
        builder: (context, state) {
          if (!state.loaded) return const SizedBox.shrink();
          if (state.routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.noRoutes,
                    style: context.text.bodyLarge?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _AddRoute(),
                ],
              ),
            );
          }
          final shown = state.shown;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _NumberSearch(),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: _AddRoute(),
              ),
              const SizedBox(height: 4),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      l.noRouteNumbered(state.query.trim()),
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                )
              else
                Material(
                  color: colors.board,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, route) in shown.indexed) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colors.onBoardMuted.withValues(alpha: 0.25),
                          ),
                        _RouteRow(route: route),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Add a route, by hand.
class _AddRoute extends StatelessWidget {
  const _AddRoute();

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => unawaited(context.push<void>(Routes.addRoute)),
    icon: const Icon(Icons.add),
    label: Text(AppLocalizations.of(context).addRoute),
    style: TextButton.styleFrom(
      foregroundColor: context.colors.amber,
      minimumSize: const Size(0, 48),
    ),
  );
}

/// The number to look for, on a board like the search's.
class _NumberSearch extends StatelessWidget {
  const _NumberSearch();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 12, 2),
        child: Row(
          children: [
            Icon(Icons.search, color: colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: context.read<RoutesCubit>().search,
                textInputAction: TextInputAction.search,
                style: context.text.titleMedium?.copyWith(
                  color: colors.onBoard,
                ),
                cursorColor: colors.amber,
                decoration: InputDecoration(
                  hintText: l.routeNumberHint,
                  hintStyle: TextStyle(color: colors.onBoardMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A route's number, its ends, and where it comes from (or Removed).
class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.route});

  final KnownRoute route;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final first = route.first;
    return InkWell(
      onTap: () => unawaited(context.push<void>(Routes.route(route.id))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumberChip(
              number: first.number,
              picked: false,
              note: numberNote(l, first),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeEnds(l, route, language),
                    style: context.text.bodyLarge?.copyWith(
                      color: route.removed
                          ? colors.onBoardMuted
                          : colors.onBoard,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route.removed
                        ? l.routeRemoved
                        : routeSource(l, first.source),
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onBoardMuted,
                    ),
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
