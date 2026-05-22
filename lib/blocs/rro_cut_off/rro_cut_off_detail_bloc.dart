import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/rro_cut_off/rro_cut_off_repository.dart';
import 'rro_cut_off_detail_event.dart';
import 'rro_cut_off_detail_state.dart';

class RROCutOffDetailBloc extends Bloc<RROCutOffDetailEvent, RROCutOffDetailState> {
  final RROCutOffDetailRepository repository;

  RROCutOffDetailBloc(this.repository) : super(RROCutOffDetailInitial()) {
    on<FetchRROCutOffDetail>(_onFetchDetail);
  }

  Future<void> _onFetchDetail(
      FetchRROCutOffDetail event,
      Emitter<RROCutOffDetailState> emit,
      ) async {
    emit(RROCutOffDetailLoading());
    try {
      final result = await repository.fetchDetail(event.transNo, event.vendorId);
      emit(RROCutOffDetailLoaded(result));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(RROCutOffDetailError(errorMessage));
    }
  }
}