// lib/blocs/schedule_list/schedule_list_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:salsa/blocs/schedule/schedule_list/schedule_list_repository.dart';

import '../../../models/schedule/schedule_list_model.dart';

part 'schedule_list_event.dart';

part 'schedule_list_state.dart';

class ScheduleListBloc extends Bloc<ScheduleListEvent, ScheduleListState> {
  final ScheduleListRepository repository;
  int _page = 0;
  String _status = '';
  String _keyword = '';
  String _maintenanceBy = '';
  bool _isLoadingMore = false;
  List<ScheduleListItemModel> _allData = [];

  ScheduleListBloc({required this.repository}) : super(ScheduleListInitial()) {
    on<UpdateScheduleList>(_onFetchScheduleList);
    on<FetchScheduleList>(_onFetchScheduleMore);
  }

  Future<void> _onFetchScheduleList(
    UpdateScheduleList event,
    Emitter<ScheduleListState> emit,
  ) async {
    _page = 0;
    _status = event.status;
    _keyword = event.keyword;
    _maintenanceBy = event.maintenanceBy;
    emit(ScheduleListLoading());

    try {
      final response = await repository.fetchSchedules(
        page: _page,
        status: _status,
        keyword: _keyword,
        maintenanceBy: _maintenanceBy,
      );
      _allData = response.list;
      _page++;
      emit(ScheduleListLoaded(
          list: _allData, hasMore: response.hasMore, page: _page));
    } catch (e) {
      emit(ScheduleListError(e.toString()));
    }
  }

  Future<void> _onFetchScheduleMore(
      FetchScheduleList event, Emitter emit) async {
    if (state is ScheduleListLoaded && !_isLoadingMore) {
      final currentState = state as ScheduleListLoaded;
      if (!currentState.hasMore) return;
      _isLoadingMore = true;
      try {
        final response = await repository.fetchSchedules(
          page: _page,
          status: _status,
          keyword: _keyword,
          maintenanceBy: _maintenanceBy,
        );
        _allData.addAll(response.list);
        _page++;

        emit(ScheduleListLoaded(
            list: _allData, hasMore: response.hasMore, page: _page));
      } catch (e) {
        emit(ScheduleListError(e.toString()));
      } finally {
        _isLoadingMore = false;
      }
    }
  }
}
