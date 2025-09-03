import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_list/service_call_list_event.dart';
import 'package:salsa/blocs/service_call/service_call_list/service_call_list_repository.dart';
import 'package:salsa/blocs/service_call/service_call_list/service_call_list_state.dart';

import '../../../models/service_call/service_call_list_model.dart';

class ServiceCallListBloc extends Bloc<ServiceCallListEvent, ServiceCallListState> {
  final ServiceCallListRepository repository;
  int _page = 0;
  String _status = '';
  String _keyword = '';
  String _maintenanceBy = '';
  bool _isLoadingMore = false;
  List<ServiceCallListModel> _allData = [];

  ServiceCallListBloc({required this.repository}) : super(ServiceCallListInitial()) {
    on<UpdateServiceCallFilter>(_onUpdateFilter);
    on<FetchServiceCallList>(_onFetchMore);
  }

  Future<void> _onUpdateFilter(UpdateServiceCallFilter event, Emitter emit) async {
    _page = 0;
    _status = event.status;
    _keyword = event.keyword;
    _maintenanceBy = event.maintenanceBy;
    emit(ServiceCallListLoading());

    try {
      final response = await repository.fetchServiceCalls(
        page: _page,
        status: _status,
        keyword: _keyword,
        maintenanceBy: _maintenanceBy,
      );
      _allData = response.list;
      _page++;
      emit(ServiceCallListLoaded(list: _allData, hasMore: response.hasMore));
    } catch (e) {
      emit(ServiceCallListError(e.toString()));
    }
  }

  Future<void> _onFetchMore(FetchServiceCallList event, Emitter emit) async {
    if (state is ServiceCallListLoaded && !_isLoadingMore) {
      final currentState = state as ServiceCallListLoaded;

      if (!currentState.hasMore) return;

      _isLoadingMore = true;
      try {
        final response = await repository.fetchServiceCalls(
          page: _page,
          status: _status,
          keyword: _keyword,
          maintenanceBy: _maintenanceBy,
        );
        _allData.addAll(response.list);
        _page++;
        emit(ServiceCallListLoaded(list: _allData, hasMore: response.hasMore));
      } catch (e) {
        emit(ServiceCallListError(e.toString()));
      } finally {
        _isLoadingMore = false;
      }
    }
  }
}
