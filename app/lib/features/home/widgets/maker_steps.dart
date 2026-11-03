import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// The phone maker's own steps that keep the guide running with the app
/// closed (docs/ARCHITECTURE.md, Phones that kill background apps), shown
/// once, after the first Start.
Future<void> showMakerSteps(
  BuildContext context,
  PhoneMaker maker, {
  required VoidCallback onOpenSettings,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.colors.board,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final steps = switch (maker) {
      PhoneMaker.xiaomi => [l.xiaomiAutostart, l.xiaomiBattery],
      PhoneMaker.samsung => [l.samsungBattery, l.samsungNeverSleeping],
      PhoneMaker.other => const <String>[],
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LedDots(count: 5, lightUp: true),
            const SizedBox(height: 16),
            Text(
              l.keepRunning,
              style: context.text.headlineSmall?.copyWith(
                color: colors.onBoard,
              ),
            ),
            const SizedBox(height: 14),
            for (final (i, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: context.text.titleMedium?.copyWith(
                          color: colors.onAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        step,
                        style: context.text.titleMedium?.copyWith(
                          color: colors.onBoard,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onBoardMuted,
                  ),
                  child: Text(l.done),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onOpenSettings();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l.openSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
