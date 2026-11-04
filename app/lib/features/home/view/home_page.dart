import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/features/home/cubit/home_cubit.dart';
import 'package:hopin/features/home/widgets/home_parts.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
import 'package:hopin/features/home/widgets/maker_steps.dart';
import 'package:hopin/features/home/widgets/question_card.dart';
import 'package:hopin/features/home/widgets/ride_board.dart';
import 'package:hopin/features/update/cubit/update_cubit.dart';
import 'package:hopin/features/update/widgets/update_banner.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Home: the map, where to, and saved places (docs/PLAN.md, Home and places).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey(workspace.uid),
      create: (context) {
        final cubit = HomeCubit(
          workspace,
          context.read<LocationService>(),
          context.read<Nominatim>(),
          context.read<GuideService>(),
        );
        unawaited(cubit.start());
        return cubit;
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _camera = MapCamera();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Rider access is switched on outside the app; coming back to it is the
    // natural moment to look again.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(context.read<SessionCubit>().refresh());
        unawaited(context.read<UpdateCubit>().check());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _search(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final picked = await context.push<Destination>(
      Routes.search,
      extra: cubit.state.me,
    );
    if (picked != null) cubit.select(picked);
  }

  Future<void> _savePlace(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final destination = cubit.state.destination;
    if (destination == null) return;
    final saved = destination.saved;
    final edit = await showPlaceEditor(
      context,
      name:
          saved?.name ??
          destination.names.inLanguage(
            Localizations.localeOf(context).languageCode,
          ) ??
          '',
      kind: saved?.kind ?? PlaceKind.other,
      editing: saved != null,
    );
    switch (edit) {
      case SavePlaceEdit(:final name, :final kind):
        await cubit.save(name: name, kind: kind);
      case DeletePlaceEdit():
        if (saved != null) await cubit.removePlace(saved);
      case null:
        break;
    }
  }

  Future<void> _editPlace(BuildContext context, SavedPlace place) async {
    final cubit = context.read<HomeCubit>();
    final edit = await showPlaceEditor(
      context,
      name: place.name,
      kind: place.kind,
      editing: true,
    );
    switch (edit) {
      case SavePlaceEdit(:final name, :final kind):
        await cubit.updatePlace(place.copyWith(name: name, kind: kind));
      case DeletePlaceEdit():
        await cubit.removePlace(place);
      case null:
        break;
    }
  }

  void _start(BuildContext context, Destination destination) {
    final language = Localizations.localeOf(context).languageCode;
    unawaited(
      context.read<HomeCubit>().startGuide(
        title: destinationTitle(
          AppLocalizations.of(context),
          destination,
          language,
        ),
        language: language,
      ),
    );
  }

  /// The map frames the ride: you and your stop, clear of the board.
  void _frame(BuildContext context, HomeState state) {
    final ride = state.ride;
    final me = state.me;
    if (ride != null) {
      if (me == null) {
        _camera.flyTo(ride.to, zoom: 14);
      } else {
        final screen = MediaQuery.sizeOf(context);
        final top = MediaQuery.paddingOf(context).top;
        _camera.fit(
          me,
          ride.to,
          padding: EdgeInsets.fromLTRB(56, top + 56, 56, screen.height * 0.5),
        );
      }
      return;
    }
    final target = state.destination?.point ?? me;
    if (target != null) {
      _camera.flyTo(target, zoom: state.destination == null ? 15 : 15.5);
    }
  }

  void _notify(BuildContext context, HomeNotice notice) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (notice) {
            HomeNotice.arrived => l.arrived,
            HomeNotice.guideFailed => l.guideFailed,
            HomeNotice.needsLocation => l.guideNeedsLocation,
            HomeNotice.gaveUp => l.guideGaveUp,
          }),
        ),
      );
    context.read<HomeCubit>().noticed();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final motion = context.motion;
    final still = MediaQuery.disableAnimationsOf(context);
    final language = Localizations.localeOf(context).languageCode;
    final mapBuilder = context.read<MapBuilder>();
    final cubit = context.read<HomeCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (before, now) =>
              before.destination?.point != now.destination?.point ||
              (before.me == null && now.me != null) ||
              (before.ride == null && now.ride != null),
          listener: _frame,
        ),
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (before, now) =>
              now.notice != null && before.notice != now.notice,
          listener: (context, state) => _notify(context, state.notice!),
        ),
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (before, now) =>
              before.makerSteps == null && now.makerSteps != null,
          listener: (context, state) {
            cubit.makerStepsSeen();
            unawaited(
              showMakerSteps(
                context,
                state.makerSteps!,
                onOpenSettings: () => unawaited(cubit.openMakerSettings()),
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final riding = state.ride != null;
          final near = state.near;
          final Widget bottom = switch (state) {
            HomeState(:final ride?) => RideBoard(
              key: const ValueKey('ride'),
              ride: ride,
              status: state.status,
              near: near?.names.inLanguage(language) ?? near?.area,
              onEnd: cubit.endGuide,
              onKeep: cubit.keepGoing,
            ),
            HomeState(location: LocationStatus.explain) => ReasonCard(
              key: const ValueKey('location'),
              reason: l.locationWhy,
              onContinue: cubit.continueToPermission,
              onNotNow: cubit.notNow,
            ),
            HomeState(question: true) => QuestionCard(
              key: const ValueKey('question'),
              places: state.places,
              onAnswer: (button) => unawaited(cubit.answer(button)),
            ),
            HomeState(explainNotifications: true) => ReasonCard(
              key: const ValueKey('notifications'),
              reason: l.notificationsWhy,
              onContinue: cubit.continueToNotifications,
              onNotNow: cubit.skipNotifications,
            ),
            HomeState(:final destination?) => DestinationPanel(
              key: ValueKey(destination.point),
              destination: destination,
              me: state.me,
              resolving: state.resolving,
              onSave: () => _savePlace(context),
              onStart: () => _start(context, destination),
              onClose: cubit.clear,
            ),
            HomeState(offerDetection: true) => ReasonCard(
              key: const ValueKey('detection'),
              reason: l.noticeWhy,
              continueLabel: l.turnOn,
              onContinue: () => unawaited(cubit.turnOnDetection(language)),
              onNotNow: () => unawaited(cubit.detectionNotNow()),
            ),
            _ => const SizedBox(key: ValueKey('none'), width: double.infinity),
          };
          final showLocate =
              state.location != LocationStatus.explain &&
              state.destination == null;
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: mapBuilder(
                    MapProps(
                      me: state.me,
                      places: state.places,
                      destination: state.destination,
                      camera: _camera,
                      onLongPress: cubit.dropPin,
                      dark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
                // Ride mode slides the search bar and chips away.
                SafeArea(
                  child: AnimatedSlide(
                    offset: riding ? const Offset(0, -1.4) : Offset.zero,
                    duration: still ? Duration.zero : motion.base,
                    curve: motion.ease,
                    child: AnimatedOpacity(
                      opacity: riding ? 0 : 1,
                      duration: still ? Duration.zero : motion.base,
                      child: IgnorePointer(
                        ignoring: riding,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SearchBarButton(
                                onTap: () => _search(context),
                                onAccount: () =>
                                    context.push<void>(Routes.settings),
                              ),
                              const SizedBox(height: 10),
                              PlaceChips(
                                places: state.places,
                                onTap: (place) =>
                                    cubit.select(Destination.fromSaved(place)),
                                onLongPress: (place) =>
                                    _editPlace(context, place),
                                onAdd: () => _search(context),
                              ),
                              const UpdateBanner(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    child: AnimatedOpacity(
                      opacity: showLocate ? 1 : 0,
                      duration: motion.quick,
                      child: IgnorePointer(
                        ignoring: !showLocate,
                        child: state.location == LocationStatus.denied
                            ? FilledButton.icon(
                                onPressed: cubit.askForLocation,
                                icon: const Icon(
                                  Icons.location_disabled_outlined,
                                ),
                                label: Text(l.turnOnLocation),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.board,
                                  foregroundColor: colors.onBoard,
                                  iconColor: colors.amber,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            : Material(
                                color: colors.board,
                                borderRadius: BorderRadius.circular(14),
                                child: IconButton(
                                  tooltip: l.showMe,
                                  iconSize: 26,
                                  padding: const EdgeInsets.all(14),
                                  onPressed: state.me == null
                                      ? null
                                      : () =>
                                            _camera.flyTo(state.me!, zoom: 16),
                                  icon: Icon(
                                    Icons.my_location,
                                    color: colors.amber,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedSwitcher(
                    duration: still ? Duration.zero : motion.base,
                    switchInCurve: motion.ease,
                    switchOutCurve: motion.ease,
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                    child: bottom,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
