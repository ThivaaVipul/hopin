import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// A stage's distance: "3 km", "1.5 km", "400 m".
String distanceText(AppLocalizations l, int metres) {
  if (metres < 1000) return l.distanceM('$metres');
  return l.distanceKm(
    metres % 1000 == 0
        ? '${metres ~/ 1000}'
        : (metres / 1000).toStringAsFixed(1),
  );
}

String patternName(AppLocalizations l, AlertPattern pattern) =>
    switch (pattern) {
      AlertPattern.gentleDoubleTap => l.patternGentleDoubleTap,
      AlertPattern.strongLongBuzz => l.patternStrongLongBuzz,
      AlertPattern.heartbeat => l.patternHeartbeat,
      AlertPattern.tripleKnock => l.patternTripleKnock,
      AlertPattern.rising => l.patternRising,
      AlertPattern.waves => l.patternWaves,
    };

/// Result of the stage editor.
sealed class StageEdit {
  const StageEdit();
}

class SaveStage extends StageEdit {
  const SaveStage(this.stage);

  final GuideStage stage;
}

class RemoveStage extends StageEdit {
  const RemoveStage();
}

/// One alert stage: its distance (those [taken] by other stages are off) and
/// its pattern, each with Try.
Future<StageEdit?> showStageEditor(
  BuildContext context, {
  required String title,
  required GuideStage stage,
  required Set<int> taken,
  required bool canRemove,
  required void Function(AlertPattern pattern) onTry,
}) => showModalBottomSheet<StageEdit>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.colors.board,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (context) => _StageEditor(
    title: title,
    stage: stage,
    taken: taken,
    canRemove: canRemove,
    onTry: onTry,
  ),
);

class _StageEditor extends StatefulWidget {
  const _StageEditor({
    required this.title,
    required this.stage,
    required this.taken,
    required this.canRemove,
    required this.onTry,
  });

  final String title;
  final GuideStage stage;
  final Set<int> taken;
  final bool canRemove;
  final void Function(AlertPattern pattern) onTry;

  @override
  State<_StageEditor> createState() => _StageEditorState();
}

class _StageEditorState extends State<_StageEditor> {
  late int _metres = widget.stage.metres;
  late AlertPattern _pattern = widget.stage.pattern;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: text.headlineSmall?.copyWith(color: colors.onBoard),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metres in stageDistances)
                  ChoiceChip(
                    label: Text(distanceText(l, metres)),
                    selected: metres == _metres,
                    onSelected: widget.taken.contains(metres)
                        ? null
                        : (_) => setState(() => _metres = metres),
                    showCheckmark: false,
                    backgroundColor: colors.board,
                    selectedColor: colors.amber,
                    disabledColor: colors.board,
                    labelStyle: text.labelLarge?.copyWith(
                      color: metres == _metres
                          ? colors.onAmber
                          : widget.taken.contains(metres)
                          ? colors.onBoardMuted.withValues(alpha: 0.5)
                          : colors.onBoard,
                    ),
                    side: BorderSide(
                      color: metres == _metres
                          ? colors.amber
                          : colors.onBoardMuted.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final pattern in AlertPattern.values)
              _PatternRow(
                name: patternName(l, pattern),
                selected: pattern == _pattern,
                onSelect: () => setState(() => _pattern = pattern),
                onTry: () => widget.onTry(pattern),
              ),
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              children: [
                if (widget.canRemove)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const RemoveStage()),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onBoardUrgent,
                    ),
                    child: Text(l.removeStage),
                  ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    SaveStage(GuideStage(_metres, _pattern)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l.done),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({
    required this.name,
    required this.selected,
    required this.onSelect,
    required this.onTry,
  });

  final String name;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.amber : colors.onBoardMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: context.text.titleMedium?.copyWith(
                    color: colors.onBoard,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onTry,
                icon: const Icon(Icons.vibration, size: 18),
                label: Text(l.tryIt),
                style: TextButton.styleFrom(
                  foregroundColor: colors.amber,
                  minimumSize: const Size(0, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
