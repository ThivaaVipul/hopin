import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/features/search/cubit/search_cubit.dart';
import 'package:hopin/l10n/app_localizations.dart';

/// Where to: recents until you search, then results. The page is a board, so
/// each place's Sinhala name shows in amber, as on the bus.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.near, this.hint});

  final GeoPoint? near;

  /// In the empty field: "Where to?" unless what's searched for is named.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.maybeOf(context);
    if (workspace == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (context) =>
          SearchCubit(context.read<Nominatim>(), workspace.recents, near: near),
      child: _SearchView(hint: hint),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({this.hint});

  final String? hint;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<SearchCubit>();
    return Scaffold(
      backgroundColor: colors.board,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l.back,
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back, color: colors.onBoard),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: cubit.search,
                      style: context.text.titleLarge?.copyWith(
                        color: colors.onBoard,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: colors.amber,
                      decoration: InputDecoration(
                        hintText: widget.hint ?? l.whereTo,
                        hintStyle: TextStyle(color: colors.onBoardMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.search,
                    onPressed: () => cubit.search(_query.text),
                    icon: Icon(Icons.search, color: colors.amber),
                  ),
                ],
              ),
            ),
            BlocBuilder<SearchCubit, SearchState>(
              buildWhen: (a, b) => a.status != b.status,
              builder: (context, state) => SizedBox(
                height: 3,
                child: state.status == SearchStatus.searching
                    ? LinearProgressIndicator(
                        color: colors.amber,
                        backgroundColor: colors.amberDim,
                      )
                    : null,
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) => switch (state.status) {
                  SearchStatus.failed => _Message(l.searchFailed),
                  SearchStatus.done when state.results.isEmpty => _Message(
                    l.nothingFound,
                  ),
                  SearchStatus.done || SearchStatus.searching
                      when state.results.isNotEmpty =>
                    _Results(places: state.results),
                  _ => _Results(
                    places: state.recents,
                    heading: state.recents.isEmpty ? null : l.recent,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.places, this.heading});

  final List<Destination> places;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Text(
              heading!,
              style: context.text.titleSmall?.copyWith(
                color: colors.onBoardMuted,
              ),
            ),
          ),
        for (final place in places)
          InkWell(
            onTap: () => context.pop(place),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.place_outlined,
                      color: colors.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.names.inLanguage(language) ?? place.area ?? '',
                          style: context.text.titleMedium?.copyWith(
                            color: colors.onBoard,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (place.names.si != null)
                          Text(
                            place.names.si!,
                            style: context.text.titleMedium?.copyWith(
                              fontFamily: sinhalaFamily,
                              color: colors.amber,
                            ),
                          ),
                        if (place.area != null)
                          Text(
                            place.area!,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.onBoardMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    child: Text(
      text,
      style: context.text.titleMedium?.copyWith(
        color: context.colors.onBoardMuted,
      ),
    ),
  );
}
