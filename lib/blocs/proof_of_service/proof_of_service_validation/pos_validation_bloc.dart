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
  }

  // Helper untuk membuat daftar pengukuran default berdasarkan tipe unit
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

  // Handler untuk memuat data awal (dari Hive atau membuat baru)
  void _onFetchData(
      FetchPosValidationData event, Emitter<PosValidationState> emit) {
    emit(PosValidationLoading());
    final initialData = event.initialData;
    bool isComplete = initialData?.isCompleted ?? false;

    if (initialData != null && isComplete) {
      add(MarkAsInProgress(
        transNo: event.transNo,
        serialNo: event.serialNo,
        note: initialData.note ?? '',
        articleNo: initialData.articleNo ?? '',
        articleDesc: initialData.articleDesc ?? '',
        articleUnitDesc: initialData.articleUnitDesc ?? '',
        capacity: initialData.capacity ?? 0,
        articleType: event.unitType,
      ));
    }

    final box = Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);
    final allEntries = box.values
        .where(
            (e) => e.transNo == event.transNo && e.serialNo != event.serialNo)
        .toList();
    final usedIndoorSerials = allEntries
        .map((e) => e.pairedSerialNo)
        .where((sn) => sn != null)
        .toSet();
    final availableIndoors = event.allIndoorSerials
        .where((sn) => !usedIndoorSerials.contains(sn))
        .toList();

    if (initialData != null) {
      emit(PosValidationLoaded(
        unitType: event.unitType,
        transNo: event.transNo,
        serialNo: event.serialNo,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        photosBefore: initialData.photosBefore,
        photosAfter: initialData.photosAfter,
        measurementsAfter: initialData.measurementsAfter,
        pairedIndoorSerial: initialData.pairedSerialNo,
        availableIndoorSerials: availableIndoors,
        note: initialData.note,
        noteRemark: initialData.noteRemark,
      ));
    } else {
      emit(PosValidationLoaded(
        unitType: event.unitType,
        transNo: event.transNo,
        serialNo: event.serialNo,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        measurementsAfter: _getDefaultMeasurements(event.unitType),
        availableIndoorSerials: availableIndoors,
      ));
    }
  }

  void _onPairOutdoor(
      PairOutdoorWithIndoor event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      emit(currentState.copyWith(pairedIndoorSerial: event.indoorSerialNo));
    }
  }

  // Handler untuk event lainnya yang memodifikasi state
  void _onChangeStep(
      ChangePosValidationStep event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      emit((state as PosValidationLoaded).copyWith(currentStep: event.step));
    }
  }

  void _onAddPhotoBefore(
      AddPhotoBefore event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos =
          List<CapturedImageDetail>.from(currentState.photosBefore)
            ..add(event.imageDetail);
      emit(currentState.copyWith(photosBefore: updatedPhotos));
    }
  }

  void _onRemovePhotoBefore(
      RemovePhotoBefore event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos = currentState.photosBefore
          .where((p) => p.imagePath != event.imagePath)
          .toList();
      emit(currentState.copyWith(photosBefore: updatedPhotos));
    }
  }

  void _onAddPhotoAfter(AddPhotoAfter event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos =
          List<CapturedImageDetail>.from(currentState.photosAfter)
            ..add(event.imageDetail);
      emit(currentState.copyWith(photosAfter: updatedPhotos));
    }
  }

  void _onRemovePhotoAfter(
      RemovePhotoAfter event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedPhotos = currentState.photosAfter
          .where((p) => p.imagePath != event.imagePath)
          .toList();
      emit(currentState.copyWith(photosAfter: updatedPhotos));
    }
  }

  void _onUpdateMeasurementAfter(
      UpdateMeasurementAfter event, Emitter<PosValidationState> emit) {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      final updatedMeasurements =
          List<MeasurementEntry>.from(currentState.measurementsAfter);
      final index = updatedMeasurements.indexWhere(
          (m) => m.measurementId == event.measurement.measurementId);
      if (index != -1) {
        updatedMeasurements[index] = event.measurement;
      }
      emit(currentState.copyWith(measurementsAfter: updatedMeasurements));
    }
  }

  Future<void> _onUpdateNoteAfter(
      UpdateNoteAfter event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      emit(currentState.copyWith(note: event.note));
      await _saveToHive(currentState.copyWith(note: event.note)); // Auto Save
    }
  }

  Future<void> _onUpdateNoteRemark(
      UpdateNoteRemark event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      emit(currentState.copyWith(noteRemark: event.remark));
      await _saveToHive(
          currentState.copyWith(noteRemark: event.remark)); // Auto Save
    }
  }

  Future<void> _saveToHive(PosValidationLoaded state) async {
    try {
      final box =
          await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      // Buat entry baru atau ambil yg lama
      final entry = PosValidationEntryModel(
        transNo: state.transNo,
        serialNo: state.serialNo.trim().toUpperCase(),
        photosBefore: state.photosBefore,
        photosAfter: state.photosAfter,
        measurementsAfter: state.measurementsAfter,
        isCompleted: false,
        // Kalau auto-save, belum completed
        note: state.note,
        noteRemark: state.noteRemark,
        // <-- SIMPAN REMARK
        articleNo: state.articleNo,
        articleDesc: state.articleDesc,
        articleUnitDesc: state.articleUnitDesc,
        capacity: 0,
        articleType: state.unitType,
        // <-- Gunakan articleType
        pairedSerialNo: state.pairedIndoorSerial,
      );
      await box.put(state.serialNo.trim().toUpperCase(), entry);
    } catch (e) {
      print("Gagal auto-save ke Hive: $e");
    }
  }

  // Handler untuk menyimpan data ke Hive
  Future<void> _onSaveData(
      SavePosValidationData event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;

      // =================================================================
      // --- LOGIKA VALIDASI DITAMBAHKAN DI SINI ---
      // =================================================================
      // for (final measurement in currentState.measurementsAfter) {
      //   // Jangan validasi jika pengukuran di-skip
      //   if (measurement.isSkipped ?? false) continue;
      //
      //   // Ambil batas (limits) dari konstanta
      //   final limits = kPOSMeasurementLimits[measurement.measurementId];
      //
      //   // Cek jika nilai yang diinput melebihi batas maksimal
      //   if (limits != null) {
      //     // Secara default, gunakan batas atas dari konstanta
      //     double maxLimit = limits.max;
      //
      //     // TAPI, jika ini adalah pengukuran suhu ('temperature') DAN kita menerima
      //     // nilai indoorTemp dari event, maka GUNAKAN nilai indoorTemp sebagai batas atas.
      //     if (measurement.measurementId == 'temperature' &&
      //         event.indoorTemp != null) {
      //       maxLimit = event.indoorTemp!;
      //     }
      //
      //     // // Lakukan validasi dengan batas atas (maxLimit) yang sudah dinamis
      //     // if (measurement.value > maxLimit) {
      //     //   final errorMessage =
      //     //       'Nilai untuk "${limits.label}" (${measurement.value} ${limits.unit}) melebihi batas maksimal 3.';
      //     //
      //     //   emit(PosValidationSaveFailure(errorMessage, currentState));
      //     //   return;
      //     // }
      //   }
      // }
      // =================================================================
      // --- AKHIR DARI LOGIKA VALIDASI ---
      // =================================================================

      // Jika semua validasi lolos, lanjutkan proses penyimpanan ke Hive
      final entry = PosValidationEntryModel(
        transNo: event.transNo,
        serialNo: event.serialNo.trim().toUpperCase(),
        photosBefore: currentState.photosBefore,
        photosAfter: currentState.photosAfter,
        measurementsAfter: currentState.measurementsAfter,
        isCompleted: event.markAsCompleted,
        note: event.note,
        noteRemark: currentState.noteRemark,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        capacity: event.capacity,
        articleType: event.articleType,
        pairedSerialNo: currentState.pairedIndoorSerial,
      );

      final box =
          await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      await box.put(event.serialNo.trim().toUpperCase(), entry);

      // Pancarkan (emit) state SUKSES setelah menyimpan
      if (event.markAsCompleted) {
        emit(PosValidationSaveSuccess());
      }
    }
  }

  Future<void> _onMarkAsInProgress(
      MarkAsInProgress event, Emitter<PosValidationState> emit) async {
    if (state is PosValidationLoaded) {
      final currentState = state as PosValidationLoaded;
      // Buat entry baru dengan isCompleted = false
      final entry = PosValidationEntryModel(
        transNo: event.transNo,
        serialNo: event.serialNo.trim().toUpperCase(),
        photosBefore: currentState.photosBefore,
        photosAfter: currentState.photosAfter,
        measurementsAfter: currentState.measurementsAfter,
        isCompleted: false,
        note: event.note,
        articleNo: event.articleNo,
        articleDesc: event.articleDesc,
        articleUnitDesc: event.articleUnitDesc,
        capacity: event.capacity,
        articleType: event.articleType,
      );

      final box =
          await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      await box.put(event.serialNo.trim().toUpperCase(), entry);
    }
  }
}
