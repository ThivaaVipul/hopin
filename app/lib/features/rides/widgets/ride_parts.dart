import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// "24 min", "1 h 5 min".
String rideDuration(AppLocalizations l, RideRecord ride) {
  final minutes = (ride.endedAt.difference(ride.startedAt).inSeconds / 60)
      .round()
      .clamp(1, 1 << 20);
  return minutes < 60
      ? l.durationMinutes(minutes)
      : l.durationHours(minutes ~/ 60, minutes % 60);
}

/// "6.2 km", "850 m".
String rideDistance(AppLocalizations l, RideRecord ride) {
  final away = shortDistance(ride.distanceM.toDouble());
  return away.km ? l.distanceKm(away.value) : l.distanceM(away.value);
}

/// The time of day, as the phone shows it (24-hour or not).
String rideTime(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(at.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

String verdictLabel(AppLocalizations l, RideVerdict verdict) =>
    switch (verdict) {
      RideVerdict.bus => l.bus,
      RideVerdict.notBus => l.notABus,
      RideVerdict.unknown => l.unsure,
    };

/// "From -> To" with an arrow icon; nothing until the ride is named.
class RideNames extends StatelessWidget {
  const RideNames({super.key, required this.ride, this.style});

  final RideRecord ride;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final from = ride.fromName;
    final to = ride.toName;
    if (from == null || to == null) return const SizedBox.shrink();
    final style = this.style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: from),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward,
                size: (style.fontSize ?? 16) * 0.95,
                color: style.color,
              ),
            ),
          ),
          TextSpan(text: to),
        ],
      ),
    );
  }
}

/// The ride's label as a small tag: amber for a bus.
class VerdictTag extends StatelessWidget {
  const VerdictTag({super.key, required this.verdict});

  final RideVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final bus = verdict == RideVerdict.bus;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bus ? colors.amber : null,
        border: bus ? null : Border.all(color: colors.onBoardMuted),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          verdictLabel(l, verdict),
          style: context.text.labelMedium?.copyWith(
            color: bus ? colors.onAmber : colors.onBoardMuted,
          ),
        ),
      ),
    );
  }
}
