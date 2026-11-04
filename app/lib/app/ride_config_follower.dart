import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hopin/app/language.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/ride_config.dart';

/// Keeps the ride service's [RideConfig] (the "On a bus?" places, the alert
/// stages, the language) in step with the signed-in rider's, so a ride
/// noticed with Hopin closed asks and guides as they set it.
class RideConfigFollower extends StatefulWidget {
  const RideConfigFollower({
    super.key,
    required this.guide,
    required this.language,
    required this.child,
  });

  final GuideService guide;
  final AppLanguage language;
  final Widget child;

  @override
  State<RideConfigFollower> createState() => _RideConfigFollowerState();
}

class _RideConfigFollowerState extends State<RideConfigFollower> {
  Workspace? _workspace;
  StreamSubscription<List<SavedPlace>>? _places;
  StreamSubscription<List<GuideStage>>? _stages;
  var _config = const RideConfig();

  @override
  void initState() {
    super.initState();
    widget.language.addListener(_onLanguage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == _workspace) return;
    _workspace = workspace;
    unawaited(_places?.cancel());
    unawaited(_stages?.cancel());
    _places = null;
    _stages = null;
    if (workspace == null) return;
    _places = workspace.places.watch().listen(
      (places) => _save(
        RideConfig(
          places: places.take(RideConfig.buttons).toList(),
          stages: _config.stages,
          language: widget.language.value,
        ),
      ),
    );
    _stages = workspace.appSettings.watchStages().listen(
      (stages) => _save(
        RideConfig(
          places: _config.places,
          stages: stages,
          language: widget.language.value,
        ),
      ),
    );
  }

  void _onLanguage() => _save(
    RideConfig(
      places: _config.places,
      stages: _config.stages,
      language: widget.language.value,
    ),
  );

  void _save(RideConfig config) {
    if (config == _config) return;
    _config = config;
    unawaited(widget.guide.saveRideConfig(config));
  }

  @override
  void dispose() {
    widget.language.removeListener(_onLanguage);
    unawaited(_places?.cancel());
    unawaited(_stages?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
