import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/share/share.dart';
import 'package:hopin/l10n/app_localizations.dart';
import 'package:hopin/l10n/time_left.dart';

/// Opens Android's share sheet with [text] (share_plus in the app, a fake in
/// widget tests).
typedef ShareSheet = Future<void> Function(String text);

/// Share on the ride board or bar: outlined until the ride is shared, then
/// amber (tapping it then offers Send link and Stop sharing).
class ShareRideButton extends StatelessWidget {
  const ShareRideButton({
    super.key,
    required this.sharing,
    required this.onPressed,
    this.ink,
  });

  final bool sharing;
  final VoidCallback onPressed;

  /// The board's text colour, where the board changes colour.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Tooltip(
      message: sharing ? l.sharingRide : l.share,
      child: sharing
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: colors.amber,
                foregroundColor: colors.onAmber,
                shape: shape,
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.wifi_tethering, size: 22),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: ink ?? colors.onBoard,
                side: BorderSide(
                  color: (ink ?? colors.onBoard).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                shape: shape,
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.share_outlined, size: 22),
            ),
    );
  }
}

enum SharingChoice { send, stop }

/// "Sharing this ride": Send link again, or Stop sharing.
Future<SharingChoice?> showSharingSheet(BuildContext context) {
  final l = AppLocalizations.of(context);
  final colors = context.colors;
  return showModalBottomSheet<SharingChoice>(
    context: context,
    backgroundColor: colors.board,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.sharingRide,
              style: context.text.headlineSmall?.copyWith(
                color: colors.onBoard,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(SharingChoice.send),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: Text(l.sendLink),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(SharingChoice.stop),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onBoard,
                    side: BorderSide(color: colors.onBoardMuted, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l.stopSharing),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Rebuilds now and then, for times that count up ("12 min", "updated
/// 20 s ago").
class _Ticking extends StatefulWidget {
  const _Ticking({required this.every, required this.builder});

  final Duration every;
  final WidgetBuilder builder;

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// The slim bar of a bus ride Hopin noticed, with no guide: how long so
/// far, Share and End.
class RideBar extends StatelessWidget {
  const RideBar({
    super.key,
    required this.since,
    required this.sharing,
    required this.onShare,
    required this.onEnd,
  });

  final DateTime since;
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.board,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const LedDots(count: 3, lightUp: true),
            const SizedBox(width: 14),
            Expanded(
              child: _Ticking(
                every: const Duration(seconds: 30),
                builder: (context) {
                  final minutes = DateTime.now().difference(since).inMinutes;
                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.busRide,
                          style: context.text.titleMedium?.copyWith(
                            color: colors.onBoard,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '\n'),
                        TextSpan(
                          text: l.durationMinutes(minutes < 1 ? 1 : minutes),
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.onBoardMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            ShareRideButton(sharing: sharing, onPressed: onShare),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(l.end),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onBoard,
                side: BorderSide(color: colors.onBoardMuted, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Shared ride to Colombo Fort", in the app's language.
String sharedRideTitle(AppLocalizations l, LiveShare share, String language) {
  final goal = share.goal;
  if (goal == null) return l.sharedRide;
  return l.sharedRideTo(
    language == 'ta' ? (goal.nameTa ?? goal.name) : goal.name,
  );
}

/// "12 min", "2.4 km" where the share says; empty for a noticed ride.
String sharedRideLeft(AppLocalizations l, LiveShare share) {
  final goal = share.goal;
  if (goal == null) return '';
  final minutes = goal.minutesLeft;
  if (minutes != null) return l.timeLeft(minutes);
  final metres = goal.metresLeft;
  if (metres == null) return '';
  final away = shortDistance(metres.toDouble());
  return away.km ? l.distanceKm(away.value) : l.distanceM(away.value);
}

/// The other rider's open share, when Hopin opens: Watch or Not now.
class SharedRideCard extends StatelessWidget {
  const SharedRideCard({
    super.key,
    required this.share,
    required this.onWatch,
    required this.onNotNow,
  });

  final LiveShare share;
  final VoidCallback onWatch;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final left = sharedRideLeft(l, share);
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
              sharedRideTitle(l, share, language),
              style: context.text.headlineSmall?.copyWith(
                color: colors.onBoard,
              ),
            ),
            if (left.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                left,
                style: context.text.titleMedium?.copyWith(color: colors.amber),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: Text(l.watch),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 52),
                  ),
                ),
                TextButton(
                  onPressed: onNotNow,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onBoardMuted,
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(l.notNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Watching the other rider's share on the map: where they're going, how
/// long is left, and how fresh the position is.
class WatchPanel extends StatelessWidget {
  const WatchPanel({super.key, required this.share, required this.onClose});

  final LiveShare share;
  final VoidCallback onClose;

  /// No update this long reads as lost (docs/PLAN.md, Sharing and stops).
  static const lostAfter = Duration(minutes: 10);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final left = sharedRideLeft(l, share);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
      decoration: BoxDecoration(
        color: colors.board,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sharedRideTitle(l, share, language),
                    style: context.text.titleLarge?.copyWith(
                      color: colors.onBoard,
                    ),
                  ),
                  if (left.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      left,
                      style: context.text.titleMedium?.copyWith(
                        color: colors.amber,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _Ticking(
                    every: const Duration(seconds: 10),
                    builder: (context) {
                      final (text, lost) = _freshness(l);
                      return Text(
                        text,
                        style: context.text.bodyMedium?.copyWith(
                          color: lost
                              ? colors.onBoardUrgent
                              : colors.onBoardMuted,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.close,
              onPressed: onClose,
              icon: Icon(Icons.close, color: colors.onBoardMuted),
            ),
          ],
        ),
      ),
    );
  }

  (String, bool) _freshness(AppLocalizations l) {
    final at = share.updatedAt;
    if (at == null) return (l.updatedJustNow, false);
    final age = DateTime.now().difference(at);
    if (age >= lostAfter) return (l.lostContact, true);
    if (age.inSeconds < 15) return (l.updatedJustNow, false);
    if (age.inMinutes < 1) return (l.updatedSecondsAgo(age.inSeconds), false);
    return (l.updatedMinutesAgo(age.inMinutes), false);
  }
}
