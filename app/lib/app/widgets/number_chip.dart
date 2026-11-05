import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// NTC's class codes as the app says them.
String classLabel(AppLocalizations l, String code) => switch (code) {
  'N' => l.classNormal,
  'SL' => l.classSemiLuxury,
  'L' => l.classLuxury,
  'AC' => l.classAc,
  'EX' => l.classExpressway,
  _ => code,
};

/// A bus's number as on its board, amber when picked, with a small note
/// under it (the classes and other numbers).
class NumberChip extends StatelessWidget {
  const NumberChip({
    super.key,
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
