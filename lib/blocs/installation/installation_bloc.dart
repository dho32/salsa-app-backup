import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';

// Imports Event & State
import '../../components/upload_s3_service.dart';
import '../../models/common/measurement_limits.dart';
import '../service/service_repository.dart';
import 'installation_event.dart';
import 'installation_state.dart';

// Imports Model
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';

// Import Repo
import 'installation_repository.dart';

class InstallationBloc extends Bloc<InstallationEvent, InstallationState> {
  final InstallationRepository repository;
  final ServiceTaskRepository serviceRepo;

  Box<InstallationEntryModel>? _draftBox;
  Box<InstallationDetailModel>? _taskBox;
  List<Map<String, String>> _technicianList = [];

  /// Cari NIK (technician_id) teknisi berdasarkan nama di technicianList.
  /// Kembalikan '' bila tidak ketemu (mis. nama diketik manual / di luar list).
  String _nikForName(String name) {
    if (name.isEmpty) return '';
    for (final t in _technicianList) {
      if (t['technician_name'] == name) return t['technician_id'] ?? '';
    }
    return '';
  }

  InstallationBloc({required this.repository})
      : serviceRepo = ServiceTaskRepository(),
        super(const InstallationState()) {
    on<LoadInstallationData>(_onLoadData);
    on<UpdateTeamInfo>(_onUpdateTeamInfo);
    on<SaveIndoorUnit>(_onSaveIndoor);
    on<SaveOutdoorUnit>(_onSaveOutdoor);
    on<SaveMaterialSet>(_onSaveMaterial);
    on<UpdateFinalPhotos>(_onUpdateFinalPhotos);
    on<SaveMaterialEvidence>(_onSaveMaterialEvidence);
    on<ValidateSerialNumbers>(_onValidateSerialNumbers);
    on<SubmitInstallationFinal>(_onSubmitFinal);
    on<UpdateTransportStatus>(_onUpdateTransportStatus);
    on<SaveStoreFrontPhoto>(_onSaveStoreFrontPhoto);
    on<UpdateTransportData>(_onUpdateTransportData);
    on<UpdateTidyingData>(_onUpdateTidyingData);
    on<UpdatePicInfo>(_onUpdatePicInfo);
    on<UpdatePicPhoto>(_onUpdatePicPhoto);
  }

