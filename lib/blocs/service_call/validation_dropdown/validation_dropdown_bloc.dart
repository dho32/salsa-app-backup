// lib/blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart'; // Diperlukan untuk save Hive
import '../../../components/constants.dart';
import 'validation_dropdown_event.dart';
import 'validation_dropdown_state.dart';
import 'package:hive/hive.dart'; // Untuk Hive.box

class ValidationDropdownBloc
    extends Bloc<ValidationDropdownEvent, ValidationDropdownState> {

  ValidationDropdownBloc()
      : super(ValidationDropdownInitial()) {
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
  }

  List<MeasurementEntry> _getDefaultMeasurements() {

    return kMeasurementLimits.values
        .map((limits) => MeasurementEntry(
              measurementId: limits.id,
              value: limits.min, // Inisialisasi dengan 0.0
              unit: limits.unit,
            ))
        .toList();
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
              : _getDefaultMeasurements();
      List<MeasurementEntry> measurementsAfter =
          initialData?.measurementsAfter.isNotEmpty == true
              ? initialData!.measurementsAfter
              : _getDefaultMeasurements();

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
        ),
      );
    } catch (e) {
      emit(ValidationDropdownError(e.toString()));
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
    if (state is ValidationDropdownLoaded) {
      final currentState = state as ValidationDropdownLoaded;
      try {
        final validationEntry = ServiceCallValidationEntryModel(
          unitType: currentState.selectedUnitType ?? '',
          serialNo: event.serialNo,
          transNo: event.transNo,
          imagePathsBefore: currentState.capturedPhotosBefore,
          measurementsBefore: currentState.capturedMeasurementsBefore,
          problems: currentState.selectedProblemCards
              .map((card) => ValidationProblem(
                  problemId: card.selectedProblemId!,
                  solutionIds: card.selectedSolutionIds))
              .toList(),
          imagePathsAfter: currentState.capturedPhotosAfter,
          measurementsAfter: currentState.capturedMeasurementsAfter,
          isCompleted: event.markAsCompleted,
          outdoorSerialNo: currentState.selectedOutdoorSerialNo,
        );

        final box = await Hive.openBox<ServiceCallValidationEntryModel>(
            kServiceCallHiveBox);
        final existingKey = box.keys.cast<int?>().firstWhere(
              (key) =>
                  box.get(key)?.serialNo == event.serialNo &&
                  box.get(key)?.transNo == event.transNo,
              orElse: () => null,
            );

        if (existingKey != null) {
          await box.put(existingKey, validationEntry);
        } else {
          await box.add(validationEntry);
        }

        final assignmentBox = await Hive.openBox(kOutdoorUnitAssignmentsBox);
        final Map<dynamic, dynamic> currentAssignments =
            assignmentBox.get(event.transNo) ?? {};

        if (currentState.selectedOutdoorSerialNo != null &&
            currentState.selectedOutdoorSerialNo!.isNotEmpty) {
          currentAssignments[event.serialNo] =
              currentState.selectedOutdoorSerialNo;
        } else {
          currentAssignments.remove(event.serialNo);
        }

        await assignmentBox.put(event.transNo, currentAssignments);
        print(
            'Assignment data for ${event.serialNo} saved to Hive successfully!');
      } catch (e) {
        print('Error saving validation data to Hive: $e');
        // Anda bisa emit ValidationDropdownError di sini jika perlu
      }
    }
  }

// Ini adalah helper untuk mengambil foto dengan Geolocation, jika dibutuhkan secara internal oleh Bloc
// Namun, _handlePhoto di UI sudah memanggil Geocoding/Geolocator, jadi ini mungkin tidak diperlukan
/*
  Future<CapturedImageDetail> _capturePhotoWithLocation() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) throw Exception('No image selected.');

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks.first;
    String address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";

    return CapturedImageDetail(
      imagePath: image.path,
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }
  */
}
