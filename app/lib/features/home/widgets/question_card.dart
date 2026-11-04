import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/core/guide/ride_task.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/ride_config.dart';
import 'package:hopin/features/home/widgets/home_parts.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// "On a bus?" on Home while the ride service asks it (docs/PLAN.md, Ride
/// detection): the same answers as its notification.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.places, required this.onAnswer});

  /// The rider's places, in their order; the first two become buttons.
  final List<SavedPlace> places;

  /// Called with ride_task.dart's button ID.
  final void Function(String button) onAnswer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final shown = places.take(RideConfig.buttons).toList();
    final style = FilledButton.styleFrom(
      backgroundColor: colors.amber,
      foregroundColor: colors.onAmber,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size(0, 52),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      decoration: BoxDecoration(
        color: colors.board,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LedDots(count: 5, lightUp: true),
            const SizedBox(height: 14),
            Text(
              l.onABus,
              style: context.text.headlineSmall?.copyWith(
                color: colors.onBoard,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, place) in shown.indexed)
                  FilledButton.icon(
                    onPressed: () => onAnswer(placeButton(i)),
                    icon: Icon(kindIcon(place.kind), size: 20),
                    label: Text(place.name),
                    style: style,
                  ),
                if (shown.length < RideConfig.buttons)
                  FilledButton(
                    onPressed: () => onAnswer(yesButton),
                    style: style,
                    child: Text(l.yes),
                  ),
                OutlinedButton(
                  onPressed: () => onAnswer(notBusButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onBoard,
                    side: BorderSide(color: colors.onBoardMuted, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(l.notABus),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
