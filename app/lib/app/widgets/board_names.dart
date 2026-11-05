import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/core/places/place.dart';

/// How large a board's names are, by where it shows.
enum BoardSize {
  /// A bus in the destination panel's list.
  row,

  /// The destination panel's own board.
  panel,

  /// The ride board.
  ride,

  /// Full screen, to show someone and ask.
  wall,
}

/// The script a board line is in, for its font.
enum BoardScript { tamil, sinhala, latin }

/// A board's lines, in the order the board shows them: Tamil, Sinhala, then
/// English (docs/PLAN.md, Which bus). Missing names are skipped, and a name
/// given twice shows once.
List<({String text, BoardScript script})> boardLines(PlaceNames names) {
  final seen = <String>{};
  return [
    for (final (value, script) in [
      (names.ta, BoardScript.tamil),
      (names.si, BoardScript.sinhala),
      (names.en, BoardScript.latin),
    ])
      if (value != null && value.trim().isNotEmpty && seen.add(value.trim()))
        (text: value.trim(), script: script),
  ];
}

/// A place's names as on a bus's board: the first line large in amber, the
/// others under it, smaller. Tamil leads; where it's missing, the next name
/// takes its place, so a board always leads with a large line.
class BoardNames extends StatelessWidget {
  const BoardNames(
    this.names, {
    super.key,
    this.size = BoardSize.panel,
    this.lead,
    this.rest,
  });

  final PlaceNames names;
  final BoardSize size;

  /// The first line's colour (the board's amber by default) and the others'.
  final Color? lead;
  final Color? rest;

  @override
  Widget build(BuildContext context) {
    final lines = boardLines(names);
    if (lines.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final text = context.text;
    final styles = switch (size) {
      // Compact beside a number and times: a long Tamil word still fits
      // whole on a small phone.
      BoardSize.row => [text.titleMedium, text.bodyMedium, text.bodySmall],
      BoardSize.panel => [
        text.headlineSmall,
        text.titleMedium,
        text.bodyMedium,
      ],
      BoardSize.ride => [
        text.headlineMedium,
        text.titleMedium,
        text.bodyMedium,
      ],
      BoardSize.wall => [
        text.displayMedium,
        text.headlineMedium,
        text.titleLarge,
      ],
    };
    Widget lineOf(int i, ({String text, BoardScript script}) line) {
      final style = styles[i]?.copyWith(
        fontFamily: switch (line.script) {
          BoardScript.tamil => tamilFamily,
          BoardScript.sinhala => sinhalaFamily,
          BoardScript.latin => null,
        },
        color: i == 0 ? (lead ?? colors.amber) : (rest ?? colors.onBoardMuted),
        fontWeight: i == 0 ? FontWeight.w600 : null,
        height: 1.25,
      );
      // A single long word leading a bus's row shrinks a little to fit, so
      // it never breaks in the middle; names of several words wrap between
      // them.
      if (size == BoardSize.row && i == 0 && !line.text.contains(' ')) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(line.text, maxLines: 1, softWrap: false, style: style),
        );
      }
      return Text(
        line.text,
        maxLines: size == BoardSize.wall ? 3 : 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final (i, line) in lines.indexed) lineOf(i, line)],
    );
  }
}
