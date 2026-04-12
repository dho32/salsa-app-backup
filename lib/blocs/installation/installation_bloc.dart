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
    on<SaveStoreFrontPhoto>(_onSaveStoreFrontPhoto);
    on<UpdateTransportData>(_onUpdateTransportData);
    on<UpdateTidyingData>(_onUpdateTidyingData);
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

      // B. AMBIL DETAIL TUGAS DARI API/CACHE
      InstallationDetailModel? taskDetail = _taskBox?.get(event.transNo);
      if (taskDetail == null) {
        try {
          final user = await AuthStorage.getUser();
          final vendorId = user['maintenance_by'] ?? '';
          if (vendorId.isEmpty) throw Exception("Vendor ID missing");

          taskDetail = await repository.getInstallationDetail(event.transNo, vendorId);
          await _taskBox?.put(event.transNo, taskDetail);
        } catch (e) {
          emit(state.copyWith(
              status: InstallationStatus.failure,
              errorMessage: "Gagal ambil detail tugas: ${e.toString()}"));
          return;
        }
      }

      // C. [LOGIKA BARU] GABUNGKAN LIMIT GLOBAL & LIMIT API
      final configBox = Hive.box(kAppConfigBox);
      final rawLimits = configBox.get('limits_sc_after');
      final Map<String, MeasurementLimits> finalLimits = {};

      // 1. Load dari Global Dulu (Hasil Login)
      if (rawLimits is Map) {
        rawLimits.forEach((key, value) {
          if (key is String && value is MeasurementLimits) {
            finalLimits[key] = value;
          }
        });
      }

      // 2. Timpa dengan Custom Limits dari API Transaksi (Jika ada)
      if (taskDetail != null &&
          taskDetail.customLimitsAfter != null &&
          taskDetail.customLimitsAfter!.isNotEmpty) {

        taskDetail.customLimitsAfter!.forEach((key, customLimit) {
          finalLimits[key] = customLimit;
        });
      }

      // D. LOAD DRAFT USER
      InstallationEntryModel? draft = _draftBox?.get(event.transNo);
      final user = await AuthStorage.getUser();

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

      emit(state.copyWith(
        status: InstallationStatus.initial,
        taskDetail: taskDetail,
        draftEntry: draft,
        availableIndoors: _calculateAvailableIndoors(draft),
        measurementLimits: finalLimits, // <-- SEKARANG SUDAH DINAMIS
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstallationStatus.failure, errorMessage: e.toString()));
    }
  }

  // --- METHODS UPDATE (TETAP SAMA) ---

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
      final apiResult = await repository.submitFinalInstallation(
        createdBy: userId,
        transNo: event.transNo,
        vendorCode: vendorCode,
        draft: draft,
        remark: event.remark,
        deviceName: deviceName,
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
}