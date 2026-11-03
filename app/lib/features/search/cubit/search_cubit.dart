import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/search/nominatim.dart';

enum SearchStatus { idle, searching, done, failed }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.results = const [],
    this.recents = const [],
  });

  final SearchStatus status;
  final List<Destination> results;
  final List<Destination> recents;

  SearchState copyWith({
    SearchStatus? status,
    List<Destination>? results,
    List<Destination>? recents,
  }) => SearchState(
    status: status ?? this.status,
    results: results ?? this.results,
    recents: recents ?? this.recents,
  );

  @override
  List<Object?> get props => [status, results, recents];
}

/// Searches on request (Nominatim's policy forbids searching as you type).
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._nominatim, RecentsRepository recents, {this.near})
    : super(const SearchState()) {
    _recents = recents.watch().listen(
      (list) => emit(state.copyWith(recents: list)),
    );
  }

  final Nominatim _nominatim;
  final GeoPoint? near;
  late final StreamSubscription<List<Destination>> _recents;
  int _latest = 0;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(state.copyWith(status: SearchStatus.idle, results: const []));
      return;
    }
    final mine = ++_latest;
    emit(state.copyWith(status: SearchStatus.searching));
    try {
      final results = await _nominatim.search(query, near: near);
      if (mine == _latest && !isClosed) {
        emit(state.copyWith(status: SearchStatus.done, results: results));
      }
    } on Exception catch (error, stack) {
      addError(error, stack);
      if (mine == _latest && !isClosed) {
        emit(state.copyWith(status: SearchStatus.failed));
      }
    }
  }

  @override
  Future<void> close() async {
    await _recents.cancel();
    return super.close();
  }
}
