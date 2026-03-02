import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_validation/pos_validation_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_validation/pos_validation_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';

import '../../../models/proof_of_service/pos_validation_entry_model.dart';

class PosValidationBloc extends Bloc<PosValidationEvent, PosValidationState> {
  PosValidationBloc() : super(PosValidationInitial()) {
    on<FetchPosValidationData>(_onFetchData);
    on<UpdateInputSerial>(_onUpdateInputSerial);
    on<ChangePosValidationStep>(_onChangeStep);
    on<AddPhotoBefore>(_onAddPhotoBefore);
    on<RemovePhotoBefore>(_onRemovePhotoBefore);
    on<AddPhotoAfter>(_onAddPhotoAfter);
    on<RemovePhotoAfter>(_onRemovePhotoAfter);
    on<UpdateMeasurementAfter>(_onUpdateMeasurementAfter);
    on<SavePosValidationData>(_onSaveData);
    on<MarkAsInProgress>(_onMarkAsInProgress);
    on<PairOutdoorWithIndoor>(_onPairOutdoor);
    on<UpdateNoteAfter>(_onUpdateNoteAfter);
    on<UpdateNoteRemark>(_onUpdateNoteRemark);
    on<AddRemarkPhoto>(_onAddRemarkPhoto);
    on<RemoveRemarkPhoto>(_onRemoveRemarkPhoto);

    // 🔥 1. DAFTARKAN EVENT BARU
    on<UpdateExcludeQtyFlag>(_onUpdateExcludeQtyFlag);
  }

  // --- HELPER UNTUK KUNCI HIVE ANTI BENTROK ---
  String _getSafeHiveKey(String serialNo, String transNo, int unitIndex,
      String unitType, bool isGeneric) {
    if (isGeneric) {
      return 'GEN_${transNo}_${unitIndex}_$unitType';
    }
    return serialNo.trim().toUpperCase();
  }

  List<MeasurementEntry> _getDefaultMeasurements(String unitType) {
    List<String> measurementIds;
    switch (unitType.toUpperCase()) {
      case 'IN':
        measurementIds = ['temperature'];
        break;
      case 'OUT':
        measurementIds = ['volt', 'ampere'];
        break;
      case 'SET':
        measurementIds = ['temperature', 'volt', 'ampere'];
        break;
      default:
        measurementIds = [];
    }

    return measurementIds.map((id) {
      final limits = kPOSMeasurementLimits[id]!;
      return MeasurementEntry(
        measurementId: limits.id,
        value: 0,
        unit: limits.unit,
      );
    }).toList();
  }

  void _onFetchData(
      FetchPosValidationData event, Emitter<PosValidationState> emit) {
    emit(PosValidationLoading());

    final box = Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);
    PosValidationEntryModel? loadedData = event.initialData;

    String displaySerialNo = event.serialNo;
    String? pairedSerial = loadedData?.pairedSerialNo;

    if (event.isGeneric) {
      final existingDraft = box.values.firstWhereOrNull((e) =>
      e.transNo == event.transNo &&
          e.unitIndex == event.unitIndex &&
          e.articleType == event.unitType);

      if (existingDraft != null) {
        loadedData = existingDraft;
        displaySerialNo = existingDraft.serialNo;
        pairedSerial = existingDraft.pairedSerialNo;
      }
    }

    if (loadedData != null && (loadedData.isCompleted ?? false)) {
      add(MarkAsInProgress(
        transNo: event.transNo,
        serialNo: displaySerialNo,
        note: loadedData.note ?? '',
        articleNo: loadedData.articleNo ?? '',
        articleDesc: loadedData.articleDesc ?? '',
        articleUnitDesc: loadedData.articleUnitDesc ?? '',
        capacity: loadedData.capacity ?? 0,
        articleType: event.unitType,
        isGeneric: event.isGeneric,
        unitIndex: event.unitIndex,
      ));
    }

    final allOtherEntries = box.values.where((e) {
      return e.transNo == event.transNo &&
          !(e.articleType == event.unitType && e.unitIndex == event.unitIndex);
    }).toList();

    final usedIndoorSerials = allOtherEntries
        .map((e) => e.pairedSerialNo)
        .where((sn) => sn != null && sn.isNotEmpty)
        .toSet();

    final availableIndoors = event.allIndoorSerials
        .where((sn) => !usedIndoorSerials.contains(sn))
        .toList();

