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
    on<CorrectUnitSerial>(_onCorrectUnitSerial);
  }

  List<MeasurementEntry> _generateMeasurementsFromLimits(
      Map<String, MeasurementLimits> limitsMap) {
    final List<MeasurementEntry> list = [];
    for (final limits in limitsMap.values) {
      list.add(MeasurementEntry(
        measurementId: limits.id,
        value: 0.0,
        unit: limits.unit,
        isSkipped: false,
      ));
    }
    return list;
  }

  List<MeasurementEntry> _generateSkippedMeasurements(
      Map<String, dynamic> limitsMap) {
    return limitsMap.keys.map((key) {
      return MeasurementEntry(
        measurementId: key,
        value: 0.0,
        unit: '',
        isSkipped: true,
        capturedImage: null,
      );
    }).toList();
  }

  Future<void> _saveToHive(ValidationDropdownLoaded state) async {
    try {
      final box = await Hive.openBox<ServiceCallValidationEntryModel>(kServiceCallHiveBox);

      // 1. Logic Ekstrak Remark (Sama seperti onSaveData)
      String? getRemarkFromList(List<MeasurementEntry> list, Set<String> ids) {
        return list.firstWhereOrNull(
                (m) => ids.contains(m.measurementId) && (m.isSkipped ?? false)
        )?.remark;
      }
      const indoorIds = {'temperature'};
      const outdoorElecIds = {'volt', 'ampere'};
      const outdoorPsiIds = {'psi'};

      final listToCheck = state.capturedMeasurementsAfter;
      final remarkIndoor = getRemarkFromList(listToCheck, indoorIds);
      final remarkOutdoor = getRemarkFromList(listToCheck, outdoorElecIds);
      final remarkPSI = getRemarkFromList(listToCheck, outdoorPsiIds);

      // 2. Cari Data Lama (Untuk Swap & Remark)
      final searchSerial = state.serialNo.trim().toUpperCase();
      final searchTransNo = state.transNo.trim().toUpperCase();

      final existingKey = box.keys.cast<dynamic>().firstWhereOrNull((key) {
        final entry = box.get(key);
        return entry?.serialNo.trim().toUpperCase() == searchSerial &&
            entry?.transNo.trim().toUpperCase() == searchTransNo;
      });

      String? existingCorrectSerial;
      String? existingNoteRemark;

      if (existingKey != null) {
        final oldData = box.get(existingKey);
        existingCorrectSerial = oldData?.correctSerialNo;
        existingNoteRemark = oldData?.noteRemark;
      }

      // 3. Buat Model (IS COMPLETED = FALSE karena ini auto-save/draft)
      final validationEntry = ServiceCallValidationEntryModel(
        unitType: state.selectedUnitType ?? '',
        serialNo: state.serialNo,
        transNo: state.transNo,

        imagePathsBefore: state.capturedPhotosBefore,
        measurementsBefore: state.capturedMeasurementsBefore,
        imagePathsAfter: state.capturedPhotosAfter,
        measurementsAfter: state.capturedMeasurementsAfter,

        problems: state.selectedProblemCards
            .map((card) => ValidationProblem(
            problemId: card.selectedProblemId!,
            solutionIds: card.selectedSolutionIds))
            .toList(),

        isCompleted: false, // Draft
        outdoorSerialNo: state.selectedOutdoorSerialNo,

        selectedIndoorNoteBefore: state.selectedIndoorNoteBefore,
        selectedOutdoorNoteBefore: state.selectedOutdoorNoteBefore,
        selectedIndoorNoteAfter: state.selectedIndoorNoteAfter,
        selectedOutdoorNoteAfter: state.selectedOutdoorNoteAfter,
        selectedOutdoorPSINoteBefore: state.selectedOutdoorPSINoteBefore,
        selectedOutdoorPSINoteAfter: state.selectedOutdoorPSINoteAfter,

        noteRemarkIndoor: remarkIndoor,
        noteRemarkOutdoor: remarkOutdoor,
        noteRemarkPSI: remarkPSI,

        correctSerialNo: existingCorrectSerial,
        noteRemark: existingNoteRemark,
      );

      if (existingKey != null) {
        await box.put(existingKey, validationEntry);
      } else {
        await box.add(validationEntry);
      }

      // (Opsional) Simpan juga outdoor assignment
      final assignmentBox = Hive.box(kOutdoorUnitAssignmentsBox);
      final Map<dynamic, dynamic> currentAssignments = assignmentBox.get(state.transNo) ?? {};
      if (state.selectedOutdoorSerialNo != null && state.selectedOutdoorSerialNo!.isNotEmpty) {
        currentAssignments[state.serialNo] = state.selectedOutdoorSerialNo;
      } else {
        currentAssignments.remove(state.serialNo);
      }
      await assignmentBox.put(state.transNo, currentAssignments);

    } catch (e) {
      print("Gagal auto-save SC: $e");
    }
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
              : _generateMeasurementsFromLimits(event.limitsScBefore);

      List<MeasurementEntry> measurementsAfter =
          initialData?.measurementsAfter.isNotEmpty == true
              ? initialData!.measurementsAfter
              : _generateMeasurementsFromLimits(event.limitsScAfter);

      emit(
        ValidationDropdownLoaded(
          transNo: event.transNo,
          serialNo: event.currentIndoorSerial,
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

          // --- PASS THROUGH NOTE OPTIONS (TANPA FILTER) ---
          noteIndoorBeforeOptions: event.detailData.noteIndoorBeforeOptions,
          noteIndoorAfterOptions: event.detailData.noteIndoorAfterOptions,
          noteOutdoorBeforeOptions: event.detailData.noteOutdoorBeforeOptions,
          noteOutdoorAfterOptions: event.detailData.noteOutdoorAfterOptions,
          noteOutdoorPsiBeforeOptions:
              event.detailData.noteOutdoorPsiBeforeOptions,
          noteOutdoorPsiAfterOptions:
              event.detailData.noteOutdoorPsiAfterOptions,
          // ------------------------------------------------

          selectedIndoorNoteBefore: initialData?.selectedIndoorNoteBefore,
          selectedOutdoorNoteBefore: initialData?.selectedOutdoorNoteBefore,
          selectedIndoorNoteAfter: initialData?.selectedIndoorNoteAfter,
          selectedOutdoorNoteAfter: initialData?.selectedOutdoorNoteAfter,
          selectedOutdoorPSINoteBefore:
              initialData?.selectedOutdoorPSINoteBefore,
          selectedOutdoorPSINoteAfter: initialData?.selectedOutdoorPSINoteAfter,

          correctSerialNo: initialData?.correctSerialNo,
        ),
      );
    } catch (e) {
      emit(ValidationDropdownError(e.toString()));
    }
  }

  Future<void> _onCorrectUnitSerial(
      CorrectUnitSerial event, Emitter<ValidationDropdownState> emit) async {
    if (state is! ValidationDropdownLoaded) return;
    final currentState = state as ValidationDropdownLoaded;

    emit(currentState.copyWith(saveStatus: ValidationSaveStatus.saving));

    try {
      final box = await Hive.openBox<ServiceCallValidationEntryModel>(
          kServiceCallHiveBox);

      // Cari data draft yang sudah ada (berdasarkan serial LAMA/TIKET)
      // Kunci utama di Hive tetap menggunakan serial dari tiket
      final existingKey = box.keys.cast<dynamic>().firstWhereOrNull(
            (key) =>
                box.get(key, defaultValue: null)?.serialNo ==
                    event.oldSerialNo &&
                box.get(key, defaultValue: null)?.transNo == event.transNo,
          );

      // LOGIC REVERT:
      // Jika user memilih serial yang SAMA dengan serial tiket, berarti dia membatalkan swap.
      // Kita set correctSerialNo jadi NULL.
      final isRevert = event.newSerialNo == event.oldSerialNo;
      final String? valueToSave = isRevert ? null : event.newSerialNo;
      String newNoteRemark = event.reason;

      if (existingKey != null) {
        // 1. UPDATE DRAFT YANG ADA
        final entry = box.get(existingKey)!;
        entry.correctSerialNo = valueToSave;

        // Append alasan ke noteRemark agar tercatat di history lokal
        if (!isRevert) {
          entry.noteRemark = newNoteRemark;
        }

        await entry.save();
      } else {
        // 2. BUAT DRAFT BARU
        final newEntry = ServiceCallValidationEntryModel(
          transNo: event.transNo,
          serialNo: event.oldSerialNo,
          // ID Tetap Serial Lama
          unitType: currentState.selectedUnitType ?? 'UNIT',

          // Simpan Data Koreksi
          correctSerialNo: valueToSave,
          noteRemark: newNoteRemark,

          // Default kosong
          imagePathsBefore: [],
          measurementsBefore: [],
          imagePathsAfter: [],
          measurementsAfter: [],
          problems: [],
          isCompleted: false,
          outdoorSerialNo: null,
          device: null,
        );
        await box.add(newEntry);
      }

      // Update State agar UI Header bisa langsung berubah
      emit(currentState.copyWith(
        saveStatus: ValidationSaveStatus.successDraft,
        saveMessage: isRevert
            ? "Unit dikembalikan ke original."
            : "Unit berhasil ditukar.",
        correctSerialNo: valueToSave, // Update state header
      ));

      // Reset status
      await Future.delayed(const Duration(milliseconds: 100));
      emit(currentState.copyWith(saveStatus: ValidationSaveStatus.initial));
    } catch (e) {
      print('Error correcting serial: $e');
      emit(currentState.copyWith(
        saveStatus: ValidationSaveStatus.error,
        saveMessage: "Gagal update serial: $e",
      ));
    }
  }

  void _onNoteChanged(
      NoteChanged event, Emitter<ValidationDropdownState> emit) {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      ValidationDropdownLoaded newState = currentState;

      if (event.isBefore) {
        switch (event.noteType) {
          case NoteType.indoor: newState = currentState.copyWith(selectedIndoorNoteBefore: event.note); break;
          case NoteType.outdoor: newState = currentState.copyWith(selectedOutdoorNoteBefore: event.note); break;
          case NoteType.outdoorPsi: newState = currentState.copyWith(selectedOutdoorPSINoteBefore: event.note); break;
        }
      } else {
        switch (event.noteType) {
          case NoteType.indoor: newState = currentState.copyWith(selectedIndoorNoteAfter: event.note); break;
          case NoteType.outdoor: newState = currentState.copyWith(selectedOutdoorNoteAfter: event.note); break;
          case NoteType.outdoorPsi: newState = currentState.copyWith(selectedOutdoorPSINoteAfter: event.note); break;
        }
      }
      emit(newState);
      _saveToHive(newState); // Auto Save
    }
  }

  void _onSelectOutdoorSerial(
      SelectOutdoorSerial event, Emitter<ValidationDropdownState> emit) {
    if (state is ValidationDropdownLoaded) {
      final newState = (state as ValidationDropdownLoaded).copyWith(selectedOutdoorSerialNo: event.serialNo);
      emit(newState);
      _saveToHive(newState); // Auto Save
    }
  }

  void _onSelectUnitType(
      SelectUnitType event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final newState = currentState.copyWith(
      selectedUnitType: event.unitType,
      selectedProblemCards: [],
    );
    emit(newState);
    _saveToHive(newState);
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
    final newState = currentState.copyWith(selectedProblemCards: updated);
    emit(newState);
    _saveToHive(newState);
  }

  void _onRemoveProblemCard(
      RemoveProblemCard event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;
    final updated = currentState.selectedProblemCards
        .where((card) => card.selectedProblemId != event.problemId)
        .toList();
    final newState = currentState.copyWith(selectedProblemCards: updated);
    emit(newState);
    _saveToHive(newState);
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
    final newState = currentState.copyWith(selectedProblemCards: targetList);
    emit(newState);
    _saveToHive(newState);
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
    final newState = currentState.copyWith(selectedProblemCards: targetList);
    emit(newState);
    _saveToHive(newState);
  }

  Future<void> _onAddCapturedPhotoBefore(
      AddCapturedPhotoBefore event, Emitter<ValidationDropdownState> emit) async {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      final updated = List<CapturedImageDetail>.from(currentState.capturedPhotosBefore)..add(event.imageDetail);
      final newState = currentState.copyWith(capturedPhotosBefore: updated);
      emit(newState);
      await _saveToHive(newState); // Auto Save
    }
  }

  Future<void> _onRemoveCapturedPhotoBefore(
      RemoveCapturedPhotoBefore event, Emitter<ValidationDropdownState> emit) async {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      final updated = currentState.capturedPhotosBefore.where((p) => p.imagePath != event.imagePath).toList();
      final newState = currentState.copyWith(capturedPhotosBefore: updated);
      emit(newState);
      await _saveToHive(newState); // Auto Save
    }
  }

  Future<void> _onUpdateMeasurementBefore(
      UpdateMeasurementBefore event, Emitter<ValidationDropdownState> emit) async {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      final updated = List<MeasurementEntry>.from(currentState.capturedMeasurementsBefore);
      final index = updated.indexWhere((m) => m.measurementId == event.measurement.measurementId);
      if (index != -1) {
        updated[index] = event.measurement;
      } else {
        updated.add(event.measurement);
      }
      final newState = currentState.copyWith(capturedMeasurementsBefore: updated);
      emit(newState);
      await _saveToHive(newState); // Auto Save
    }
  }

  Future<void> _onAddCapturedPhotoAfter(
      AddCapturedPhotoAfter event, Emitter<ValidationDropdownState> emit) async {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      final updated = List<CapturedImageDetail>.from(currentState.capturedPhotosAfter)..add(event.imageDetail);
      final newState = currentState.copyWith(capturedPhotosAfter: updated);
      emit(newState);
      await _saveToHive(newState); // Auto Save
    }
  }

  Future<void> _onRemoveCapturedPhotoAfter(
      RemoveCapturedPhotoAfter event, Emitter<ValidationDropdownState> emit) async {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      final updated = currentState.capturedPhotosAfter.where((p) => p.imagePath != event.imagePath).toList();
      final newState = currentState.copyWith(capturedPhotosAfter: updated);
      emit(newState);
      await _saveToHive(newState); // Auto Save
    }
  }

  Future<void> _onUpdateMeasurementAfter(
      UpdateMeasurementAfter event, Emitter<ValidationDropdownState> emit) async {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      final updated = List<MeasurementEntry>.from(currentState.capturedMeasurementsAfter);
      final index = updated.indexWhere((m) => m.measurementId == event.measurement.measurementId);
      if (index != -1) {
        updated[index] = event.measurement;
      } else {
        updated.add(event.measurement);
      }
      final newState = currentState.copyWith(capturedMeasurementsAfter: updated);
      emit(newState);
      await _saveToHive(newState); // Auto Save
    }
  }

  void _onChangeValidationStep(
      ChangeValidationStep event, Emitter<ValidationDropdownState> emit) {
    final currentState = state as ValidationDropdownLoaded;

    emit(currentState.copyWith(currentStep: event.step));
  }

  // Handler untuk mengubah mode tampilan
  void _onChangeValidationViewMode(
      ChangeValidationViewMode event, Emitter<ValidationDropdownState> emit) {
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      emit(currentState.copyWith(currentViewMode: event.mode));
    }
  }

  Future<void> _onSaveValidationData(
      SaveValidationData event, Emitter<ValidationDropdownState> emit) async {

    if (state is! ValidationDropdownLoaded) return;
    final stateSaatEventMulai = state as ValidationDropdownLoaded;

    emit(stateSaatEventMulai.copyWith(saveStatus: ValidationSaveStatus.saving));

    try {
      // 1. LOGIC EKSTRAK REMARK DARI MEASUREMENTS

      String? getRemarkFromList(List<MeasurementEntry> list, Set<String> ids) {
        return list.firstWhereOrNull(
                (m) => ids.contains(m.measurementId) && (m.isSkipped ?? false)
        )?.remark;
      }

      const indoorIds = {'temperature'};
      const outdoorElecIds = {'volt', 'ampere'};
      const outdoorPsiIds = {'psi'};

      final listToCheck = stateSaatEventMulai.capturedMeasurementsAfter;

      final remarkIndoor = getRemarkFromList(listToCheck, indoorIds);
      final remarkOutdoor = getRemarkFromList(listToCheck, outdoorElecIds);
      final remarkPSI = getRemarkFromList(listToCheck, outdoorPsiIds);

      // 2. Ambil data lama (untuk swap)
      final box = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final existingKey = box.keys.cast<dynamic>().firstWhereOrNull(
            (key) =>
        box.get(key, defaultValue: null)?.serialNo == event.serialNo &&
            box.get(key, defaultValue: null)?.transNo == event.transNo,
      );

      String? existingCorrectSerial;
      String? existingNoteRemark; // Remark Swap Unit

      if (existingKey != null) {
        final oldData = box.get(existingKey);
        existingCorrectSerial = oldData?.correctSerialNo;
        existingNoteRemark = oldData?.noteRemark;

        print("🔍 DEBUG SAVE: Serial=$existingCorrectSerial, Remark=$existingNoteRemark");
      }

      // 3. Buat Model Baru dengan Data Lengkap
      final validationEntry = ServiceCallValidationEntryModel(
        unitType: stateSaatEventMulai.selectedUnitType ?? '',
        serialNo: event.serialNo,
        transNo: event.transNo,

        // Data List
        imagePathsBefore: stateSaatEventMulai.capturedPhotosBefore,
        measurementsBefore: stateSaatEventMulai.capturedMeasurementsBefore,
        imagePathsAfter: stateSaatEventMulai.capturedPhotosAfter,
        measurementsAfter: stateSaatEventMulai.capturedMeasurementsAfter,

        problems: stateSaatEventMulai.selectedProblemCards
            .map((card) => ValidationProblem(
            problemId: card.selectedProblemId!,
            solutionIds: card.selectedSolutionIds))
            .toList(),

        isCompleted: event.markAsCompleted,
        outdoorSerialNo: stateSaatEventMulai.selectedOutdoorSerialNo,

        // Note Pilihan Dropdown
        selectedIndoorNoteBefore: stateSaatEventMulai.selectedIndoorNoteBefore,
        selectedOutdoorNoteBefore: stateSaatEventMulai.selectedOutdoorNoteBefore,
        selectedIndoorNoteAfter: stateSaatEventMulai.selectedIndoorNoteAfter,
        selectedOutdoorNoteAfter: stateSaatEventMulai.selectedOutdoorNoteAfter,
        selectedOutdoorPSINoteBefore: stateSaatEventMulai.selectedOutdoorPSINoteBefore,
        selectedOutdoorPSINoteAfter: stateSaatEventMulai.selectedOutdoorPSINoteAfter,
        noteRemarkIndoor: remarkIndoor,
        noteRemarkOutdoor: remarkOutdoor,
        noteRemarkPSI: remarkPSI,
        correctSerialNo: existingCorrectSerial,
        noteRemark: existingNoteRemark,
      );

      if (existingKey != null) {
        await box.put(existingKey, validationEntry);
      } else {
        await box.add(validationEntry);
      }

      final assignmentBox = Hive.box(kOutdoorUnitAssignmentsBox);
      final Map<dynamic, dynamic> currentAssignments = assignmentBox.get(event.transNo) ?? {};
      if (stateSaatEventMulai.selectedOutdoorSerialNo != null && stateSaatEventMulai.selectedOutdoorSerialNo!.isNotEmpty) {
        currentAssignments[event.serialNo] = stateSaatEventMulai.selectedOutdoorSerialNo;
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
            saveStatus: ValidationSaveStatus.successDraft,
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
