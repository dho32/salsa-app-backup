import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

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
        // Jika cache lama masih nempel (unitIndex 0 semua), paksa hapus & ambil baru dari API!
        if (cachedData != null) {
          bool isCacheCorrupted = cachedData.detail.any((d) => d.isGeneric && d.unitIndex == 0);
          if (isCacheCorrupted) {
            print("⚠️ Cache lama terdeteksi. Menghapus cache...");
            await cacheBox.delete(event.transNo.trim().toUpperCase());
            cachedData = null;
          }
        }

        if (cachedData != null) {
          final result = await _calculateValidationStatuses(cachedData.detail, event.transNo);
          emit(ProofOfServiceDetailLoaded(cachedData, result['statuses'], savedSerials: result['serials']));
          return;
        }

        final dataFromApi = await repository.fetchProofOfServiceDetail(event.transNo);
        await cacheBox.put(event.transNo.trim().toUpperCase(), dataFromApi);

        final result = await _calculateValidationStatuses(dataFromApi.detail, event.transNo);
        emit(ProofOfServiceDetailLoaded(dataFromApi, result['statuses'], savedSerials: result['serials']));

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

        // 🔥 Ambil SN Asli yang diinput Teknisi untuk ditimpa ke UI
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