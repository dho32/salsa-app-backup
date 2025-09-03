// lib/blocs/proof_of_service/proof_of_service_detail_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/schedule/proof_of_service/proof_of_service_repository.dart';
import 'package:salsa/components/constants.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_response.dart';
import '../../auth/auth_storage.dart';

part 'proof_of_service_event.dart';

part 'proof_of_service_state.dart';

class ProofOfServiceBloc
    extends Bloc<ProofOfServiceEvent, ProofOfServiceState> {
  final ProofOfServiceRepository repository;

  ProofOfServiceBloc({required this.repository}) : super(POSInitial()) {
    on<FetchPOSDetail>(_onFetchPOSDetail);
    on<UpdateMeasurements>(_onUpdateMeasurements);
  }

  Future<void> _onFetchPOSDetail(
    FetchPOSDetail event,
    Emitter<ProofOfServiceState> emit,
  ) async {
    emit(POSLoading());
    try {
      // 1. Ambil data mentah dari Repository, anggap ini sebagai data dasar
      final baseState = await repository.fetchPOSDetail(event.transNo);

      // 2. Siapkan variabel untuk menampung data yang akan diubah
      List<POSUnitItem> finalUnitList = [];
      POSMeasurementData finalMeasurements = baseState.measurements;

      // 3. Proses unit list untuk disinkronkan dengan Hive
      final box =
          await Hive.openBox<ProofOfServiceDetailData>(kProofOfServiceHiveBox);
      for (var unit in baseState.unitList) {
        final hiveKey = '${baseState.headerData.transNo}-${unit.serialNo}';
        final isFilled = box.containsKey(hiveKey);

        finalUnitList.add(POSUnitItem(
          articleNo: unit.articleNo,
          description: unit.description,
          serialNo: unit.serialNo,
          unitType: unit.unitType,
          articleNameUnit: unit.articleNameUnit,
          isDetailFilled: isFilled,
        ));
      }

      // 4. Proses teknisi jika datanya kosong
      if (baseState.measurements.technician.isEmpty) {
        final user = await AuthStorage.getUser();
        final userName = user['name'] ?? 'Teknisi Tidak Ditemukan';

        // Perbarui hanya variabel finalMeasurements
        finalMeasurements = POSMeasurementData(
          picInput: baseState.measurements.picInput,
          technician: [userName],
          temperatureIn: baseState.measurements.temperatureIn,
          temperatureOut: baseState.measurements.temperatureOut,
          serviceTime: baseState.measurements.serviceTime,
        );
      }

      // 5. PANCARKAN STATE FINAL HANYA SEKALI dengan semua data yang sudah diperbarui
      emit(baseState.copyWith(
        unitList: finalUnitList,
        measurements: finalMeasurements,
      ));
    } catch (e) {
      emit(POSError(e.toString()));
    }
  }

  void _onUpdateMeasurements(
    UpdateMeasurements event,
    Emitter<ProofOfServiceState> emit,
  ) {
    // Ambil state saat ini
    final currentState = state;
    if (currentState is POSLoaded) {
      // Pancarkan state baru dengan data pengukuran yang sudah diperbarui
      emit(currentState.copyWith(measurements: event.newMeasurements));
    }
  }
}