    if (loadedData != null) {
      emit(PosValidationLoaded(
        unitType: event.unitType,
        transNo: event.transNo,
        serialNo: displaySerialNo,
        originalSerialNo: displaySerialNo,
        isGeneric: event.isGeneric,
        unitIndex: event.unitIndex,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        photosBefore: loadedData.photosBefore,
        photosAfter: loadedData.photosAfter,
        measurementsAfter: loadedData.measurementsAfter,
        pairedIndoorSerial: pairedSerial,
        availableIndoorSerials: availableIndoors,
        note: loadedData.note,
        noteRemark: loadedData.noteRemark,
        remarkPhotos: loadedData.remarkPhotos,
        // 🔥 PASTIKAN STATE MEMILIKI FIELD INI DI FILE STATE-NYA YA KANG
        excludeQty: loadedData.excludeQty ?? false,
        reffLineNo: event.reffLineNo ?? loadedData.reffLineNo,
      ));
    } else {
      emit(PosValidationLoaded(
        unitType: event.unitType,
        transNo: event.transNo,
        serialNo: displaySerialNo,
        originalSerialNo: displaySerialNo,
        isGeneric: event.isGeneric,
        unitIndex: event.unitIndex,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        measurementsAfter: _getDefaultMeasurements(event.unitType),
        availableIndoorSerials: availableIndoors,
        pairedIndoorSerial: pairedSerial,
        excludeQty: false, // 🔥 Default
        reffLineNo: event.reffLineNo,
      ));
    }
  }

  // 🔥 2. FUNGSI BARU UNTUK MENANGKAP EVENT EXCLUDE QTY
  Future<void> _onUpdateExcludeQtyFlag(
      UpdateExcludeQtyFlag event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final newState = currentState.copyWith(excludeQty: event.excludeQty);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onUpdateInputSerial(
      UpdateInputSerial event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final newState = currentState.copyWith(serialNo: event.newSerial);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _saveToHive(PosValidationLoaded state) async {
    try {
      final box =
      await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);

      final hiveKey = _getSafeHiveKey(state.serialNo, state.transNo,
          state.unitIndex, state.unitType, state.isGeneric);

      final entry = PosValidationEntryModel(
        transNo: state.transNo,
        serialNo: state.serialNo.trim().toUpperCase(),
        photosBefore: state.photosBefore,
        photosAfter: state.photosAfter,
        measurementsAfter: state.measurementsAfter,
        isCompleted: false,
        note: state.note,
        noteRemark: state.noteRemark,
        remarkPhotos: state.remarkPhotos,
        articleNo: state.articleNo,
        articleDesc: state.articleDesc,
        articleUnitDesc: state.articleUnitDesc,
        capacity: 0,
        articleType: state.unitType,
        pairedSerialNo: state.pairedIndoorSerial,
        isGeneric: state.isGeneric,
        unitIndex: state.unitIndex,
        // 🔥 3. SIMPAN KE HIVE
        excludeQty: state.excludeQty,
        reffLineNo: state.reffLineNo,
      );

      await box.put(hiveKey, entry);
    } catch (e) {
      print("Gagal auto-save ke Hive: $e");
    }
  }

  void _onChangeStep(
      ChangePosValidationStep event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      emit((state as PosValidationLoaded).copyWith(currentStep: event.step));
    }
  }

  Future<void> _onAddPhotoBefore(
      AddPhotoBefore event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos =
      List<CapturedImageDetail>.from(currentState.photosBefore)
        ..add(event.imageDetail);
      final newState = currentState.copyWith(photosBefore: updatedPhotos);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onRemovePhotoBefore(
      RemovePhotoBefore event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos = currentState.photosBefore
          .where((p) => p.imagePath != event.imagePath)
          .toList();
      final newState = currentState.copyWith(photosBefore: updatedPhotos);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onAddPhotoAfter(
      AddPhotoAfter event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos =
      List<CapturedImageDetail>.from(currentState.photosAfter)
        ..add(event.imageDetail);
      final newState = currentState.copyWith(photosAfter: updatedPhotos);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onRemovePhotoAfter(
      RemovePhotoAfter event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos = currentState.photosAfter
          .where((p) => p.imagePath != event.imagePath)
          .toList();
      final newState = currentState.copyWith(photosAfter: updatedPhotos);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onUpdateMeasurementAfter(
      UpdateMeasurementAfter event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedMeasurements =
      List<MeasurementEntry>.from(currentState.measurementsAfter);
      final index = updatedMeasurements.indexWhere(
              (m) => m.measurementId == event.measurement.measurementId);
      if (index != -1) {
        updatedMeasurements[index] = event.measurement;
      }
      final newState =
      currentState.copyWith(measurementsAfter: updatedMeasurements);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onUpdateNoteAfter(
      UpdateNoteAfter event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      emit(currentState.copyWith(note: event.note));
      await _saveToHive(currentState.copyWith(note: event.note));
    }
  }

  Future<void> _onUpdateNoteRemark(
      UpdateNoteRemark event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      emit(currentState.copyWith(noteRemark: event.remark));
      await _saveToHive(currentState.copyWith(noteRemark: event.remark));
    }
  }

  Future<void> _onAddRemarkPhoto(
      AddRemarkPhoto event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos =
      List<CapturedImageDetail>.from(currentState.remarkPhotos ?? [])
        ..add(event.imageDetail);
      final newState = currentState.copyWith(remarkPhotos: updatedPhotos);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  Future<void> _onRemoveRemarkPhoto(
      RemoveRemarkPhoto event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos = currentState.remarkPhotos
          ?.where((p) => p.imagePath != event.imagePath)
          .toList();
      final newState = currentState.copyWith(remarkPhotos: updatedPhotos);
      emit(newState);
      await _saveToHive(newState);
    }
  }

  void _onPairOutdoor(
      PairOutdoorWithIndoor event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final newState =
      currentState.copyWith(pairedIndoorSerial: event.indoorSerialNo);
      emit(newState);
      _saveToHive(newState);
    }
  }

  Future<void> _onSaveData(
      SavePosValidationData event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final box =
      await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      final hiveKey = _getSafeHiveKey(event.serialNo, event.transNo,
          currentState.unitIndex, event.articleType, currentState.isGeneric);

      if (currentState.isGeneric && event.articleType == 'IN') {
        final oldSerial = currentState.originalSerialNo;
        final newSerial = event.serialNo.trim().toUpperCase();

        if (oldSerial != null &&
            oldSerial.isNotEmpty &&
            !oldSerial.startsWith('AC') &&
            oldSerial != newSerial) {
          final affectedOutdoors = box.values
              .where((e) =>
          e.transNo == event.transNo &&
              e.articleType == 'OUT' &&
              e.pairedSerialNo == oldSerial)
              .toList();

          for (var outUnit in affectedOutdoors) {
            final updatedOut = outUnit.copyWith(pairedSerialNo: newSerial);
            final outKey = _getSafeHiveKey(updatedOut.serialNo,
                updatedOut.transNo, updatedOut.unitIndex ?? 0, 'OUT', true);
            await box.put(outKey, updatedOut);
          }
        }
      }

      final entry = PosValidationEntryModel(
        transNo: event.transNo,
        serialNo: event.serialNo.trim().toUpperCase(),
        photosBefore: currentState.photosBefore,
        photosAfter: currentState.photosAfter,
        measurementsAfter: currentState.measurementsAfter,
        isCompleted: event.markAsCompleted,
        note: event.note,
        noteRemark: currentState.noteRemark,
        remarkPhotos: currentState.remarkPhotos,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        capacity: event.capacity,
        articleType: event.articleType,
        pairedSerialNo: currentState.pairedIndoorSerial,
        isGeneric: currentState.isGeneric,
        unitIndex: currentState.unitIndex,
        // 🔥 4. SIMPAN KE HIVE (SAAT USER KLIK SAVE)
        excludeQty: currentState.excludeQty,
        reffLineNo: currentState.reffLineNo,
      );

      await box.put(hiveKey, entry);

      if (event.markAsCompleted) {
        emit(PosValidationSaveSuccess());
      }
    }
  }

  Future<void> _onMarkAsInProgress(
      MarkAsInProgress event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final entry = PosValidationEntryModel(
        transNo: event.transNo,
        serialNo: event.serialNo.trim().toUpperCase(),
        photosBefore: currentState.photosBefore,
        photosAfter: currentState.photosAfter,
        measurementsAfter: currentState.measurementsAfter,
        isCompleted: false,
        note: event.note,
        noteRemark: currentState.noteRemark,
        remarkPhotos: currentState.remarkPhotos,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        capacity: event.capacity,
        articleType: event.articleType,
        isGeneric: event.isGeneric,
        unitIndex: event.unitIndex,
        // 🔥 5. SIMPAN KE HIVE JUGA
        excludeQty: currentState.excludeQty,
        reffLineNo: currentState.reffLineNo,
      );

      final box =
      await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      final hiveKey = _getSafeHiveKey(event.serialNo, event.transNo,
          event.unitIndex, event.articleType, event.isGeneric);

      await box.put(hiveKey, entry);
    }
  }
}