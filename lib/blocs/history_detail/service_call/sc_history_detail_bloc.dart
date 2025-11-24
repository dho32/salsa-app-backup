// blocs/history/sc_history_detail_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/history_detail/service_call/sc_history_detail_event.dart';
import 'package:salsa/blocs/history_detail/service_call/sc_history_detail_repository.dart';
import 'package:salsa/blocs/history_detail/service_call/sc_history_detail_state.dart';

class ScHistoryDetailBloc
    extends Bloc<ScHistoryDetailEvent, ScHistoryDetailState> {
  final ScHistoryDetailRepository repository;

  ScHistoryDetailBloc(this.repository) : super(ScHistoryDetailInitial()) {
    on<FetchScHistoryDetail>((event, emit) async {
      emit(ScHistoryDetailLoading());
      try {
        final result = await repository.fetchScHistoryDetail(event.transNo);
        emit(ScHistoryDetailLoaded(result));
      } catch (e) {
        emit(ScHistoryDetailError(e.toString()));
      }
    });
  }
}
