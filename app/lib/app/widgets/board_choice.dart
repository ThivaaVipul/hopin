import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';

/// One of a few choices side by side on a board (the language, a ride's
/// label): amber when chosen, outlined otherwise. Put each in an [Expanded].
class BoardChoice extends StatelessWidget {
  const BoardChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? colors.amber : colors.board,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected
                ? colors.amber
                : colors.onBoardMuted.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                // A label too long for its share (Tamil, large text) shrinks
                // a little rather than breaking inside a word.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: context.text.titleMedium?.copyWith(
                      color: selected ? colors.onAmber : colors.onBoard,
                      fontWeight: FontWeight.w600,
                    ),
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
