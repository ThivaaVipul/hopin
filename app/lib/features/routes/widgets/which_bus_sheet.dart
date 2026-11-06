import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/board_names.dart';
import 'package:hopin/app/widgets/number_chip.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/ride/which_bus.dart';
import 'package:hopin/features/routes/widgets/route_parts.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// What "Which bus?" answered: the ride's bus, or none (Not this bus).
typedef BusChoice = ({RouteTag? tag});

/// "Which bus?" (docs/PLAN.md, Which bus): the buses this ride could be
/// first (along its [path], or near [here] during a ride), then any by its
/// number, and Add for a number Hopin doesn't know. Null when dismissed.
Future<BusChoice?> askWhichBus(
  BuildContext context, {
  required List<RouteDirection> directions,
  List<GeoPoint> path = const [],
  GeoPoint? here,
  RouteTag? current,
}) => showModalBottomSheet<BusChoice>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.colors.board,
  showDragHandle: true,
  builder: (context) => _WhichBusSheet(
    directions: [
      for (final direction in directions)
        if (!direction.ridden) direction,
    ],
    path: path,
    here: here,
    current: current,
  ),
);

class _WhichBusSheet extends StatefulWidget {
  const _WhichBusSheet({
    required this.directions,
    required this.path,
    required this.here,
    required this.current,
  });

  final List<RouteDirection> directions;
  final List<GeoPoint> path;
  final GeoPoint? here;
  final RouteTag? current;

  @override
  State<_WhichBusSheet> createState() => _WhichBusSheetState();
}

class _WhichBusSheetState extends State<_WhichBusSheet> {
  late final _likely = likelyBuses(
    widget.directions,
    path: widget.path,
    here: widget.here,
  );
  var _query = '';

  List<RouteDirection> get _found {
    final wanted = plainNumber(_query);
    if (wanted.isEmpty) return _likely;
    return [
      for (final direction in widget.directions)
        if ([
          direction.number,
          ...direction.also,
        ].any((n) => plainNumber(n).startsWith(wanted)))
          direction,
    ]..sort((a, b) => plainNumber(a.number).compareTo(plainNumber(b.number)));
  }

  /// Whether the number typed is one Hopin has.
  bool get _known => widget.directions.any(
    (d) => plainNumber(d.number) == plainNumber(_query),
  );

  void _pick(RouteDirection direction) => Navigator.of(context).pop((
    tag: RouteTag.of(
      direction,
      language: Localizations.localeOf(context).languageCode,
    ),
  ));

  Future<void> _add() async {
    final language = Localizations.localeOf(context).languageCode;
    final added = await context.push<HandRoute>(
      Routes.addRoute,
      extra: _query.trim(),
    );
    if (added == null || !mounted) return;
    Navigator.of(
      context,
    ).pop((tag: RouteTag.of(added.directions.first, language: language)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final found = _found;
    final typed = _query.trim().isNotEmpty;
    final heading = typed
        ? null
        : widget.path.length >= 2
        ? l.alongThisRide
        : widget.here == null
        ? null
        : l.nearYou;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l.whichBus,
                style: context.text.headlineSmall?.copyWith(
                  color: colors.onBoard,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (text) => setState(() => _query = text),
                textInputAction: TextInputAction.search,
                style: context.text.titleMedium?.copyWith(
                  color: colors.onBoard,
                ),
                cursorColor: colors.amber,
                decoration: InputDecoration(
                  hintText: l.routeNumberHint,
                  hintStyle: TextStyle(color: colors.onBoardMuted),
                  prefixIcon: Icon(Icons.search, color: colors.amber),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (heading != null && found.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Text(
                        heading,
                        style: context.text.labelMedium?.copyWith(
                          color: colors.onBoardMuted,
                        ),
                      ),
                    ),
                  for (final direction in found.take(30))
                    _BusChoiceRow(
                      direction: direction,
                      picked: widget.current?.matches(direction) ?? false,
                      onTap: () => _pick(direction),
                    ),
                  if (typed && !_known)
                    _TextRow(
                      icon: Icons.add,
                      text: l.addRouteNumbered(_query.trim()),
                      onTap: () => unawaited(_add()),
                    ),
                  if (widget.current != null && !typed)
                    _TextRow(
                      icon: Icons.close,
                      text: l.notThisBus,
                      muted: true,
                      onTap: () => Navigator.of(context).pop((tag: null)),
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

/// A bus: its number and its board, as on the bus.
class _BusChoiceRow extends StatelessWidget {
  const _BusChoiceRow({
    required this.direction,
    required this.picked,
    required this.onTap,
  });

  final RouteDirection direction;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumberChip(
              number: direction.number,
              picked: picked,
              note: numberNote(l, direction),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BoardNames(
                direction.board,
                size: BoardSize.row,
                rest: colors.onBoard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.icon,
    required this.text,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = muted ? colors.onBoardMuted : colors.amber;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: context.text.bodyLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Which bus?" on the ride bar and the ride board: a bus until the ride is
/// tagged, then its number.
class WhichBusButton extends StatelessWidget {
  const WhichBusButton({
    super.key,
    required this.tag,
    required this.onPressed,
    this.ink,
  });

  final RouteTag? tag;
  final VoidCallback onPressed;

  /// The board's ink, where it isn't the theme's.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final tag = this.tag;
    if (tag == null) {
      return IconButton(
        tooltip: l.whichBus,
        onPressed: onPressed,
        icon: Icon(Icons.directions_bus_outlined, color: ink ?? colors.onBoard),
      );
    }
    return Tooltip(
      message: l.whichBus,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.amber,
          side: BorderSide(color: colors.amber, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(
          tag.number,
          maxLines: 1,
          style: context.text.titleMedium?.copyWith(
            fontFamily: displayFamily,
            fontWeight: FontWeight.w700,
            color: colors.amber,
          ),
        ),
      ),
    );
  }
}