  // --- 1. [DIREVISI] LOAD DATA DENGAN LIMIT DINAMIS ---
  Future<void> _onLoadData(
      LoadInstallationData event, Emitter<InstallationState> emit) async {
    emit(state.copyWith(status: InstallationStatus.loading));
    try {
      // A. Open Hive Boxes
      if (!Hive.isBoxOpen(kInstallationDraftBox)) {
        _draftBox = await Hive.openBox<InstallationEntryModel>(kInstallationDraftBox);
      } else {
        _draftBox = Hive.box<InstallationEntryModel>(kInstallationDraftBox);
      }

      if (!Hive.isBoxOpen(kInstallationDetailBox)) {
        _taskBox = await Hive.openBox<InstallationDetailModel>(kInstallationDetailBox);
      } else {
        _taskBox = Hive.box<InstallationDetailModel>(kInstallationDetailBox);
      }

      final user = await AuthStorage.getUser();
      final vendorId = user['maintenance_by'] ?? '';

      // B. AMBIL DETAIL TUGAS — OFFLINE-FIRST (stale-while-revalidate).
      //    1) Pakai cache dulu bila ada → render instan & aman offline.
      //    2) Tidak ada cache → wajib fetch API (first load).
      //    Revalidasi ke API menyusul di bagian F supaya metadata header
      //    (is_pic / ship_to / ship_to_mail) ikut fresh tanpa memblok layar.
      //    Tanpa revalidasi, cache lama bisa membekukan is_pic=true sehingga
      //    panel PIC tetap muncul walau backend sudah kirim is_pic=false.
      final InstallationDetailModel? cached = _taskBox?.get(event.transNo);
      InstallationDetailModel? taskDetail = cached;

      if (taskDetail == null) {
        try {
          if (vendorId.isEmpty) throw Exception("Vendor ID missing");
          taskDetail = await repository
              .getInstallationDetail(event.transNo, vendorId)
              .timeout(const Duration(seconds: 15));
          await _taskBox?.put(event.transNo, taskDetail);
        } catch (e) {
          emit(state.copyWith(
              status: InstallationStatus.failure,
              errorMessage:
                  "Gagal ambil detail tugas. Periksa koneksi internet Anda."));
          return;
        }
      }
      // Dijamin non-null di sini (cache ada, atau fetch sukses).
      final InstallationDetailModel detail = taskDetail;

      // C. Roster teknisi (resolve NIK teknisi 2/3 dari nama saat dropdown WH).
      final configBox = Hive.box(kAppConfigBox);
      final rawTechList = configBox.get('technician_list');
      if (rawTechList is List) {
        _technicianList = rawTechList.whereType<Map>().map((t) => {
              'technician_id': (t['technician_id'] ?? '').toString(),
              'technician_name': (t['technician_name'] ?? '').toString(),
            }).toList();
      }

      // D. LOAD / BUAT / REKONSILIASI DRAFT USER
      InstallationEntryModel? draft = _draftBox?.get(event.transNo);
      if (draft == null) {
        draft = InstallationEntryModel(
          transNo: event.transNo,
          vendorId: user['maintenance_by'] ?? '',
          vendorName: user['maintenance_by_name'] ?? '',
          technicianId: user['user_id'] ?? '',
          technician1Name: user['name'] ?? '',
          startDate: DateTime.now(),
          units: _buildUnitSkeleton(detail.targets),
        );
        await _draftBox?.put(event.transNo, draft);
      } else {
        // Draft lama bisa punya unit_index kembar / 0 (mis. dibuat saat cache
        // detail masih stale) → sinkronkan ulang ke targets sebagai sumber
        // kebenaran. Tanpa ini, semua kartu di list menunjuk unit yang sama
        // sehingga simpan 1 unit terlihat "mengubah semua".
        final repaired = _reconcileDraftUnits(draft, detail.targets);
        if (repaired != null) {
          draft = draft.copyWith(units: repaired);
          await _draftBox?.put(event.transNo, draft);
        }
      }

      // E. EMIT PERTAMA — instan dari cache / first-load.
      emit(state.copyWith(
        status: InstallationStatus.initial,
        taskDetail: detail,
        draftEntry: draft,
        availableIndoors: _calculateAvailableIndoors(draft),
        measurementLimits: _buildLimits(configBox, detail),
      ));

      // F. REVALIDATE — bila tadi dari cache & online, ambil versi fresh lalu
      //    re-emit agar is_pic / ship_to & data referensi terbaru menyusul.
      //    Gagal / offline → diam-diam tetap pakai tampilan cache.
      if (cached != null && vendorId.isNotEmpty) {
        try {
          final fresh = await repository
              .getInstallationDetail(event.transNo, vendorId)
              .timeout(const Duration(seconds: 15));
          await _taskBox?.put(event.transNo, fresh);

          // Cache tadi bisa stale (unit_index 0) sehingga draft ikut stale.
          // Rekonsiliasi lagi terhadap targets FRESH agar unit_index selaras.
          final repaired = _reconcileDraftUnits(draft, fresh.targets);
          if (repaired != null) {
            draft = draft.copyWith(units: repaired);
            await _draftBox?.put(event.transNo, draft);
          }

          if (!emit.isDone) {
            emit(state.copyWith(
              taskDetail: fresh,
              draftEntry: draft,
              availableIndoors: _calculateAvailableIndoors(draft),
              measurementLimits: _buildLimits(configBox, fresh),
            ));
          }
        } catch (_) {
          // Offline / gagal → biarkan tampilan cache.
        }
      }
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure, errorMessage: e.toString()));
    }
  }

  /// Gabungkan limit global (hasil login) dengan custom limit dari API transaksi.
  Map<String, MeasurementLimits> _buildLimits(
      Box configBox, InstallationDetailModel detail) {
    final Map<String, MeasurementLimits> finalLimits = {};
    final rawLimits = configBox.get('limits_sc_after');
    if (rawLimits is Map) {
      rawLimits.forEach((key, value) {
        if (key is String && value is MeasurementLimits) {
          finalLimits[key] = value;
        }
      });
    }
    final custom = detail.customLimitsAfter;
    if (custom != null && custom.isNotEmpty) {
      finalLimits.addAll(custom);
    }
    return finalLimits;
  }

  /// Skeleton unit awal dari targets. `unit_index` di targets adalah SATU-
  /// SATUNYA pembeda antar unit (article_no & line_no bisa sama semua), jadi
  /// ini sumber kebenaran identitas unit.
  List<InstallationUnitModel> _buildUnitSkeleton(
      List<InstallationTargetUnitModel> targets) {
    return targets
        .map((t) => InstallationUnitModel(
              unitIndex: t.unitIndex,
              articleType: t.unitType,
              serialNo: '',
              articleNo: t.articleNo,
              articleDesc: t.description,
              reffLineNo: t.reffLineNo,
              materials: InstallationMaterialsModel(),
              measurements: [],
              status: 'OPEN',
              materialStatus: 'OPEN',
            ))
        .toList();
  }

  /// Pastikan unit draft selaras dengan targets terbaru: setiap target punya
  /// tepat satu unit dengan key (articleType, unitIndex) yang benar.
  ///
  /// Draft lama yang dibuat sebelum `unit_index` terisi bisa punya unit_index
  /// kembar / semua 0 (default Hive saat field absen). Akibatnya matcher di
  /// list/bloc (`u.unitIndex == target.unitIndex`) mengembalikan unit pertama
  /// yang sama untuk semua kartu → "isi 1, berubah semua". Di sini kita deteksi
  /// & bangun ulang skeleton dari targets, membawa data lama BILA key-nya masih
  /// unik & cocok. Return null bila draft sudah sehat (tidak perlu diubah).
  List<InstallationUnitModel>? _reconcileDraftUnits(
      InstallationEntryModel draft, List<InstallationTargetUnitModel> targets) {
    if (targets.isEmpty) return null; // tak ada acuan → jangan sentuh draft.

    String keyOf(String type, int idx) => '$type#$idx';

    final targetKeys =
        targets.map((t) => keyOf(t.unitType, t.unitIndex)).toSet();
    final draftKeys =
        draft.units.map((u) => keyOf(u.articleType, u.unitIndex)).toList();
    final draftKeySet = draftKeys.toSet();

    final hasDuplicateKeys = draftKeys.length != draftKeySet.length;
    final coversAllTargets = draftKeySet.containsAll(targetKeys);

    // Sehat: tidak ada key kembar & semua target punya slot → biarkan apa adanya
    // (data yang sudah diinput tetap aman).
    if (!hasDuplicateKeys && coversAllTargets) return null;

    // Rusak/stale → bangun ulang dari targets. Bawa data lama per key BILA unik
    // (untuk key kembar, ambil yang pertama; sisanya dianggap ambigu → reset).
    final Map<String, InstallationUnitModel> byKey = {};
    for (final u in draft.units) {
      byKey.putIfAbsent(keyOf(u.articleType, u.unitIndex), () => u);
    }

    return targets.map((t) {
      final old = byKey[keyOf(t.unitType, t.unitIndex)];
      if (old != null) {
        // Pertahankan data lama, tapi paksa metadata target yang benar.
        return old.copyWith(
          unitIndex: t.unitIndex,
          articleType: t.unitType,
          articleNo: t.articleNo,
          articleDesc: t.description,
          reffLineNo: t.reffLineNo,
        );
      }
      return InstallationUnitModel(
        unitIndex: t.unitIndex,
        articleType: t.unitType,
        serialNo: '',
        articleNo: t.articleNo,
        articleDesc: t.description,
        reffLineNo: t.reffLineNo,
        materials: InstallationMaterialsModel(),
        measurements: [],
        status: 'OPEN',
        materialStatus: 'OPEN',
      );
    }).toList();
  }

  // --- METHODS UPDATE (TETAP SAMA) ---

  Future<void> _onUpdateTeamInfo(
      UpdateTeamInfo event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    final newDraft = draft.copyWith(
      technician2Name: event.technician2 ?? draft.technician2Name,
      technician3Name: event.technician3 ?? draft.technician3Name,
      technician2Id: event.technician2 != null
          ? _nikForName(event.technician2!)
          : draft.technician2Id,
      technician3Id: event.technician3 != null
          ? _nikForName(event.technician3!)
          : draft.technician3Id,
      startDate: event.startDate ?? draft.startDate,
    );
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(draftEntry: newDraft));
  }

  Future<void> _onSaveIndoor(
      SaveIndoorUnit event, Emitter<InstallationState> emit) async {
    emit(state.copyWith(status: InstallationStatus.loading));
    try {
      final draft = state.draftEntry!;
      var units = List<InstallationUnitModel>.from(draft.units);
      final index = units.indexWhere(
              (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'IN');
      InstallationUnitModel finalIndoor = event.unit;
      if (index >= 0) {
        if ((finalIndoor.pairedSerialNo == null ||
            finalIndoor.pairedSerialNo!.isEmpty) &&
            (units[index].pairedSerialNo != null &&
                units[index].pairedSerialNo!.isNotEmpty)) {
          finalIndoor =
              finalIndoor.copyWith(pairedSerialNo: units[index].pairedSerialNo);
        }
        units[index] = finalIndoor;
      } else {
        units.add(finalIndoor);
      }
      final outdoorIndex = units.indexWhere(
              (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'OUT');
      if (outdoorIndex != -1) {
        final existingOutdoor = units[outdoorIndex];
        if (existingOutdoor.pairedSerialNo != finalIndoor.serialNo) {
          units[outdoorIndex] = existingOutdoor.copyWith(
            pairedSerialNo: finalIndoor.serialNo,
          );
        }
        if (finalIndoor.pairedSerialNo != existingOutdoor.serialNo) {
          if (index >= 0) {
            units[index] =
                units[index].copyWith(pairedSerialNo: existingOutdoor.serialNo);
          } else {
            units[units.length - 1] = units[units.length - 1]
                .copyWith(pairedSerialNo: existingOutdoor.serialNo);
          }
        }
      }
      final newDraft = draft.copyWith(units: units);
      await _draftBox?.put(draft.transNo, newDraft);
      emit(state.copyWith(
        status: InstallationStatus.success,
        draftEntry: newDraft,
        availableIndoors: _calculateAvailableIndoors(newDraft),
        errorMessage: "",
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveOutdoor(
      SaveOutdoorUnit event, Emitter<InstallationState> emit) async {
    emit(state.copyWith(status: InstallationStatus.loading));
    try {
      final draft = state.draftEntry!;
      var units = List<InstallationUnitModel>.from(draft.units);
      final outIndex = units.indexWhere(
              (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'OUT');
      InstallationUnitModel finalOutdoor = event.unit;
      if (outIndex >= 0) {
        units[outIndex] = finalOutdoor;
      } else {
        units.add(finalOutdoor);
      }
      final indoorIndex = units.indexWhere(
              (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'IN');
      if (indoorIndex != -1) {
        final existingIndoor = units[indoorIndex];
        if (finalOutdoor.pairedSerialNo != existingIndoor.serialNo) {
          if (outIndex >= 0) {
            units[outIndex] = units[outIndex]
                .copyWith(pairedSerialNo: existingIndoor.serialNo);
          } else {
            units[units.length - 1] = units[units.length - 1]
                .copyWith(pairedSerialNo: existingIndoor.serialNo);
          }
        }
        if (existingIndoor.pairedSerialNo != finalOutdoor.serialNo) {
          units[indoorIndex] = existingIndoor.copyWith(
            pairedSerialNo: finalOutdoor.serialNo,
          );
        }
      }
      final newDraft = draft.copyWith(units: units);
      await _draftBox?.put(draft.transNo, newDraft);
      emit(state.copyWith(
        status: InstallationStatus.success,
        draftEntry: newDraft,
        availableIndoors: _calculateAvailableIndoors(newDraft),
        errorMessage: "",
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveMaterial(
      SaveMaterialSet event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    var units = List<InstallationUnitModel>.from(draft.units);
    final index = units.indexWhere(
            (u) => u.unitIndex == event.unitIndex && u.articleType == 'OUT');
    final String newStatus = event.isFinal ? 'COMPLETED' : 'DRAFT';
    if (index >= 0) {
      final oldUnit = units[index];
      units[index] = oldUnit.copyWith(
        materials: event.materials,
        materialStatus: newStatus,
      );
    } else {
      String articleNo = '';
      String articleDesc = 'Outdoor Unit';
      String reffLineNo = '';
      try {
        final target = state.taskDetail?.targets.firstWhere(
                (t) => t.unitIndex == event.unitIndex && t.unitType == 'OUT');
        if (target != null) {
          articleNo = target.articleNo;
          articleDesc = target.description;
          reffLineNo = target.reffLineNo;
        }
      } catch (_) {}
      final newUnit = InstallationUnitModel(
        serialNo: '',
        articleNo: articleNo,
        articleDesc: articleDesc,
        articleType: 'OUT',
        unitIndex: event.unitIndex,
        materials: event.materials,
        materialStatus: newStatus,
        reffLineNo: reffLineNo,
      );
      units.add(newUnit);
    }
    final newDraft = draft.copyWith(units: units);
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(
        status: InstallationStatus.success, draftEntry: newDraft));
  }

  Future<void> _onUpdateFinalPhotos(
      UpdateFinalPhotos event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry!;
    final newDraft = draft.copyWith(
      finalPhotos: event.photos,
      finalNote: event.note ?? draft.finalNote,
    );
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(draftEntry: newDraft));
  }

  List<String> _calculateAvailableIndoors(InstallationEntryModel draft) {
    return draft.units
        .where((u) =>
    u.articleType == 'IN' &&
        (u.pairedSerialNo == null || u.pairedSerialNo!.isEmpty))
        .map((u) => u.serialNo)
        .toList();
  }

  Future<void> _onSaveMaterialEvidence(
      SaveMaterialEvidence event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    List<MaterialEvidenceModel> evidences = List.from(draft.materialEvidences);
    final index = evidences.indexWhere((e) => e.key == event.key);
    final newEvidence = MaterialEvidenceModel(
      key: event.key,
      photoPath: event.path,
      title: event.title,
    );
    if (index >= 0) {
      evidences[index] = newEvidence;
    } else {
      evidences.add(newEvidence);
    }
    final newDraft = draft.copyWith(materialEvidences: evidences);
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(
        status: InstallationStatus.success, draftEntry: newDraft));
  }

  Future<void> _onValidateSerialNumbers(
      ValidateSerialNumbers event,
      Emitter<InstallationState> emit,
      ) async {
    emit(state.copyWith(status: InstallationStatus.validatingSN));
    try {
      final draft = state.draftEntry;
      if (draft == null) throw "Data draft kosong";
      final header = state.taskDetail?.header;
      if (header == null) throw "Data header kosong";
      final user = await AuthStorage.getUser();
      final String vendorCode = user['maintenance_by'] ?? '';
      List<Map<String, String>> itemsPayload = [];
      for (var unit in draft.units) {
        if (unit.serialNo.isNotEmpty) {
          itemsPayload.add({
            "serial_no": unit.serialNo,
            "unit_type": unit.articleType,
            "article_no": unit.articleNo
          });
        }
      }
      if (itemsPayload.isEmpty) {
        throw "Belum ada Serial Number yang diinput";
      }
      final result = await repository.validateSerialNumbers(
          transNo: header.transNo, vendorCode: vendorCode, items: itemsPayload);
      final resultData = result['result'];
      bool isValid = resultData['is_valid'] ?? false;
      if (isValid) {
        emit(state.copyWith(status: InstallationStatus.snValidationSuccess));
      } else {
        List invalidList = resultData['invalid_list'] ?? [];
        String errorMsg = "Validasi Gagal:\n";
        for (var item in invalidList) {
          errorMsg += "- ${item['serial_no']}: ${item['reason']}\n";
        }
        throw errorMsg.trim();
      }
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure,
          errorMessage: e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onSubmitFinal(
      SubmitInstallationFinal event, Emitter<InstallationState> emit) async {
    emit(state.copyWith(status: InstallationStatus.submitting));
    try {
      final draft = state.draftEntry;
      if (draft == null) throw "Data draft tidak ditemukan";
      if (draft.hasTransport) {
        if (draft.transportDistance == null || draft.transportDistance! <= 0) {
          throw "Jarak wajib diisi jika Anda menggunakan jasa Transportasi!";
        }
      }
      final user = await AuthStorage.getUser();
      final userId = user['user_id'] ?? '';
      final vendorCode = user['maintenance_by'] ?? '';
      final deviceName = user['device_model'] ?? '';
      // PIC final: aktif HANYA bila surat tugas mengizinkan PIC (header.isPic)
      // DAN teknisi menyalakan toggle "Ada PIC di Lokasi?" (draft.isPicActive).
      // Default toggle OFF → PIC opsional (kebalikan RRO Cut Off).
      final bool finalIsPic =
          (state.taskDetail?.header.isPic ?? true) && draft.isPicActive;
      final apiResult = await repository.submitFinalInstallation(
        createdBy: userId,
        transNo: event.transNo,
        vendorCode: vendorCode,
        draft: draft,
        remark: event.remark,
        deviceName: deviceName,
        isPic: finalIsPic,
      );
      if (apiResult['status'] != 'OK') throw apiResult['message'];
      emit(state.copyWith(status: InstallationStatus.uploading));
      final uploadResult = await uploadInstallationFiles(
        apiResult: apiResult,
        progressCubit: event.progressCubit,
        draft: draft,
      );
      int failCount = uploadResult.failureCount;
      int successCount = uploadResult.successCount;
      if (uploadResult.allSuccess) {
        try {
          await serviceRepo.confirmUploadSuccess(event.transNo);
          if (_draftBox == null && Hive.isBoxOpen(kInstallationDraftBox)) {
            _draftBox = Hive.box<InstallationEntryModel>(kInstallationDraftBox);
          }
          await _draftBox?.delete(event.transNo);
          emit(state.copyWith(status: InstallationStatus.success));
        } catch (e) {
          emit(state.copyWith(
            status: InstallationStatus.uploadPartial,
            successCount: successCount,
            failureCount: 1,
            failedFiles: ["Confirmation Failed: $e"],
          ));
        }
      } else {
        Box<Map<dynamic, dynamic>> failedBox;
        if (Hive.isBoxOpen(kFailedUploadsBox)) {
          failedBox = Hive.box<Map<dynamic, dynamic>>(kFailedUploadsBox);
        } else {
          failedBox = await Hive.openBox<Map<dynamic, dynamic>>(kFailedUploadsBox);
        }
        final storeName = state.taskDetail?.header.shipToName ?? 'Toko Tidak Diketahui';
        await failedBox.put(event.transNo, {
          'transNo': event.transNo,
          'module': 'INSTALLATION',
          'timestamp': DateTime.now().toIso8601String(),
          'failedFiles': uploadResult.failedFiles,
          'presignedDetail': apiResult['result']['detail'],
          'storeName': storeName,
        });
        emit(state.copyWith(
          status: InstallationStatus.uploadPartial,
          successCount: successCount,
          failureCount: failCount,
          failedFiles: uploadResult.failedFiles,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure,
          errorMessage: e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onUpdateTransportStatus(
      UpdateTransportStatus event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    final newDraft = draft.copyWith(hasTransport: event.hasTransport);
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(draftEntry: newDraft));
  }

  Future<void> _onSaveStoreFrontPhoto(
      SaveStoreFrontPhoto event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft != null) {
      final newDraft = draft.copyWith(
        storeFrontPhoto: event.photo,
        clearStoreFrontPhoto: event.photo == null,
      );
      await _draftBox?.put(draft.transNo, newDraft);
      emit(state.copyWith(draftEntry: newDraft));
    }
  }

  Future<void> _onUpdateTransportData(
      UpdateTransportData event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft != null) {
      final newDraft = draft.copyWith(
        hasTransport: event.hasTransport,
        transportDistance: event.distance,
        transportEvidencePhoto: event.photo,
        clearTransportPhoto: event.photo == null,
      );
      await _draftBox?.put(draft.transNo, newDraft);
      emit(state.copyWith(draftEntry: newDraft));
    }
  }

  Future<void> _onUpdateTidyingData(
      UpdateTidyingData event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft != null) {
      final newDraft = draft.copyWith(
        hasTidyingService: event.hasTidyingService,
        tidyingQty: event.tidyingQty,
      );
      await _draftBox?.put(draft.transNo, newDraft);
      emit(state.copyWith(draftEntry: newDraft));
    }
  }

  Future<void> _onUpdatePicInfo(
      UpdatePicInfo event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    final newDraft = draft.copyWith(
      picName: event.picName,
      picPhone: event.picPhone,
      picNik: event.picNik,
      picPosition: event.picPosition,
      isPicActive: event.isPicActive,
    );
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(draftEntry: newDraft));
  }

  Future<void> _onUpdatePicPhoto(
      UpdatePicPhoto event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    final newDraft = draft.copyWith(
      picPhoto: event.photo,
      clearPicPhoto: event.photo == null,
    );
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(draftEntry: newDraft));
  }
}