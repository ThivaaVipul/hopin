import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/app/widgets/rolling.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The ride board (docs/PLAN.md, The guide and Look): the stop's Sinhala name
/// in amber as on the bus, the distance and time left, the board's lights as
/// progress, "Now near" and End. At "Get off next" the whole board turns
/// amber, in time with the buzz; past the stop it says so.
class RideBoard extends StatelessWidget {
  const RideBoard({
    super.key,
    required this.ride,
    required this.status,
    required this.near,
    required this.onEnd,
  });

  final GuideRide ride;

  /// Null until the guide's first GPS fix.
  final GuideStatus? status;

  /// The area you are passing, in the app's language.
  final String? near;
  final VoidCallback onEnd;

  /// The progress lights.
  static const lights = 10;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: status?.phase == GuidePhase.getOff ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : motion.base,
      curve: motion.ease,
      builder: (context, amber, _) =>
          _Board(board: this, ink: _Ink.between(context.colors, amber)),
    );
  }
}

/// The board's colours, from the green-black board (0) to the amber one (1).
class _Ink {
  _Ink.between(HopinColors c, double t)
    : background = Color.lerp(c.board, c.amber, t)!,
      text = Color.lerp(c.onBoard, c.onAmber, t)!,
      muted = Color.lerp(c.onBoardMuted, c.onAmber.withValues(alpha: 0.75), t)!,
      lit = Color.lerp(c.amber, c.onAmber, t)!,
      unlit = Color.lerp(c.amberDim, c.onAmber.withValues(alpha: 0.22), t)!;

  final Color background;
  final Color text;
  final Color muted;

  /// The Sinhala name and the lit lights.
  final Color lit;
  final Color unlit;
}

class _Board extends StatelessWidget {
  const _Board({required this.board, required this.ink});

  final RideBoard board;
  final _Ink ink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final motion = context.motion;
    final text = context.text;
    final ride = board.ride;
    final status = board.status;
    final near = board.near;
    final si = ride.names.si;
    final headline = switch (status?.phase) {
      GuidePhase.getOff => l.getOffNext,
      GuidePhase.passed => l.passedStop,
      _ => null,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 20),
      decoration: BoxDecoration(
        color: ink.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: motion.base,
              curve: motion.ease,
              alignment: AlignmentDirectional.topStart,
              child: headline == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        headline,
                        style: text.headlineSmall?.copyWith(
                          color: status?.phase == GuidePhase.passed
                              ? colors.onBoardUrgent
                              : ink.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            if (si != null)
              Text(
                si,
                style: text.headlineMedium?.copyWith(
                  fontFamily: sinhalaFamily,
                  color: ink.lit,
                  height: 1.3,
                ),
              ),
            Text(
              ride.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(color: ink.text),
            ),
            const SizedBox(height: 14),
            if (status == null)
              Row(
                children: [
                  LedDots(
                    count: 3,
                    lightUp: true,
                    litColor: ink.lit,
                    dimColor: ink.unlit,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.findingYou,
                      style: text.titleMedium?.copyWith(color: ink.muted),
                    ),
                  ),
                ],
              )
            else
              _Numbers(status: status, ink: ink),
            const SizedBox(height: 14),
            LedDots(
              count: RideBoard.lights,
              lit: status == null
                  ? 0
                  : (status.progress * RideBoard.lights).floor(),
              size: 10,
              litColor: ink.lit,
              dimColor: ink.unlit,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    near == null ? '' : l.nowNear(near),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(color: ink.muted),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: board.onEnd,
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  label: Text(l.end),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ink.text,
                    side: BorderSide(color: ink.muted, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The distance left, large, with its unit smaller; the time left beside it.
class _Numbers extends StatelessWidget {
  const _Numbers({required this.status, required this.ink});

  final GuideStatus status;
  final _Ink ink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = context.text;
    final away = shortDistance(status.metres);
    final distance = away.km
        ? l.distanceKm(away.value)
        : l.distanceM(away.value);
    final at = distance.indexOf(away.value);
    final big = text.displayMedium?.copyWith(color: ink.text, height: 1);
    final unit = text.titleLarge?.copyWith(color: ink.muted);
    final left = status.left;
    final minutes = left == null ? null : l.minutesLeft(wholeMinutes(left));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Rolling(
            value: distance,
            child: at < 0
                ? Text(distance, style: big)
                : Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: distance.substring(0, at), style: unit),
                        TextSpan(text: away.value, style: big),
                        TextSpan(
                          text: distance.substring(at + away.value.length),
                          style: unit,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (minutes != null)
          Rolling(
            value: minutes,
            child: Text(
              minutes,
              style: text.headlineSmall?.copyWith(color: ink.text),
            ),
          ),
      ],
    );
  }
}
