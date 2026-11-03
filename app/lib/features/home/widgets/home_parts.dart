import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/l10n/app_localizations.dart';

IconData kindIcon(PlaceKind kind) => switch (kind) {
  PlaceKind.home => Icons.home_outlined,
  PlaceKind.work => Icons.work_outline,
  PlaceKind.uni => Icons.school_outlined,
  PlaceKind.other => Icons.place_outlined,
};

String kindLabel(AppLocalizations l, PlaceKind kind) => switch (kind) {
  PlaceKind.home => l.kindHome,
  PlaceKind.work => l.kindWork,
  PlaceKind.uni => l.kindUni,
  PlaceKind.other => l.kindOther,
};

/// The bar at the top of Home: a board with an amber mark, like the bus's own.
class SearchBarButton extends StatelessWidget {
  const SearchBarButton({
    super.key,
    required this.onTap,
    required this.onAccount,
  });

  final VoidCallback onTap;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 4,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.whereTo,
                  style: context.text.bodyLarge?.copyWith(
                    color: colors.onBoard,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.account,
                onPressed: onAccount,
                icon: Icon(Icons.person_outline, color: colors.onBoardMuted),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saved places as board chips; long-press one to edit it.
class PlaceChips extends StatelessWidget {
  const PlaceChips({
    super.key,
    required this.places,
    required this.onTap,
    required this.onLongPress,
    required this.onAdd,
  });

  final List<SavedPlace> places;
  final ValueChanged<SavedPlace> onTap;
  final ValueChanged<SavedPlace> onLongPress;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (final place in places) ...[
            _Chip(
              icon: kindIcon(place.kind),
              label: place.name,
              onTap: () => onTap(place),
              onLongPress: () => onLongPress(place),
            ),
            const SizedBox(width: 8),
          ],
          _Chip(icon: Icons.add, label: l.add, onTap: onAdd),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.board,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.amber),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.text.titleMedium?.copyWith(
                  color: colors.onBoard,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The board panel at the bottom: where the rider would go, as on the bus.
class DestinationPanel extends StatelessWidget {
  const DestinationPanel({
    super.key,
    required this.destination,
    required this.me,
    required this.resolving,
    required this.onSave,
    required this.onClose,
  });

  final Destination destination;
  final GeoPoint? me;
  final bool resolving;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final names = destination.names;
    final saved = destination.saved;
    final placeName = names.inLanguage(language);
    final title = saved?.name ?? placeName ?? destination.area ?? l.droppedPin;
    final detail = [
      if (saved != null && placeName != null && placeName != saved.name)
        placeName,
      if (destination.area != null && destination.area != title)
        destination.area!,
    ].join(', ');
    final away = me == null
        ? null
        : shortDistance(me!.distanceTo(destination.point));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 24),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (names.si != null)
                        Text(
                          names.si!,
                          style: context.text.headlineSmall?.copyWith(
                            fontFamily: sinhalaFamily,
                            color: colors.amber,
                            height: 1.3,
                          ),
                        ),
                      Text(
                        title,
                        style: context.text.titleLarge?.copyWith(
                          color: colors.onBoard,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.onBoardMuted,
                          ),
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
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  if (resolving)
                    const LedDots(count: 6, lightUp: true)
                  else if (away != null)
                    Text(
                      away.km ? l.awayKm(away.value) : l.awayM(away.value),
                      style: context.text.titleMedium?.copyWith(
                        color: colors.onBoardMuted,
                      ),
                    ),
                  const Spacer(),
                  if (saved != null)
                    OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l.edit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onBoard,
                        side: BorderSide(
                          color: colors.onBoardMuted,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: resolving ? null : onSave,
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: Text(l.save),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.amber,
                        foregroundColor: colors.onAmber,
                        disabledBackgroundColor: colors.amberDim,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one-time reason before Android's location popup.
class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.onContinue,
    required this.onNotNow,
  });

  final VoidCallback onContinue;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
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
            const SizedBox(height: 16),
            Text(
              l.locationWhy,
              style: context.text.titleMedium?.copyWith(
                color: colors.onBoard,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onNotNow,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onBoardMuted,
                  ),
                  child: Text(l.notNow),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l.continueLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of the place editor.
sealed class PlaceEdit {
  const PlaceEdit();
}

class SavePlaceEdit extends PlaceEdit {
  const SavePlaceEdit(this.name, this.kind);
  final String name;
  final PlaceKind kind;
}

class DeletePlaceEdit extends PlaceEdit {
  const DeletePlaceEdit();
}

/// Names a new place, or renames, re-icons or deletes a saved one.
Future<PlaceEdit?> showPlaceEditor(
  BuildContext context, {
  required String name,
  required PlaceKind kind,
  required bool editing,
}) => showModalBottomSheet<PlaceEdit>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.colors.board,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (context) => _PlaceEditor(name: name, kind: kind, editing: editing),
);

class _PlaceEditor extends StatefulWidget {
  const _PlaceEditor({
    required this.name,
    required this.kind,
    required this.editing,
  });

  final String name;
  final PlaceKind kind;
  final bool editing;

  @override
  State<_PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<_PlaceEditor> {
  late final _name = TextEditingController(text: widget.name);
  late PlaceKind _kind = widget.kind;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final name = _name.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        22,
        24,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.editing ? l.editPlace : l.savePlace,
              style: context.text.headlineSmall?.copyWith(
                color: colors.onBoard,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 40,
              autofocus: !widget.editing,
              onChanged: (_) => setState(() {}),
              style: context.text.titleMedium?.copyWith(color: colors.onBoard),
              cursorColor: colors.amber,
              decoration: InputDecoration(
                labelText: l.placeName,
                labelStyle: TextStyle(color: colors.onBoardMuted),
                counterStyle: TextStyle(color: colors.onBoardMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.onBoardMuted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.amber, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in PlaceKind.values)
                  ChoiceChip(
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                    showCheckmark: false,
                    avatar: Icon(
                      kindIcon(kind),
                      size: 18,
                      color: _kind == kind ? colors.onAmber : colors.amber,
                    ),
                    label: Text(kindLabel(l, kind)),
                    labelStyle: TextStyle(
                      color: _kind == kind ? colors.onAmber : colors.onBoard,
                    ),
                    selectedColor: colors.amber,
                    backgroundColor: colors.board,
                    side: BorderSide(
                      color: _kind == kind ? colors.amber : colors.onBoardMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.editing)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const DeletePlaceEdit()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.delete),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onBoardUrgent,
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: name.isEmpty
                      ? null
                      : () =>
                            Navigator.pop(context, SavePlaceEdit(name, _kind)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.amber,
                    foregroundColor: colors.onAmber,
                    disabledBackgroundColor: colors.amberDim,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
