import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/history_detail/proof_of_service/pos_history_detail_event.dart';
import 'package:salsa/blocs/history_detail/proof_of_service/pos_history_detail_repository.dart';
import 'package:salsa/blocs/history_detail/proof_of_service/pos_history_detail_state.dart';

class PosHistoryDetailBloc
    extends Bloc<PosHistoryDetailEvent, PosHistoryDetailState> {
  final PosHistoryDetailRepository repository;

  PosHistoryDetailBloc(this.repository) : super(PosHistoryDetailInitial()) {
    on<FetchPosHistoryDetail>((event, emit) async {
      emit(PosHistoryDetailLoading());
      try {
        final result = await repository.fetchPosHistoryDetail(event.transNo);
        emit(PosHistoryDetailLoaded(result));
      } catch (e) {
        emit(PosHistoryDetailError(e.toString()));
      }
    });
  }
}
