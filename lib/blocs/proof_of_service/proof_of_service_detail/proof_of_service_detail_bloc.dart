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

      // Gunakan satu blok try-catch utama untuk menangani semua kemungkinan error
      try {
        ProofOfServiceDetailModel? cachedData;

        // --- TAHAP 1: Coba baca cache dengan aman ---
        // Gunakan try-catch kecil khusus untuk operasi baca cache.
        try {
          final cacheBox =
              Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
          cachedData = cacheBox.get(event.transNo.trim().toUpperCase());
        } catch (e) {
          // Jika GAGAL membaca cache (karena data lama/rusak),
          // kita cetak pesannya, tapi biarkan aplikasi berjalan terus.
          print(
              "🟡 Gagal membaca cache (kemungkinan data lama). Akan mengambil dari API. Error: $e");
          // `cachedData` akan tetap null, sehingga alur akan lanjut ke Tahap 3.
        }

        // --- TAHAP 2: Proses cache jika berhasil dibaca ---
        if (cachedData != null) {
          print("✅ Data ditemukan di cache. Memproses...");
          final statuses =
              await _calculateValidationStatuses(cachedData.detail);
          emit(ProofOfServiceDetailLoaded(cachedData, statuses));
          return; // Berhasil, proses selesai.
        }

        // --- TAHAP 3: Jika cache kosong atau gagal dibaca, ambil dari API ---
        print("🟡 Cache kosong atau tidak valid. Mengambil data dari API...");
        final dataFromApi =
            await repository.fetchProofOfServiceDetail(event.transNo);

        // Timpa/simpan cache dengan data baru yang bersih
        final cacheBox =
            Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
        await cacheBox.put(event.transNo.trim().toUpperCase(), dataFromApi);
        print("💾 Data dari API berhasil disimpan/ditimpa ke cache.");

        final statuses = await _calculateValidationStatuses(dataFromApi.detail);
        emit(ProofOfServiceDetailLoaded(dataFromApi, statuses));
      } catch (e) {
        // --- TAHAP 4: Tangkap semua error lainnya ---
        // Blok ini akan menangkap error jika API gagal atau ada masalah tak terduga lainnya.
        print("🔴🔴 Gagal total memuat data: $e");
        emit(ProofOfServiceDetailError(
            "Gagal memuat detail data. Periksa koneksi internet Anda dan coba lagi."));
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
      PosValidationEntryModel? draft;

      // Tambahkan try-catch di sini untuk menangani data cache yang tidak kompatibel
      try {
        draft = box.get(key);
      } catch (e) {
        print('🔴 Gagal membaca draft validasi untuk SN $key. Menghapus data rusak...');
        // Jika gagal membaca, hapus data yang rusak agar tidak error lagi nanti
        await box.delete(key);
        // Anggap saja tidak ada draft
        draft = null;
      }

      if (draft != null) {
        if (draft.isCompleted) {
          statuses[key] = ValidationStatus.completed;
        } else {
          statuses[key] = ValidationStatus.inProgress;
        }
      } else {
        statuses[key] = ValidationStatus.notStarted;
      }
    }

    // Bagian ini tidak perlu diubah
    for (final detail in details) {
      final key = detail.serialNo.trim().toUpperCase();
      statuses.putIfAbsent(key, () => ValidationStatus.notStarted);
    }

    return statuses;
  }
}
