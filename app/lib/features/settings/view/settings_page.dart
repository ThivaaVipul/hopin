import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/board_choice.dart';
import 'package:hopin/app/widgets/led_dots.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/data/app_settings.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/update/updates.dart';
import 'package:hopin/features/home/widgets/home_parts.dart';
import 'package:hopin/features/home/widgets/maker_steps.dart';
import 'package:hopin/features/settings/cubit/settings_cubit.dart';
import 'package:hopin/features/settings/widgets/stage_editor.dart';
import 'package:hopin/features/update/cubit/update_cubit.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Settings (docs/PLAN.md, Settings and updates): you, your places, the
/// alerts, the language, this phone, updates and sign out, on one page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey(workspace.uid),
      create: (context) {
        final cubit = SettingsCubit(workspace, context.read<GuideService>());
        unawaited(cubit.start());
        return cubit;
      },
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Notifications and the battery state change in Android's settings.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<SettingsCubit>().checkPhone()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _editPlace(SavedPlace place) async {
    final cubit = context.read<SettingsCubit>();
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

  Future<void> _editStage(int? index) async {
    final cubit = context.read<SettingsCubit>();
    final l = AppLocalizations.of(context);
    final stages = cubit.state.stages;
    final stage = index == null ? cubit.nextStage() : stages[index];
    final edit = await showStageEditor(
      context,
      title: index == stages.length - 1 ? l.getOffNext : l.getReady,
      stage: stage,
      taken: {
        for (final (i, other) in stages.indexed)
          if (i != index) other.metres,
      },
      canRemove: index != null && stages.length > 1,
      onTry: (pattern) => unawaited(cubit.tryPattern(pattern)),
    );
    switch (edit) {
      case SaveStage(:final stage):
        await cubit.saveStage(index, stage);
      case RemoveStage():
        if (index != null) await cubit.removeStage(index);
      case null:
        break;
    }
  }

  Future<void> _batteryGuide() async {
    final cubit = context.read<SettingsCubit>();
    await cubit.askToRunInBackground();
    if (!mounted || cubit.state.maker == PhoneMaker.other) return;
    await showMakerSteps(
      context,
      cubit.state.maker,
      onOpenSettings: () => unawaited(cubit.openMakerSettings()),
    );
  }

  Future<void> _signOut() async {
    final session = context.read<SessionCubit>();
    await context.read<GuideService>().end();
    await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settings),
        backgroundColor: colors.page,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const _Account(),
            _Section(
              title: l.places,
              child: state.places.isEmpty
                  ? _Line(text: l.noPlaces, muted: true)
                  : ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: (from, to) =>
                          unawaited(cubit.reorder(from, to)),
                      children: [
                        for (final (index, place) in state.places.indexed)
                          _PlaceRow(
                            key: ValueKey(place.id),
                            place: place,
                            index: index,
                            onTap: () => _editPlace(place),
                          ),
                      ],
                    ),
            ),
            _Section(
              title: l.rides,
              child: _Line(
                text: l.allRides,
                onTap: () => unawaited(context.push<void>(Routes.rides)),
                action: Icon(
                  Icons.chevron_right,
                  color: context.colors.onBoardMuted,
                ),
              ),
            ),
            _Section(
              title: l.alerts,
              child: Column(
                children: [
                  for (final (index, stage) in state.stages.indexed)
                    _StageRow(
                      name: index == state.stages.length - 1
                          ? l.getOffNext
                          : l.getReady,
                      stage: stage,
                      onTap: () => _editStage(index),
                    ),
                  if (state.stages.length < maxStages)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => _editStage(null),
                        icon: const Icon(Icons.add),
                        label: Text(l.addStage),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.amber,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              title: l.language,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _LanguagePicker(onPick: cubit.setLanguage),
              ),
            ),
            _Section(
              title: l.thisPhone,
              child: Column(
                children: [
                  _Detection(
                    detection: state.detection,
                    onChanged: (on) => unawaited(
                      cubit.setDetection(
                        on: on,
                        language: Localizations.localeOf(context).languageCode,
                      ),
                    ),
                  ),
                  if (kDebugMode)
                    _Line(
                      text: l.pretendRide,
                      muted: true,
                      action: _BoardButton(
                        label: l.start,
                        onPressed: () => unawaited(cubit.detectNow()),
                      ),
                    ),
                  _Line(
                    text: state.notificationsOn == false
                        ? l.notificationsOff
                        : l.notificationsOn,
                    muted: state.notificationsOn != false,
                    action: state.notificationsOn == false
                        ? _BoardButton(
                            label: l.turnOn,
                            onPressed: () =>
                                unawaited(cubit.turnOnNotifications()),
                          )
                        : null,
                  ),
                  _Line(
                    text: state.runsInBackground == false
                        ? l.mayBeStopped
                        : l.runsInBackground,
                    muted: state.runsInBackground != false,
                    action: _BoardButton(
                      label: l.batteryGuide,
                      onPressed: () => unawaited(_batteryGuide()),
                    ),
                  ),
                ],
              ),
            ),
            _Section(title: l.updates, child: const _Updates()),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => unawaited(_signOut()),
                style: TextButton.styleFrom(
                  foregroundColor: colors.urgent,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(l.signOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who is signed in, and rider access (the claim set by the owner).
class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        final account = session.account;
        if (account == null) return const SizedBox.shrink();
        return _Board(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.hello(account.firstName),
                style: context.text.headlineSmall?.copyWith(
                  color: colors.onBoard,
                ),
              ),
              const SizedBox(height: 10),
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
                  if (!account.isRider)
                    _BoardButton(
                      label: l.checkAgain,
                      onPressed: () =>
                          unawaited(context.read<SessionCubit>().refresh()),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            title,
            style: context.text.titleMedium?.copyWith(
              color: context.colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _Board(child: child),
      ],
    ),
  );
}

/// A flat board card, as in the Look.
class _Board extends StatelessWidget {
  const _Board({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.board,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class _Line extends StatelessWidget {
  const _Line({
    required this.text,
    this.muted = false,
    this.action,
    this.onTap,
  });

  final String text;
  final bool muted;
  final Widget? action;

  /// The whole line opens something.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    final line = _content(context);
    return onTap == null
        ? line
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: line,
          );
  }

  Widget _content(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: context.text.bodyLarge?.copyWith(
                  color: muted ? colors.onBoardMuted : colors.onBoard,
                ),
              ),
            ),
            if (action case final action?)
              // A long label (Tamil, large text) wraps rather than squeezing
              // the line to nothing.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                ),
                child: action,
              ),
          ],
        ),
      ),
    );
  }
}

