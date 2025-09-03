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

    // ## EVENT HANDLER UTAMA DENGAN LOGIKA CACHE ##
    on<FetchProofOfServiceDetail>((event, emit) async {
      emit(ProofOfServiceDetailLoading());

      try {
        final cacheBox = Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
        final cachedData = cacheBox.get(event.transNo.trim().toUpperCase());

        // --- 1. CEK CACHE ---
        if (cachedData != null) {
          // JIKA CACHE ADA, GUNAKAN DATA LOKAL
          print("✅ Data ditemukan di cache untuk TransNo: ${event.transNo}");
          final statuses = await _calculateValidationStatuses(cachedData.detail);
          emit(ProofOfServiceDetailLoaded(cachedData, statuses));
          return; // Selesai. Tidak perlu ke jaringan.
        }

        // --- 2. JIKA CACHE KOSONG, AMBIL DARI JARINGAN ---
        print("🟡 Cache kosong. Mengambil data dari API untuk TransNo: ${event.transNo}");
        final dataFromApi = await repository.fetchProofOfServiceDetail(event.transNo);

        // --- 3. SIMPAN DATA BARU KE CACHE ---
        await cacheBox.put(event.transNo.trim().toUpperCase(), dataFromApi);
        print("💾 Data dari API berhasil disimpan ke cache.");

        final statuses = await _calculateValidationStatuses(dataFromApi.detail);
        emit(ProofOfServiceDetailLoaded(dataFromApi, statuses));

      } catch (e) {
        emit(ProofOfServiceDetailError("Gagal memuat data: ${e.toString()}"));
      }
    });
  }

  // Helper function
  Future<Map<String, ValidationStatus>> _calculateValidationStatuses(
      List<ProofOfServiceItemDetail> details) async {

    final box = Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);
    final statuses = <String, ValidationStatus>{};

    for (final detail in details) {
      final key = detail.serialNo.trim().toUpperCase();
      final draft = box.get(key);

      if (draft != null) {
        // logic untuk cek status card
        if (draft.photosAfter.isNotEmpty) {
          statuses[key] = ValidationStatus.completed;
        } else {
          statuses[key] = ValidationStatus.inProgress;
        }
      } else {
        // Jika tidak ada draft sama sekali, berarti belum dimulai
        statuses[key] = ValidationStatus.notStarted;
      }
    }

    // Pastikan semua detail punya status, bahkan yang belum ada di draft
    for (final detail in details) {
      final key = detail.serialNo.trim().toUpperCase();
      statuses.putIfAbsent(key, () => ValidationStatus.notStarted);
    }

    return statuses;
  }
}