// lib/blocs/proof_of_service_detail/proof_of_service_detail_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:salsa/components/constants.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_response.dart';

part 'proof_of_service_detail_event.dart';

part 'proof_of_service_detail_state.dart';

class ProofOfServiceDetailBloc
    extends Bloc<ProofOfServiceDetailEvent, ProofOfServiceDetailState> {
  ProofOfServiceDetailBloc() : super(ProofOfServiceDetailInitial()) {
    on<FetchProofOfServiceDetail>(_onFetchProofOfServiceDetail);
    on<UpdateProofOfServiceDetail>(_onUpdateProofOfServiceDetail);
    on<SaveProofOfServiceDetail>(_onSaveProofOfServiceDetail);
  }

  Future<void> _onFetchProofOfServiceDetail(
    FetchProofOfServiceDetail event,
    Emitter<ProofOfServiceDetailState> emit,
  ) async {
    emit(ProofOfServiceDetailLoading());
    try {
      final unitInfo = event.unit;
      final box = await Hive.openBox<ProofOfServiceDetailData>(
          kProofOfServiceHiveBox);
      final hiveKey = '${event.transNo}-${unitInfo.serialNo}';
      final savedData = box.get(hiveKey) ?? ProofOfServiceDetailData();
      emit(ProofOfServiceDetailLoaded(
        transNo: event.transNo,
        unitInfo: unitInfo,
        inputData: savedData,
      ));
    } catch (e) {
      emit(ProofOfServiceDetailError(e.toString()));
    }
  }

  void _onUpdateProofOfServiceDetail(
    UpdateProofOfServiceDetail event,
    Emitter<ProofOfServiceDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is ProofOfServiceDetailLoaded) {
      emit(ProofOfServiceDetailLoaded(
        transNo: currentState.transNo,
        unitInfo: currentState.unitInfo,
        inputData: event.newData,
      ));
    }
  }

  Future<void> _onSaveProofOfServiceDetail(
    SaveProofOfServiceDetail event,
    Emitter<ProofOfServiceDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProofOfServiceDetailLoaded) {
      final data = currentState.inputData;
      if (data.imagePaths.isEmpty) {
        return;
      }

      final box =
          await Hive.openBox<ProofOfServiceDetailData>(kProofOfServiceHiveBox);
      final hiveKey =
          '${currentState.transNo}-${currentState.unitInfo.serialNo}';

      await box.put(hiveKey, data);
    }
  }
}
