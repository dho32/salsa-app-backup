import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/common/measurement_limits.dart'; // <-- JANGAN LUPA IMPORT INI

import '../../../components/constants.dart';
import '../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../../models/service_call/validation_status.dart';

class ProofOfServiceDetailBloc extends Bloc<ProofOfServiceDetailEvent, ProofOfServiceDetailState> {
  final ProofOfServiceDetailRepository repository;

  ProofOfServiceDetailBloc(this.repository) : super(ProofOfServiceDetailInitial()) {
    on<FetchProofOfServiceDetail>((event, emit) async {
      emit(ProofOfServiceDetailLoading());
      try {
        final cacheBox = Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
        ProofOfServiceDetailModel? cachedData = cacheBox.get(event.transNo.trim().toUpperCase());

        // 🔥 ANTI-BUG CACHE LAMA 🔥
        if (cachedData != null) {
          bool isCacheCorrupted = cachedData.detail.any((d) => d.isGeneric && d.unitIndex == 0);
          if (isCacheCorrupted) {
            await cacheBox.delete(event.transNo.trim().toUpperCase());
            cachedData = null;
          }
        }

        // 1. Tentukan Data Akhir (Dari Cache atau API)
        ProofOfServiceDetailModel finalData;
        if (cachedData != null) {
          finalData = cachedData;
        } else {
          finalData = await repository.fetchProofOfServiceDetail(event.transNo);
          await cacheBox.put(event.transNo.trim().toUpperCase(), finalData);
        }

        // --- [TAMBAHAN: RACIK LIMIT DINAMIS POS] ---
        // 2. Buka kotak Global Master dari Hive
        // (Pastikan kAppConfigBox sesuai dengan nama konstanta config Akang)
        final configBox = Hive.box(kAppConfigBox);
        Map<String, MeasurementLimits> mergedLimits = {};

        // Ambil limit global untuk POS (biasanya limits_pos_after)
        final rawLimits = configBox.get('limits_pos_after');
        if (rawLimits is Map) {
          rawLimits.forEach((key, value) {
            if (key is String && value is MeasurementLimits) {
              mergedLimits[key] = value;
            }
          });
        }

        // 3. Timpa dengan data dari API (Suhu AC, Ampere, Volt, PSI)
        if (finalData.customLimitsAfter != null && finalData.customLimitsAfter!.isNotEmpty) {
          finalData.customLimitsAfter!.forEach((key, value) {
            mergedLimits[key] = value;
          });
        }
        // ----------------------------------------

        // 4. Kalkulasi Status & Emit
        final result = await _calculateValidationStatuses(finalData.detail, event.transNo);
        emit(ProofOfServiceDetailLoaded(
          finalData,
          result['statuses'],
          savedSerials: result['serials'],
          limitsMap: mergedLimits, // <-- INJECT LIMIT DINAMIS KE STATE
        ));

      } catch (e) {
        emit(ProofOfServiceDetailError("Gagal memuat detail data. Periksa koneksi internet Anda dan coba lagi."));
      }
    });
  }

  Future<Map<String, dynamic>> _calculateValidationStatuses(List<ProofOfServiceItemDetail> details, String transNo) async {
    final box = await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
    final statuses = <String, ValidationStatus>{};
    final serials = <String, String>{}; // 🔥 Keranjang SN

    for (final detail in details) {
      final mapKey = detail.isGeneric
          ? '${detail.unitType}_${detail.unitIndex}'
          : detail.serialNo.trim().toUpperCase();

      PosValidationEntryModel? draft;

      if (detail.isGeneric) {
        final hiveKey = 'GEN_${transNo}_${detail.unitIndex}_${detail.unitType}';
        draft = box.get(hiveKey);
        draft ??= box.values.firstWhereOrNull((e) =>
        e.transNo == transNo && e.unitIndex == detail.unitIndex && e.articleType == detail.unitType);
      } else {
        try { draft = box.get(mapKey); } catch (e) { await box.delete(mapKey); draft = null; }
      }

      if (draft != null) {
        bool isComplete = draft.isCompleted ?? false;
        statuses[mapKey] = isComplete ? ValidationStatus.completed : ValidationStatus.inProgress;

        if (detail.isGeneric && draft.serialNo.isNotEmpty && !draft.serialNo.startsWith('AC')) {
          serials[mapKey] = draft.serialNo;
        }
      } else {
        statuses[mapKey] = ValidationStatus.notStarted;
      }
    }
    return {'statuses': statuses, 'serials': serials};
  }
}