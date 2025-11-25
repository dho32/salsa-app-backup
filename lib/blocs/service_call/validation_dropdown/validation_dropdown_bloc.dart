// lib/blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart'; // Diperlukan untuk save Hive
import '../../../components/constants.dart';
import '../../../models/common/measurement_limits.dart';
import 'validation_dropdown_event.dart';
import 'validation_dropdown_state.dart';
import 'package:hive/hive.dart'; // Untuk Hive.box

class ValidationDropdownBloc
    extends Bloc<ValidationDropdownEvent, ValidationDropdownState> {
  ValidationDropdownBloc() : super(ValidationDropdownInitial()) {
    on<FetchValidationDropdownData>(_onFetchData);
    on<SelectUnitType>(_onSelectUnitType);
    on<AddProblemCard>(_onAddProblemCard);
    on<RemoveProblemCard>(_onRemoveProblemCard);
    on<SelectProblemForCard>(_onSelectProblemForCard);
    on<SelectSolutionsForCard>(_onSelectSolutionsForCard);
    on<AddCapturedPhotoBefore>(_onAddCapturedPhotoBefore);
    on<RemoveCapturedPhotoBefore>(_onRemoveCapturedPhotoBefore);
    on<UpdateMeasurementBefore>(_onUpdateMeasurementBefore);
    on<AddCapturedPhotoAfter>(_onAddCapturedPhotoAfter);
    on<RemoveCapturedPhotoAfter>(_onRemoveCapturedPhotoAfter);
    on<UpdateMeasurementAfter>(_onUpdateMeasurementAfter);
    on<ChangeValidationStep>(_onChangeValidationStep);
    on<ChangeValidationViewMode>(_onChangeValidationViewMode);
    on<SaveValidationData>(_onSaveValidationData);
    on<SelectOutdoorSerial>(_onSelectOutdoorSerial);
    on<NoteChanged>(_onNoteChanged);
    on<MarkUnitAsInvalid>(_onMarkUnitAsInvalid);
  }

  List<MeasurementEntry> _generateMeasurementsFromLimits(
      Map<String, MeasurementLimits> limitsMap) {
    return limitsMap.values
        .map((limits) => MeasurementEntry(
      measurementId: limits.id,
      value: 0.0,
      unit: limits.unit,
      isSkipped: false,
    ))
        .toList();
  }

  List<MeasurementEntry> _generateSkippedMeasurements(
      Map<String, dynamic> limitsMap) {
    // Menggunakan keys dari limitsMap (baik Before atau After)
    return limitsMap.keys.map((key) {
      return MeasurementEntry(
        measurementId: key,
        value: 0.0,
        unit: '', // Tidak penting karena skip
        isSkipped: true, // <-- KUNCI: Otomatis SKIP
        capturedImage: null,
      );
    }).toList();
  }

  Future<void> _onFetchData(FetchValidationDropdownData event,
      Emitter<ValidationDropdownState> emit) async {
    emit(ValidationDropdownLoading());
    try {
      final data = event.problemSources;
      final initialData = event.initialData;

      final assignmentBox = await Hive.openBox(kOutdoorUnitAssignmentsBox);
      final Map<dynamic, dynamic> allAssignments =
          assignmentBox.get(event.transNo) ?? {};

      final Set<String> usedSerials = {};
      allAssignments.forEach((indoorSN, outdoorSN) {
        if (indoorSN != event.currentIndoorSerial) {
          usedSerials.add(outdoorSN as String);
        }
      });

      final List<String> availableSerialsForDropdown = event
          .allAvailableOutdoorSerials
          .where((serial) => !usedSerials.contains(serial))
          .toList();

      List<MeasurementEntry> measurementsBefore =
      initialData?.measurementsBefore.isNotEmpty == true
          ? initialData!.measurementsBefore
          : _generateMeasurementsFromLimits(event.limitsScBefore); // <-- Gunakan limits
      List<MeasurementEntry> measurementsAfter =
      initialData?.measurementsAfter.isNotEmpty == true
          ? initialData!.measurementsAfter
          : _generateMeasurementsFromLimits(event.limitsScAfter);

      emit(
        ValidationDropdownLoaded(
          data: data,
          selectedUnitType: initialData?.unitType,
          capturedPhotosBefore: initialData?.imagePathsBefore ?? [],
          capturedMeasurementsBefore: measurementsBefore,
          selectedProblemCards: initialData?.problems
                  .map((p) => SelectedProblemCard(
                      selectedProblemId: p.problemId,
                      selectedSolutionIds: p.solutionIds))
                  .toList() ??
              [],
          capturedPhotosAfter: initialData?.imagePathsAfter ?? [],
          capturedMeasurementsAfter: measurementsAfter,
          currentStep: 0,
          currentViewMode: ValidationViewMode.before,
          outdoorSerialNumbers: availableSerialsForDropdown,
          selectedOutdoorSerialNo: initialData?.outdoorSerialNo,
          limitsScBefore: event.limitsScBefore,
          limitsScAfter: event.limitsScAfter,
          noteIndoorBeforeOptions: event.detailData.noteIndoorBeforeOptions,
          noteIndoorAfterOptions: event.detailData.noteIndoorAfterOptions,
          noteOutdoorBeforeOptions: event.detailData.noteOutdoorBeforeOptions,
          noteOutdoorAfterOptions: event.detailData.noteOutdoorAfterOptions,
          noteOutdoorPsiBeforeOptions: event.detailData.noteOutdoorPsiBeforeOptions,
          noteOutdoorPsiAfterOptions: event.detailData.noteOutdoorPsiAfterOptions,
          selectedIndoorNoteBefore: initialData?.selectedIndoorNoteBefore,
          selectedOutdoorNoteBefore: initialData?.selectedOutdoorNoteBefore,
          selectedIndoorNoteAfter: initialData?.selectedIndoorNoteAfter,
          selectedOutdoorNoteAfter: initialData?.selectedOutdoorNoteAfter,
          selectedOutdoorPSINoteBefore: initialData?.selectedOutdoorPSINoteBefore,
          selectedOutdoorPSINoteAfter: initialData?.selectedOutdoorPSINoteAfter,
        ),
      );
    } catch (e) {
      emit(ValidationDropdownError(e.toString()));
    }
  }

  Future<void> _onMarkUnitAsInvalid(
      MarkUnitAsInvalid event, Emitter<ValidationDropdownState> emit) async {

    if (state is! ValidationDropdownLoaded) return;
    final currentState = state as ValidationDropdownLoaded;

    emit(currentState.copyWith(saveStatus: ValidationSaveStatus.saving));
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // 1. Generate Dummy Measurements (Semua 0 & Skipped)
      final dummyMeasurementsBefore = _generateSkippedMeasurements(currentState.limitsScBefore);
      final dummyMeasurementsAfter = _generateSkippedMeasurements(currentState.limitsScAfter);

      // 2. Buat Objek Model (Inject Note & Foto Bukti)
      final validationEntry = ServiceCallValidationEntryModel(
        unitType: currentState.selectedUnitType ?? 'INVALID_UNIT', // Fallback jika belum pilih
        serialNo: event.serialNo,
        transNo: event.transNo,

        // Foto Bukti kita taruh di 'Before' (Sesuai request: minimal 1 foto)
        imagePathsBefore: event.proofPhotos,
        measurementsBefore: dummyMeasurementsBefore,

        // Note: Tembak Rata ke Semua Field
        selectedIndoorNoteBefore: event.reason,
        selectedOutdoorNoteBefore: event.reason,
        selectedOutdoorPSINoteBefore: event.reason,

        // Bagian 'After' kita kosongkan total (tapi tetap valid secara struktur)
        imagePathsAfter: [],
        measurementsAfter: dummyMeasurementsAfter,
        selectedIndoorNoteAfter: event.reason,
        selectedOutdoorNoteAfter: event.reason,
        selectedOutdoorPSINoteAfter: event.reason,

        problems: [], // Tidak ada masalah spesifik karena unit batal
        isCompleted: true, // <-- TANDAI SELESAI (Hijau)
        outdoorSerialNo: null, // Reset outdoor assignment
      );

      // 3. Simpan ke Hive (Sama seperti _onSaveValidationData)
      final box = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final existingKey = box.keys.cast<dynamic>().firstWhereOrNull(
            (key) =>
        box.get(key, defaultValue: null)?.serialNo == event.serialNo &&
            box.get(key, defaultValue: null)?.transNo == event.transNo,
      );

      if (existingKey != null) {
        await box.put(existingKey, validationEntry);
      } else {
        await box.add(validationEntry);
      }

      // 4. Hapus Assignment Outdoor (Jika ada, karena unit ini batal)
      final assignmentBox = Hive.box(kOutdoorUnitAssignmentsBox);
      final Map<dynamic, dynamic> currentAssignments =
          assignmentBox.get(event.transNo) ?? {};
      currentAssignments.remove(event.serialNo);
      await assignmentBox.put(event.transNo, currentAssignments);

      // 5. Emit Sukses
      emit(currentState.copyWith(
        saveStatus: ValidationSaveStatus.successFinal,
        saveMessage: "Unit berhasil ditandai tidak sesuai.",
      ));

    } catch (e) {
      print('Error marking unit as invalid: $e');
      emit(currentState.copyWith(
        saveStatus: ValidationSaveStatus.error,
        saveMessage: "Gagal membatalkan unit: $e",
      ));
    }
  }

  void _onNoteChanged(
      NoteChanged event, Emitter<ValidationDropdownState> emit) {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;

      if (event.isBefore) {
        switch (event.noteType) {
          case NoteType.indoor:
            emit(currentState.copyWith(selectedIndoorNoteBefore: event.note));
            break;
          case NoteType.outdoor:
            emit(currentState.copyWith(selectedOutdoorNoteBefore: event.note));
            break;
          case NoteType.outdoorPsi:
            emit(currentState.copyWith(selectedOutdoorPSINoteBefore: event.note));
            break;
        }
      } else {
        switch (event.noteType) {
          case NoteType.indoor:
            emit(currentState.copyWith(selectedIndoorNoteAfter: event.note));
            break;
          case NoteType.outdoor:
            emit(currentState.copyWith(selectedOutdoorNoteAfter: event.note));
            break;
          case NoteType.outdoorPsi:
            emit(currentState.copyWith(selectedOutdoorPSINoteAfter: event.note));
            break;
        }
      }
    }
  }

  void _onSelectOutdoorSerial(
      SelectOutdoorSerial event, Emitter<ValidationDropdownState> emit) {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      emit(currentState.copyWith(selectedOutdoorSerialNo: event.serialNo));
    }
  }

  void _onSelectUnitType(
      SelectUnitType event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    emit(currentState.copyWith(
      selectedUnitType: event.unitType,
      selectedProblemCards: [],
    ));
  }

  void _onAddProblemCard(
      AddProblemCard event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final isDuplicate = currentState.selectedProblemCards
        .any((c) => c.selectedProblemId == event.problemId);
    if (isDuplicate) return;

    final updated =
        List<SelectedProblemCard>.from(currentState.selectedProblemCards)
          ..add(SelectedProblemCard(
              selectedProblemId: event.problemId,
              selectedSolutionIds: event.solutionIds));
    emit(currentState.copyWith(selectedProblemCards: updated));
  }

  void _onRemoveProblemCard(
      RemoveProblemCard event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated = currentState.selectedProblemCards
        .where((card) => card.selectedProblemId != event.problemId)
        .toList();
    emit(currentState.copyWith(selectedProblemCards: updated));
  }

  void _onSelectProblemForCard(
      SelectProblemForCard event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final targetList =
        List<SelectedProblemCard>.from(currentState.selectedProblemCards);
    if (event.index < targetList.length) {
      targetList[event.index] = targetList[event.index].copyWith(
          selectedProblemId: event.problemId, selectedSolutionIds: []);
    }
    emit(currentState.copyWith(selectedProblemCards: targetList));
  }

  void _onSelectSolutionsForCard(
      SelectSolutionsForCard event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final targetList =
        List<SelectedProblemCard>.from(currentState.selectedProblemCards);
    if (event.index < targetList.length) {
      targetList[event.index] = targetList[event.index]
          .copyWith(selectedSolutionIds: event.solutionIds);
    }
    emit(currentState.copyWith(selectedProblemCards: targetList));
  }

  void _onAddCapturedPhotoBefore(
      AddCapturedPhotoBefore event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated =
        List<CapturedImageDetail>.from(currentState.capturedPhotosBefore)
          ..add(event.imageDetail);
    emit(currentState.copyWith(capturedPhotosBefore: updated));
  }

  void _onRemoveCapturedPhotoBefore(
      RemoveCapturedPhotoBefore event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated = currentState.capturedPhotosBefore
        .where((img) => img.imagePath != event.imagePath)
        .toList();
    emit(currentState.copyWith(capturedPhotosBefore: updated));
  }

  void _onUpdateMeasurementBefore(
      UpdateMeasurementBefore event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated =
        List<MeasurementEntry>.from(currentState.capturedMeasurementsBefore);
    final index = updated
        .indexWhere((m) => m.measurementId == event.measurement.measurementId);
    if (index != -1) {
      updated[index] = event.measurement;
    } else {
      updated.add(event.measurement);
    }
    emit(currentState.copyWith(capturedMeasurementsBefore: updated));
  }

  void _onAddCapturedPhotoAfter(
      AddCapturedPhotoAfter event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated =
        List<CapturedImageDetail>.from(currentState.capturedPhotosAfter)
          ..add(event.imageDetail);
    emit(currentState.copyWith(capturedPhotosAfter: updated));
  }

  void _onRemoveCapturedPhotoAfter(
      RemoveCapturedPhotoAfter event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated = currentState.capturedPhotosAfter
        .where((img) => img.imagePath != event.imagePath)
        .toList();
    emit(currentState.copyWith(capturedPhotosAfter: updated));
  }

  void _onUpdateMeasurementAfter(
      UpdateMeasurementAfter event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated =
        List<MeasurementEntry>.from(currentState.capturedMeasurementsAfter);
    final index = updated
        .indexWhere((m) => m.measurementId == event.measurement.measurementId);
    if (index != -1) {
      updated[index] = event.measurement;
    } else {
      updated.add(event.measurement);
    }
    emit(currentState.copyWith(capturedMeasurementsAfter: updated));
  }

  void _onChangeValidationStep(
      ChangeValidationStep event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;

    emit(currentState.copyWith(currentStep: event.step));
  }

  // BARU: Handler untuk mengubah mode tampilan
  void _onChangeValidationViewMode(
      ChangeValidationViewMode event, Emitter<ValidationDropdownState> emit) {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      emit(currentState.copyWith(currentViewMode: event.mode));
    }
  }

  // BARU: Handler untuk menyimpan data validasi ke Hive
  Future<void> _onSaveValidationData(
      SaveValidationData event, Emitter<ValidationDropdownState> emit) async {

    if (state is! ValidationDropdownLoaded) return;

    final stateSaatEventMulai = state as ValidationDropdownLoaded;

    emit(stateSaatEventMulai.copyWith(saveStatus: ValidationSaveStatus.saving));

    try {
      // 4. Buat objek data yang akan disimpan (menggunakan stateSaatEventMulai)
      final validationEntry = ServiceCallValidationEntryModel(
        unitType: stateSaatEventMulai.selectedUnitType ?? '',
        serialNo: event.serialNo,
        transNo: event.transNo,
        imagePathsBefore: stateSaatEventMulai.capturedPhotosBefore,
        measurementsBefore: stateSaatEventMulai.capturedMeasurementsBefore,
        problems: stateSaatEventMulai.selectedProblemCards
            .map((card) => ValidationProblem(
            problemId: card.selectedProblemId!,
            solutionIds: card.selectedSolutionIds))
            .toList(),
        imagePathsAfter: stateSaatEventMulai.capturedPhotosAfter,
        measurementsAfter: stateSaatEventMulai.capturedMeasurementsAfter,
        isCompleted: event.markAsCompleted,
        outdoorSerialNo: stateSaatEventMulai.selectedOutdoorSerialNo,
        selectedIndoorNoteBefore: stateSaatEventMulai.selectedIndoorNoteBefore,
        selectedOutdoorNoteBefore: stateSaatEventMulai.selectedOutdoorNoteBefore,
        selectedIndoorNoteAfter: stateSaatEventMulai.selectedIndoorNoteAfter,
        selectedOutdoorNoteAfter: stateSaatEventMulai.selectedOutdoorNoteAfter,
        selectedOutdoorPSINoteBefore: stateSaatEventMulai.selectedOutdoorPSINoteBefore,
        selectedOutdoorPSINoteAfter: stateSaatEventMulai.selectedOutdoorPSINoteAfter,
      );

      // 5. Lakukan proses async (menyimpan ke Hive)
      final box = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final existingKey = box.keys.cast<dynamic>().firstWhereOrNull(
            (key) =>
        box.get(key, defaultValue: null)?.serialNo == event.serialNo &&
            box.get(key, defaultValue: null)?.transNo == event.transNo,
      );

      if (existingKey != null) {
        await box.put(existingKey, validationEntry);
      } else {
        await box.add(validationEntry);
      }

      final assignmentBox = Hive.box(kOutdoorUnitAssignmentsBox);
      final Map<dynamic, dynamic> currentAssignments =
          assignmentBox.get(event.transNo) ?? {};
      if (stateSaatEventMulai.selectedOutdoorSerialNo != null &&
          stateSaatEventMulai.selectedOutdoorSerialNo!.isNotEmpty) {
        currentAssignments[event.serialNo] =
            stateSaatEventMulai.selectedOutdoorSerialNo;
      } else {
        currentAssignments.remove(event.serialNo);
      }
      await assignmentBox.put(event.transNo, currentAssignments);

      if (event.markAsCompleted) {
        emit((state as ValidationDropdownLoaded).copyWith(
          saveStatus: ValidationSaveStatus.successFinal,
          saveMessage: "Validasi berhasil disimpan!",
        ));
      } else {
        if (event.showNotification) {
          emit((state as ValidationDropdownLoaded).copyWith(
            saveStatus: ValidationSaveStatus.successDraft, // Tetap 'Draft'
            saveMessage: "Draft berhasil disimpan",
          ));
        } else {
          emit((state as ValidationDropdownLoaded).copyWith(
            saveStatus: ValidationSaveStatus.successSilent,
          ));
        }
      }

    } catch (e) {
      print('Error saving validation data to Hive: $e');
      emit((state as ValidationDropdownLoaded).copyWith(
        saveStatus: ValidationSaveStatus.error,
        saveMessage: "Gagal menyimpan data: $e",
      ));
    }
  }
}