/// Notice bus rides: the switch, and what's missing when it can't be on.
class _Detection extends StatelessWidget {
  const _Detection({required this.detection, required this.onChanged});

  final Detection? detection;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final detection = this.detection;
    final missing = detection == null || detection.on
        ? null
        : !detection.activity
        ? l.needsActivity
        : !detection.allTheTime
        ? l.needsAllTheTime
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          text: l.noticeRides,
          action: Switch(
            value: detection?.on ?? false,
            onChanged: detection == null ? null : onChanged,
            activeThumbColor: colors.onAmber,
            activeTrackColor: colors.amber,
            inactiveThumbColor: colors.onBoardMuted,
            inactiveTrackColor: colors.board,
          ),
        ),
        if (missing != null &&
            (detection?.activity == true || detection?.allTheTime == true))
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, bottom: 12),
            child: Text(
              missing,
              style: context.text.bodyMedium?.copyWith(
                color: colors.onBoardUrgent,
              ),
            ),
          ),
      ],
    );
  }
}

class _BoardButton extends StatelessWidget {
  const _BoardButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: context.colors.amber,
      minimumSize: const Size(0, 48),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    super.key,
    required this.place,
    required this.index,
    required this.onTap,
  });

  final SavedPlace place;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final placeName = place.names.inLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return Material(
      color: colors.board,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(kindIcon(place.kind), color: colors.amber),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.name,
                      style: context.text.titleMedium?.copyWith(
                        color: colors.onBoard,
                      ),
                    ),
                    if (placeName != null && placeName != place.name)
                      Text(
                        placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.onBoardMuted,
                        ),
                      ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Tooltip(
                  message: l.reorder,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(Icons.drag_handle, color: colors.onBoardMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.name,
    required this.stage,
    required this.onTap,
  });

  final String name;
  final GuideStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: text.titleMedium?.copyWith(color: colors.onBoard),
                    ),
                    Text(
                      patternName(l, stage.pattern),
                      style: text.bodyMedium?.copyWith(
                        color: colors.onBoardMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                distanceText(l, stage.metres),
                style: text.titleLarge?.copyWith(color: colors.amber),
              ),
              Icon(Icons.chevron_right, color: colors.onBoardMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.onPick});

  final Future<void> Function(String code) onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        for (final code in AppSettings.languages)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: BoardChoice(
                label: code == 'ta' ? l.tamil : l.english,
                selected: code == current,
                onTap: () => unawaited(onPick(code)),
              ),
            ),
          ),
      ],
    );
  }
}

class _Updates extends StatelessWidget {
  const _Updates();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final cubit = context.read<UpdateCubit>();
        final release = state.installed > 0;
        final version = release
            ? l.versionLabel(versionOf(state.installed))
            : l.devBuild;
        final status = switch (state.phase) {
          UpdatePhase.upToDate => l.upToDate,
          UpdatePhase.checkFailed => l.checkFailed,
          _ when state.offered => l.updateReady(state.latest!.version),
          _ => null,
        };
        return Column(
          children: [
            _Line(
              text: version,
              action: release
                  ? _BoardButton(
                      label: state.offered ? l.update : l.checkUpdates,
                      onPressed: switch (state.phase) {
                        UpdatePhase.checking || UpdatePhase.downloading => null,
                        _ when state.offered => () => unawaited(cubit.update()),
                        _ => () => unawaited(cubit.check(now: true)),
                      },
                    )
                  : null,
            ),
            if (state.phase == UpdatePhase.checking)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12, bottom: 14),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LedDots(count: 5, lightUp: true),
                ),
              )
            else if (status != null)
              _Line(text: status, muted: true),
          ],
        );
      },
    );
  }
}
