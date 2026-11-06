import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/search/osrm.dart';
import 'package:hopin/features/routes/cubit/route_editor_cubit.dart';
import 'package:hopin/features/routes/widgets/route_map.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Adding a route by hand, or changing one's towns (docs/PLAN.md, Which
/// bus): its number, where it starts, the towns on the way and where it
/// ends, all picked from search, with the road OSRM draws through them on
/// the map before Save. It pops the route as saved.
class RouteEditorPage extends StatelessWidget {
  const RouteEditorPage({super.key, this.routeId, this.number});

  /// The hand route to change; null to add one.
  final String? routeId;

  /// A new one's number, from "Which bus?".
  final String? number;

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey('${workspace.uid}/${routeId ?? 'new'}'),
      create: (context) => RouteEditorCubit(
        workspace.routes,
        context.read<Osrm>(),
        routeId: routeId,
        number: number,
      )..start(),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocConsumer<RouteEditorCubit, RouteEditorState>(
      listenWhen: (before, now) => !before.saved && now.saved,
      listener: (context, state) {
        if (context.canPop()) context.pop(state.kept);
      },
      builder: (context, state) {
        final cubit = context.read<RouteEditorCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(state.editing ? l.editRoute : l.addRoute),
            backgroundColor: colors.page,
            foregroundColor: colors.ink,
            surfaceTintColor: Colors.transparent,
          ),
          body: !state.loaded
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _NumberField(number: state.number),
                    const SizedBox(height: 16),
                    _Towns(state: state),
                    const SizedBox(height: 16),
                    _Road(state: state),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: state.canSave ? () => unawaited(cubit.save()) : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.amber,
                foregroundColor: colors.onAmber,
                disabledBackgroundColor: colors.amberDim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(0, 52),
              ),
              child: Text(l.save),
            ),
          ),
        );
      },
    );
  }
}

/// The number as on the bus.
class _NumberField extends StatefulWidget {
  const _NumberField({required this.number});

  final String number;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _number = TextEditingController(text: widget.number);

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: TextField(
          controller: _number,
          autofocus: widget.number.isEmpty,
          inputFormatters: [LengthLimitingTextInputFormatter(12)],
          textCapitalization: TextCapitalization.characters,
          onChanged: context.read<RouteEditorCubit>().setNumber,
          style: context.text.titleLarge?.copyWith(
            color: colors.onBoard,
            fontFamily: displayFamily,
            fontWeight: FontWeight.w700,
          ),
          cursorColor: colors.amber,
          decoration: InputDecoration(
            labelText: l.routeNumberLabel,
            labelStyle: TextStyle(color: colors.onBoardMuted),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

/// From, the towns on the way (with Add a town), and To, in route order.
class _Towns extends StatelessWidget {
  const _Towns({required this.state});

  final RouteEditorState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<RouteEditorCubit>();
    final divider = Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: colors.onBoardMuted.withValues(alpha: 0.25),
    );
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TownRow(
            label: l.routeFrom,
            town: state.from,
            onTap: () => unawaited(_pick(context, cubit.setFrom)),
          ),
          divider,
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
            child: Text(
              l.townsOnTheWay,
              style: context.text.labelMedium?.copyWith(
                color: colors.onBoardMuted,
              ),
            ),
          ),
          for (final (i, town) in state.via.indexed)
            _TownRow(
              town: town,
              onTap: null,
              onRemove: () => unawaited(cubit.removeTown(i)),
            ),
          if (state.via.length < RouteEditorCubit.maxVia)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
              child: TextButton.icon(
                onPressed: () => unawaited(_pick(context, cubit.addTown)),
                icon: const Icon(Icons.add),
                label: Text(l.addTown),
                style: TextButton.styleFrom(
                  foregroundColor: colors.amber,
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          divider,
          _TownRow(
            label: l.routeTo,
            town: state.to,
            onTap: () => unawaited(_pick(context, cubit.setTo)),
          ),
        ],
      ),
    );
  }

  /// A town from search, near the route's start when it has one.
  Future<void> _pick(
    BuildContext context,
    Future<void> Function(RouteTown town) use,
  ) async {
    final l = AppLocalizations.of(context);
    final SearchFor search = (near: state.from?.point, hint: l.searchTown);
    final place = await context.push<Destination>(Routes.search, extra: search);
    if (place == null) return;
    final names = place.names.isEmpty
        ? PlaceNames(en: place.area)
        : place.names;
    await use(RouteTown(place.point, names));
  }
}

class _TownRow extends StatelessWidget {
  const _TownRow({
    required this.town,
    required this.onTap,
    this.label,
    this.onRemove,
  });

  final String? label;
  final RouteTown? town;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final town = this.town;
    final name = town == null
        ? l.pickTown
        : town.names.inLanguage(language) ?? town.names.si ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          label == null ? 4 : 12,
          onRemove == null ? 16 : 4,
          label == null ? 4 : 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label case final label?)
                    Text(
                      label,
                      style: context.text.labelMedium?.copyWith(
                        color: colors.onBoardMuted,
                      ),
                    ),
                  Text(
                    name,
                    style: context.text.bodyLarge?.copyWith(
                      color: town == null ? colors.amber : colors.onBoard,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove case final onRemove?)
              IconButton(
                tooltip: l.removeTown,
                onPressed: onRemove,
                icon: Icon(Icons.close, color: colors.onBoardMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// The road through the towns on the map, or how drawing it goes.
class _Road extends StatelessWidget {
  const _Road({required this.state});

  final RouteEditorState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final road = state.road;
    if (road != null) {
      final mapBuilder = context.read<RouteMapBuilder>();
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 240,
          // A new road is a new map: it draws once, when its style loads.
          child: KeyedSubtree(
            key: ObjectKey(road),
            child: mapBuilder(
              RouteMapProps(
                roads: [road],
                guessed: const [],
                marks: <GeoPoint>[for (final town in state.towns) town.point],
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ),
      );
    }
    final muted = context.text.bodyMedium?.copyWith(color: colors.inkMuted);
    if (state.drawing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l.drawingRoad, style: muted)),
          ],
        ),
      );
    }
    if (state.failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.roadFailed, style: muted),
            TextButton(
              onPressed: () =>
                  unawaited(context.read<RouteEditorCubit>().drawAgain()),
              style: TextButton.styleFrom(
                foregroundColor: colors.amber,
                minimumSize: const Size(0, 48),
              ),
              child: Text(l.tryAgain),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
