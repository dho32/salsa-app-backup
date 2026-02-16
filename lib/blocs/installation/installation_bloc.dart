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
  }

  // --- 1. LOAD DATA ---
  Future<void> _onLoadData(
      LoadInstallationData event, Emitter<InstallationState> emit) async {
    emit(state.copyWith(status: InstallationStatus.loading));
    try {
      // A. Open Hive Boxes
      if (!Hive.isBoxOpen(kInstallationDraftBox)) {
        _draftBox =
            await Hive.openBox<InstallationEntryModel>(kInstallationDraftBox);
      } else {
        _draftBox = Hive.box<InstallationEntryModel>(kInstallationDraftBox);
      }

      if (!Hive.isBoxOpen(kInstallationDetailBox)) {
        _taskBox =
            await Hive.openBox<InstallationDetailModel>(kInstallationDetailBox);
      } else {
        _taskBox = Hive.box<InstallationDetailModel>(kInstallationDetailBox);
      }

      // B. LOAD CONFIG
      final configBox = Hive.box(kAppConfigBox);
      final rawLimits = configBox.get('limits_sc_after');
      final Map<String, MeasurementLimits> loadedLimits = {};
      if (rawLimits is Map) {
        rawLimits.forEach((key, value) {
          if (key is String && value is MeasurementLimits) {
            loadedLimits[key] = value;
          }
        });
      }

      // C. LOAD TASK DETAIL
      InstallationDetailModel? taskDetail = _taskBox?.get(event.transNo);
      // Selalu coba fetch jika null atau jika kita ingin update data terbaru
      if (taskDetail == null) {
        try {
          final user = await AuthStorage.getUser();
          final vendorId = user['maintenance_by'] ?? '';
          if (vendorId.isEmpty) throw Exception("Vendor ID missing");

          taskDetail =
              await repository.getInstallationDetail(event.transNo, vendorId);
          await _taskBox?.put(event.transNo, taskDetail);
        } catch (e) {
          emit(state.copyWith(
              status: InstallationStatus.failure,
              errorMessage: "Gagal ambil detail tugas: ${e.toString()}"));
          return;
        }
      }

      // D. LOAD DRAFT USER
      InstallationEntryModel? draft = _draftBox?.get(event.transNo);

      final user = await AuthStorage.getUser();

      // LOGIC 1: JIKA DRAFT KOSONG -> BUAT BARU
      if (draft == null) {
        List<InstallationUnitModel> initialUnits = [];
        if (taskDetail != null) {
          initialUnits = taskDetail.targets.map((t) {
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

        draft = InstallationEntryModel(
          transNo: event.transNo,
          vendorId: user['maintenance_by'] ?? '',
          vendorName: user['maintenance_by_name'] ?? '',
          technicianId: user['user_id'] ?? '',
          technician1Name: user['name'] ?? '',
          startDate: DateTime.now(),
          units: initialUnits,
        );
        await _draftBox?.put(event.transNo, draft);
      }

      // LOGIC 2: [FIX] SELF-HEALING REFF LINE NO
      // else if (taskDetail != null) {
      //   bool needUpdate = false;
      //   List<InstallationUnitModel> patchedUnits = List.from(draft.units);
      //
      //   // for (int i = 0; i < patchedUnits.length; i++) {
      //   //   if (patchedUnits[i].reffLineNo.isEmpty) {
      //   //     try {
      //   //       final target = taskDetail.targets.firstWhere((t) =>
      //   //       t.unitIndex == patchedUnits[i].unitIndex &&
      //   //           t.unitType == patchedUnits[i].articleType
      //   //       );
      //   //
      //   //       if (target.reffLineNo.isNotEmpty) {
      //   //         // UPDATE UNIT DENGAN REFF LINE NO YANG BENAR
      //   //         patchedUnits[i] = patchedUnits[i].copyWith(reffLineNo: target.reffLineNo);
      //   //         needUpdate = true;
      //   //         print("🔧 Self-Healing: Fixed ReffLineNo for Unit ${patchedUnits[i].unitIndex}");
      //   //       }
      //   //     } catch (_) {}
      //   //   }
      //   // }
      //
      //   // if (needUpdate) {
      //   //   draft = draft.copyWith(units: patchedUnits);
      //   //   await _draftBox?.put(event.transNo, draft);
      //   // }
      // }

      emit(state.copyWith(
        status: InstallationStatus.initial,
        taskDetail: taskDetail,
        draftEntry: draft,
        availableIndoors: _calculateAvailableIndoors(draft),
        measurementLimits: loadedLimits,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure, errorMessage: e.toString()));
    }
  }

  // --- METHODS UPDATE ---

  Future<void> _onUpdateTeamInfo(
      UpdateTeamInfo event, Emitter<InstallationState> emit) async {
    final draft = state.draftEntry;
    if (draft == null) return;
    final newDraft = draft.copyWith(
      technician2Name: event.technician2 ?? draft.technician2Name,
      technician3Name: event.technician3 ?? draft.technician3Name,
      startDate: event.startDate ?? draft.startDate,
    );
    await _draftBox?.put(draft.transNo, newDraft);
    emit(state.copyWith(draftEntry: newDraft));
  }

  // [FIXED] Auto-Pairing Outdoor saat Indoor disimpan
  Future<void> _onSaveIndoor(
      SaveIndoorUnit event, Emitter<InstallationState> emit) async {
    // Gunakan status loading biasa (Local Save)
    emit(state.copyWith(status: InstallationStatus.loading));

    try {
      final draft = state.draftEntry!;
      var units = List<InstallationUnitModel>.from(draft.units);

      // 1. Find & Update Indoor Unit
      final index = units.indexWhere(
          (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'IN');

      if (index >= 0) {
        units[index] = event.unit;
      } else {
        units.add(event.unit);
      }

      // 2. [FIX BUG] Auto-Update Pairing Outdoor Unit
      // Cari Outdoor dengan unitIndex yang sama
      final outdoorIndex = units.indexWhere(
          (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'OUT');

      if (outdoorIndex != -1) {
        final existingOutdoor = units[outdoorIndex];
        // Jika Pairing belum sesuai dengan SN Indoor baru, paksa update
        if (existingOutdoor.pairedSerialNo != event.unit.serialNo) {
          units[outdoorIndex] = existingOutdoor.copyWith(
            pairedSerialNo: event.unit.serialNo,
          );
        }
      }

      final newDraft = draft.copyWith(units: units);
      await _draftBox?.put(draft.transNo, newDraft);

      // 3. Emit SUCCESS (Bukan Validating) biar UI gak manggil API
      emit(state.copyWith(
        status: InstallationStatus.success,
        draftEntry: newDraft,
        availableIndoors: _calculateAvailableIndoors(newDraft),
        errorMessage: "", // Clear error if any
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure, errorMessage: e.toString()));
    }
  }

  // [FIXED] Explicit Success Status
  Future<void> _onSaveOutdoor(
      SaveOutdoorUnit event, Emitter<InstallationState> emit) async {
    emit(state.copyWith(status: InstallationStatus.loading));

    try {
      final draft = state.draftEntry!;
      var units = List<InstallationUnitModel>.from(draft.units);

      // 1. Update/Add Outdoor Unit
      final outIndex = units.indexWhere(
          (u) => u.unitIndex == event.unit.unitIndex && u.articleType == 'OUT');

      if (outIndex >= 0) {
        units[outIndex] = event.unit;
      } else {
        units.add(event.unit);
      }

      // 2. Update Paired Indoor Unit (IF PAIRED)
      if (event.pairedIndoorSerial.isNotEmpty) {
        final inIndex = units.indexWhere((u) =>
            u.serialNo == event.pairedIndoorSerial && u.articleType == 'IN');

        if (inIndex >= 0) {
          final oldIndoor = units[inIndex];
          units[inIndex] = oldIndoor.copyWith(
            pairedSerialNo: event.unit.serialNo, // Update link ke SN Outdoor
          );
        }
      }

      final newDraft = draft.copyWith(units: units);
      await _draftBox?.put(draft.transNo, newDraft);

      // 3. Emit SUCCESS
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

    // Cari Unit Outdoor dengan index yang sesuai
    final index = units.indexWhere(
        (u) => u.unitIndex == event.unitIndex && u.articleType == 'OUT');

    final String newStatus = event.isFinal ? 'COMPLETED' : 'DRAFT';

    if (index >= 0) {
      // ✅ KASUS 1: Unit sudah ada -> Update Saja
      final oldUnit = units[index];
      units[index] = oldUnit.copyWith(
        materials: event.materials,
        materialStatus: newStatus,
      );
    } else {
      // ⚠️ KASUS 2: Unit belum ada -> Buat baru
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

    // Status Success (Save Lokal)
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

    // FIX: Akses langsung event.key (bukan event.evidence.key)
    final index = evidences.indexWhere((e) => e.key == event.key);

    // FIX: Buat object model di sini
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

      print(draft.units);

      final user = await AuthStorage.getUser();
      final String vendorCode = user['maintenance_by'] ?? '';

      // Susun Payload Items
      List<Map<String, String>> itemsPayload = [];

      for (var unit in draft.units) {
        print(unit.serialNo);
        // A. Unit Utama (Indoor/Outdoor)
        if (unit.serialNo.isNotEmpty) {
          itemsPayload.add({
            "serial_no": unit.serialNo,
            "unit_type": unit.articleType,
            "article_no": unit.articleNo
          });
        }

        //dikomen dlu karena sudah kehandle dari query diatas
        // // B. Unit Pasangan (Khusus Outdoor -> Cek Indoor pasangannya)
        // if (unit.articleType == 'OUT' &&
        //     (unit.pairedSerialNo?.isNotEmpty ?? false)) {
        //   bool exists =
        //       itemsPayload.any((e) => e['serial_no'] == unit.pairedSerialNo);
        //
        //   if (!exists) {
        //     final indoorTarget = state.taskDetail?.targets.firstWhere(
        //         (t) => t.unitIndex == unit.unitIndex && t.unitType == 'IN',
        //         orElse: () => InstallationTargetUnitModel(
        //             unitIndex: -1,
        //             unitType: '',
        //             articleNo: '',
        //             description: ''));
        //
        //     if (indoorTarget != null && indoorTarget.articleNo.isNotEmpty) {
        //       itemsPayload.add({
        //         "serial_no": unit.pairedSerialNo!,
        //         "unit_type": "IN",
        //         "article_no": indoorTarget.articleNo
        //       });
        //     }
        //   }
        // }
      }

      if (itemsPayload.isEmpty) {
        throw "Belum ada Serial Number yang diinput";
      }

      // Hit API
      final result = await repository.validateSerialNumbers(
          transNo: header.transNo, vendorCode: vendorCode, items: itemsPayload);

      final resultData = result['result'];
      bool isValid = resultData['is_valid'] ?? false;

      if (isValid) {
        // SUKSES VALIDASI -> UI Pindah Halaman
        emit(state.copyWith(status: InstallationStatus.snValidationSuccess));
      } else {
        // GAGAL VALIDASI -> UI Show Dialog
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
    // 1. STATE: SUBMITTING (Loading submit JSON)
    emit(state.copyWith(status: InstallationStatus.submitting));

    try {
      final draft = state.draftEntry;
      if (draft == null) throw "Data draft tidak ditemukan";

      final user = await AuthStorage.getUser();
      final userId = user['user_id'] ?? '';
      final vendorCode = user['maintenance_by'] ?? '';
      final deviceName = user['device_model'] ?? '';
      final apiResult = await repository.submitFinalInstallation(
        createdBy: userId,
        transNo: event.transNo,
        vendorCode: vendorCode,
        draft: draft,
        remark: event.remark,
        deviceName: deviceName,
      );

      if (apiResult['status'] != 'OK') throw apiResult['message'];

      // 3. STATE: UPLOADING (Muncul Dialog Progress Bar)
      emit(state.copyWith(status: InstallationStatus.uploading));

      // 4. ACTION: Upload Fisik ke S3
      final uploadResult = await uploadInstallationFiles(
        apiResult: apiResult,
        progressCubit: event.progressCubit,
        draft: draft,
      );

      int failCount = uploadResult.failureCount;
      int successCount = uploadResult.successCount;

      // 5. CHECK RESULT
      if (uploadResult.allSuccess) {
        // --- SKENARIO SUKSES SEMPURNA ---
        try {
          // A. Konfirmasi ke Backend (Tutup Tiket)
          await serviceRepo.confirmUploadSuccess(event.transNo);

          // B. Hapus Draft Lokal
          if (_draftBox == null && Hive.isBoxOpen(kInstallationDraftBox)) {
            _draftBox = Hive.box<InstallationEntryModel>(kInstallationDraftBox);
          }
          await _draftBox?.delete(event.transNo);

          // C. Emit Sukses
          emit(state.copyWith(status: InstallationStatus.success));
        } catch (e) {
          // Jika confirm gagal, anggap partial (agar bisa retry)
          emit(state.copyWith(
            status: InstallationStatus.uploadPartial,
            successCount: successCount,
            failureCount: 1, // Confirm failed count as 1
            failedFiles: ["Confirmation Failed: $e"],
          ));
        }
      } else {
        // A. Simpan ke Hive FailedUploads (Agar muncul Card Pending di Home)
        final failedBox = await Hive.openBox(kFailedUploadsBox);
        await failedBox.put(event.transNo, {
          'transNo': event.transNo,
          'type': 'INSTALLATION',
          'timestamp': DateTime.now().toIso8601String(),
          'failed_files': uploadResult.failedFiles,
          'presigned_detail': apiResult['result']['detail']
          // Simpan URL utk retry
        });

        // // B. Hapus Draft Utama (Karena data teks sudah masuk server)
        // if (_draftBox == null && Hive.isBoxOpen(kInstallationDraftBox)) {
        //   _draftBox = Hive.box<InstallationEntryModel>(kInstallationDraftBox);
        // }
        // await _draftBox?.delete(event.transNo);

        // C. Emit Partial
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

    // Update draft global
    final newDraft = draft.copyWith(hasTransport: event.hasTransport);

    // Simpan ke Hive
    await _draftBox?.put(draft.transNo, newDraft);

    // Emit state baru
    emit(state.copyWith(draftEntry: newDraft));
  }
}
