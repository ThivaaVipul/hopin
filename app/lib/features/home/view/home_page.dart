import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/features/home/cubit/home_cubit.dart';
import 'package:hopin/features/home/widgets/home_parts.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
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
      onResume: () => context.read<SessionCubit>().refresh(),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final motion = context.motion;
    final mapBuilder = context.read<MapBuilder>();
    final cubit = context.read<HomeCubit>();
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (before, now) =>
          before.destination?.point != now.destination?.point ||
          (before.me == null && now.me != null),
      listener: (context, state) {
        final target = state.destination?.point ?? state.me;
        if (target != null) {
          _camera.flyTo(target, zoom: state.destination == null ? 15 : 15.5);
        }
      },
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final Widget bottom = switch (state) {
            HomeState(location: LocationStatus.explain) => LocationCard(
              key: const ValueKey('location'),
              onContinue: cubit.continueToPermission,
              onNotNow: cubit.notNow,
            ),
            HomeState(:final destination?) => DestinationPanel(
              key: ValueKey(destination.point),
              destination: destination,
              me: state.me,
              resolving: state.resolving,
              onSave: () => _savePlace(context),
              onClose: cubit.clear,
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchBarButton(
                          onTap: () => _search(context),
                          onAccount: () => showAccountSheet(context),
                        ),
                        const SizedBox(height: 10),
                        PlaceChips(
                          places: state.places,
                          onTap: (place) =>
                              cubit.select(Destination.fromSaved(place)),
                          onLongPress: (place) => _editPlace(context, place),
                          onAdd: () => _search(context),
                        ),
                      ],
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
                    duration: motion.base,
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

/// Who is signed in, rider access, and signing out (until Settings, M1a4).
Future<void> showAccountSheet(BuildContext context) {
  final session = context.read<SessionCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.board,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) => BlocProvider.value(
      value: session,
      child: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final account = state.account;
          if (account == null) return const SizedBox.shrink();
          final l = AppLocalizations.of(context);
          final colors = context.colors;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.hello(account.firstName),
                    style: context.text.headlineSmall?.copyWith(
                      color: colors.onBoard,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      LedDots(count: 5, lit: account.isRider ? 5 : 1),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          account.isRider ? l.riderOn : l.riderWaiting,
                          style: context.text.titleMedium?.copyWith(
                            color: colors.onBoard,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!account.isRider)
                        TextButton(
                          onPressed: session.refresh,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.amber,
                          ),
                          child: Text(l.checkAgain),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          unawaited(session.signOut());
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onBoardMuted,
                        ),
                        child: Text(l.signOut),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
