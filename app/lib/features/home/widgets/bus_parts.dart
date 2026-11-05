import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/board_names.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/stops.dart';
import 'package:hopin/core/ride/which_bus.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The time of day, as the phone shows it (24-hour or not).
String clockTime(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

String classLabel(AppLocalizations l, String code) => switch (code) {
  'N' => l.classNormal,
  'SL' => l.classSemiLuxury,
  'L' => l.classLuxury,
  'AC' => l.classAc,
  'EX' => l.classExpressway,
  _ => code,
};

String walkLabel(AppLocalizations l, double metres) {
  final away = shortDistance(metres);
  return away.km ? l.walkKm(away.value) : l.walkM(away.value);
}

/// The name of where you board: the route's own stop, a known stop there, or
/// none (the road, or a nameless bus stand).
String? boardingName(BusOption option, List<Stop> stops, String language) {
  if (option.boardName case final name?) return name;
  Stop? best;
  var closest = 60.0;
  for (final stop in stops) {
    final away = stop.point.distanceTo(option.boardAt);
    if (away <= closest) {
      closest = away;
      best = stop;
    }
  }
  return best?.names.inLanguage(language);
}

String boardingLabel(
  AppLocalizations l,
  BusOption option,
  List<Stop> stops,
  String language,
) => switch (boardingName(option, stops, language)) {
  final name? => l.boardAt(name),
  null when option.direction.long => l.boardAtStand,
  null => l.boardOnRoad,
};

/// The buses that go to the destination, in its panel: a row each, the
/// picked one lit, and where the routes come from.
class BusList extends StatelessWidget {
  const BusList({
    super.key,
    required this.buses,
    required this.picked,
    required this.stops,
    required this.onPick,
    required this.onTimes,
  });

  final List<BusOption> buses;
  final BusOption? picked;

  /// The stops on the phone, to name where you board.
  final List<Stop> stops;
  final ValueChanged<BusOption> onPick;
  final ValueChanged<BusOption> onTimes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.32,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: buses.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: colors.onBoardMuted.withValues(alpha: 0.25),
            ),
            itemBuilder: (context, i) => BusRow(
              option: buses[i],
              picked: buses[i].direction == picked?.direction,
              stops: stops,
              onTap: () => onPick(buses[i]),
              onTimes: () => onTimes(buses[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l.routeCredits,
            style: context.text.labelSmall?.copyWith(
              color: colors.onBoardMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// One bus: its number, its board as on the bus, where to board and how far
/// to walk, and when it next comes.
class BusRow extends StatelessWidget {
  const BusRow({
    super.key,
    required this.option,
    required this.picked,
    required this.stops,
    required this.onTap,
    required this.onTimes,
  });

  final BusOption option;
  final bool picked;
  final List<Stop> stops;
  final VoidCallback onTap;
  final VoidCallback onTimes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final direction = option.direction;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NumberChip(
              number: direction.number,
              picked: picked,
              note: [
                for (final code in direction.classes) classLabel(l, code),
                if (direction.also.isNotEmpty)
                  l.alsoNumbers(direction.also.join(', ')),
              ].join(', '),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoardNames(
                    direction.board,
                    size: BoardSize.row,
                    rest: colors.onBoard,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${boardingLabel(l, option, stops, language)}'
                    ', ${walkLabel(l, option.walkTo)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onBoardMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (direction.times.isNotEmpty) ...[
              const SizedBox(width: 8),
              _NextTimes(option: option, onTap: onTimes),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({
    required this.number,
    required this.picked,
    required this.note,
  });

  final String number;
  final bool picked;

  /// The classes and other numbers, small under the number.
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = context.motion;
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: still ? Duration.zero : motion.quick,
            curve: motion.ease,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: picked ? colors.amber : Colors.transparent,
              border: Border.all(color: colors.amber, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium?.copyWith(
                fontFamily: displayFamily,
                fontWeight: FontWeight.w700,
                color: picked ? colors.onAmber : colors.amber,
              ),
            ),
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                note,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: colors.onBoardMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextTimes extends StatelessWidget {
  const _NextTimes({required this.option, required this.onTap});

  final BusOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final next = option.next;
    final now = DateTime.now();
    final first = next.firstOrNull;
    final tomorrow =
        first != null &&
        DateTime(first.year, first.month, first.day) !=
            DateTime(now.year, now.month, now.day);
    // A narrow column beside the board: a time with its AM or PM in Tamil,
    // at large text, wraps rather than pushing the board off the row.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (first == null)
                Text(
                  l.noneLeftToday,
                  textAlign: TextAlign.end,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.onBoardMuted,
                  ),
                )
              else ...[
                if (tomorrow)
                  Text(
                    l.tomorrow,
                    textAlign: TextAlign.end,
                    style: context.text.labelSmall?.copyWith(
                      color: colors.onBoardMuted,
                    ),
                  ),
                Text(
                  clockTime(context, first),
                  textAlign: TextAlign.end,
                  style: context.text.titleMedium?.copyWith(
                    fontFamily: displayFamily,
                    fontWeight: FontWeight.w700,
                    color: colors.onBoard,
                  ),
                ),
                for (final at in next.skip(1))
                  Text(
                    clockTime(context, at),
                    textAlign: TextAlign.end,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onBoardMuted,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// No known bus goes there: say so, and offer the place's name full screen
/// to show someone and ask.
class NoBusKnown extends StatelessWidget {
  const NoBusKnown({super.key, required this.onShow});

  /// Null when the place has no name to show.
  final VoidCallback? onShow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            l.noBusKnown,
            style: context.text.bodyLarge?.copyWith(color: colors.onBoardMuted),
          ),
        ),
        if (onShow case final show?)
          TextButton.icon(
            onPressed: show,
            icon: const Icon(Icons.fullscreen, size: 20),
            label: Text(l.showName),
            style: TextButton.styleFrom(foregroundColor: colors.amber),
          ),
      ],
    );
  }
}

/// The place's names full screen, on amber, large enough to show across a
/// bus stop; a tap anywhere closes it.
Future<void> showNameBoard(BuildContext context, PlaceNames names) {
  final l = AppLocalizations.of(context);
  final still = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l.close,
    transitionDuration: still ? Duration.zero : context.motion.base,
    pageBuilder: (context, _, _) => _NameWall(names: names),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _NameWall extends StatelessWidget {
  const _NameWall({required this.names});

  final PlaceNames names;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      label: l.close,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: colors.amber,
          padding: const EdgeInsets.all(32),
          child: SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 64,
                  ),
                  child: BoardNames(
                    names,
                    size: BoardSize.wall,
                    lead: colors.onAmber,
                    rest: colors.onAmber.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// All of today's times of a bus where you board; past ones dimmed.
Future<void> showAllTimes(
  BuildContext context,
  BusOption option,
  String? place,
) {
  final l = AppLocalizations.of(context);
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final colors = context.colors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${option.direction.number}  ${place == null ? l.allTimes : l.timesAt(place)}',
                style: context.text.titleLarge,
              ),
              const SizedBox(height: 12),
              if (option.today.isEmpty)
                Text(l.noneLeftToday)
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        for (final minute in option.today)
                          Text(
                            clockTime(
                              context,
                              midnight.add(Duration(minutes: minute)),
                            ),
                            style: context.text.titleMedium?.copyWith(
                              fontFamily: displayFamily,
                              color:
                                  midnight
                                      .add(Duration(minutes: minute))
                                      .isBefore(now)
                                  ? colors.inkMuted
                                  : colors.ink,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
