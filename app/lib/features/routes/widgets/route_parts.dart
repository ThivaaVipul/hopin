import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopin/app/widgets/number_chip.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/features/routes/cubit/routes_cubit.dart';
import 'package:hopin/features/routes/widgets/route_map.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// "Colombo to Kandy": a route's two ends in the app's language (where it
/// goes alone when its start is unknown).
String routeEnds(AppLocalizations l, KnownRoute route, String language) {
  String? name(PlaceNames names) => names.inLanguage(language) ?? names.si;
  final to = name(route.first.board) ?? route.number;
  final from = name(route.from);
  return from == null ? to : l.routeEnds(from, to);
}

String routeSource(AppLocalizations l, RouteSource source) => switch (source) {
  RouteSource.osm => l.routeSourceOsm,
  RouteSource.ntc => l.routeSourceNtc,
  RouteSource.lmt => l.routeSourceLmt,
  RouteSource.hand => l.routeSourceHand,
};

/// The classes and other numbers, as under a bus's number.
String numberNote(AppLocalizations l, RouteDirection direction) => [
  for (final code in direction.classes) classLabel(l, code),
  if (direction.also.isNotEmpty) l.alsoNumbers(direction.also.join(', ')),
].join(', ');

/// The towns a long-distance route passes between its ends, in order.
List<String> townsBetween(RouteDirection direction) => [
  if (direction.long)
    for (final stop in direction.stops) ?stop.name,
];

/// What a route's map draws: every direction's road (guessed parts apart)
/// and the first direction's ends, or a long-distance route's towns.
RouteMapProps routeMapProps(KnownRoute route, {required bool dark}) {
  final files = [for (final noted in route.directions) noted.file];
  final first = files.first;
  return RouteMapProps(
    roads: [
      for (final direction in files)
        if (direction.path.length > 1) direction.path,
    ],
    guessed: [
      for (final direction in files) ...[
        if (direction.before.length > 1) direction.before,
        if (direction.after.length > 1) direction.after,
      ],
    ],
    marks: first.long
        ? <GeoPoint>[
            ?first.start,
            for (final stop in first.stops) stop.point,
            ?first.end,
          ]
        : <GeoPoint>[?first.road.firstOrNull, ?first.road.lastOrNull],
    dark: dark,
  );
}

/// One direction's board lines to edit: Tamil, Sinhala and English, each
/// hinting the route file's own; an empty line keeps the file's. Pops the
/// lines, or null for Cancel.
class BoardLinesDialog extends StatefulWidget {
  const BoardLinesDialog({super.key, required this.lines, required this.file});

  /// As the board reads now, and as the route file has it.
  final PlaceNames lines;
  final PlaceNames file;

  @override
  State<BoardLinesDialog> createState() => _BoardLinesDialogState();
}

class _BoardLinesDialogState extends State<BoardLinesDialog> {
  late final _ta = TextEditingController(text: widget.lines.ta);
  late final _si = TextEditingController(text: widget.lines.si);
  late final _en = TextEditingController(text: widget.lines.en);

  @override
  void dispose() {
    _ta.dispose();
    _si.dispose();
    _en.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(
    context,
  ).pop(PlaceNames(ta: _ta.text, si: _si.text, en: _en.text));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget line(
      TextEditingController controller,
      String label,
      String? hint, {
      bool last = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        inputFormatters: [LengthLimitingTextInputFormatter(120)],
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onSubmitted: last ? (_) => _save() : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
    return AlertDialog(
      title: Text(l.editBoard),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            line(_ta, l.lineTamil, widget.file.ta),
            line(_si, l.lineSinhala, widget.file.si),
            line(_en, l.lineEnglish, widget.file.en, last: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
