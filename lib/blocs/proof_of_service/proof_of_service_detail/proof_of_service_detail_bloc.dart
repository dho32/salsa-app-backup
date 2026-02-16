import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

import '../../../components/constants.dart';
import '../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../../models/service_call/validation_status.dart';

class ProofOfServiceDetailBloc
    extends Bloc<ProofOfServiceDetailEvent, ProofOfServiceDetailState> {
  final ProofOfServiceDetailRepository repository;

  ProofOfServiceDetailBloc(this.repository)
      : super(ProofOfServiceDetailInitial()) {

    on<FetchProofOfServiceDetail>((event, emit) async {
      emit(ProofOfServiceDetailLoading());

      try {
        ProofOfServiceDetailModel? cachedData;

        // TAHAP 1: Baca Cache
        try {
          final cacheBox = Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          cachedData = cacheBox.get(event.transNo.trim().toUpperCase());
        } catch (e) {
          print("🟡 Cache Error: $e");
        }

        // TAHAP 2: Gunakan Cache
        if (cachedData != null) {
          print("✅ Data Detail found in cache.");
          final statuses = await _calculateValidationStatuses(cachedData.detail);
          emit(ProofOfServiceDetailLoaded(cachedData, statuses));
          return;
        }

        // TAHAP 3: Ambil API
        print("🟡 Fetching from API...");
        final dataFromApi = await repository.fetchProofOfServiceDetail(event.transNo);

        final cacheBox = Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
        await cacheBox.put(event.transNo.trim().toUpperCase(), dataFromApi);
        print("💾 API Data cached.");

        final statuses = await _calculateValidationStatuses(dataFromApi.detail);
        emit(ProofOfServiceDetailLoaded(dataFromApi, statuses));

      } catch (e) {
        print("🔴 Error Fetching POS Detail: $e");
        emit(ProofOfServiceDetailError(
            "Gagal memuat detail data. Periksa koneksi internet Anda dan coba lagi."));
      }
    });
  }

  // --- HELPER VALIDATION STATUS ---
  Future<Map<String, ValidationStatus>> _calculateValidationStatuses(
      List<ProofOfServiceItemDetail> details) async {

    final box = Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);
    final statuses = <String, ValidationStatus>{};

    for (final detail in details) {
      final key = detail.serialNo.trim().toUpperCase();
      PosValidationEntryModel? draft;

      try {
        draft = box.get(key);
      } catch (e) {
        await box.delete(key);
        draft = null;
      }

      if (draft != null) {
        // [FIX NULL SAFETY] Gunakan tanda seru (!)
        if (draft!.reffLineNo != detail.reffLineNo) {
          try {
            final updatedDraft = draft!.copyWith( // Tambah '!'
              reffLineNo: detail.reffLineNo,
            );
            await box.put(key, updatedDraft);
            print("🔄 Auto-sync Reff Line No: ${detail.reffLineNo}");

            // Update reference lokal
            draft = updatedDraft;
          } catch (e) {
            print("⚠️ Gagal update draft: $e");
          }
        }

        // [FIX NULL SAFETY] Tambah '!' sebelum mengakses property isCompleted
        bool isComplete = draft!.isCompleted ?? false;
        statuses[key] = isComplete ? ValidationStatus.completed : ValidationStatus.inProgress;

      } else {
        statuses[key] = ValidationStatus.notStarted;
      }
    }

    for (final detail in details) {
      final key = detail.serialNo.trim().toUpperCase();
      statuses.putIfAbsent(key, () => ValidationStatus.notStarted);
    }

    return statuses;
  }
}