// lib/blocs/proof_of_service/pos_form/pos_form_cubit.dart

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:easy_debounce/easy_debounce.dart';

import '../../../models/proof_of_service/pos_validation_entry_model.dart'; // Tambahkan package ini: flutter pub add easy_debounce

class PosFormCubit extends Cubit<PosFormState> {
  final String transNo;
  final Box<PosTransactionInfoModel> _transactionInfoBox;

  PosFormCubit({required this.transNo, required bool initialAllUnitsValidated})
      : _transactionInfoBox =
            Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox),
        super(const PosFormState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final info = _transactionInfoBox.get(transNo);
    if (info != null) {
      emit(state.copyWith(
        picName: info.picName ?? '',
        picNik: info.picNik ?? '',
        picPosition: info.picPosition ?? '',
        picPhone: info.picPhone ?? '',
        technician2: info.technician2 ?? '',
        technician3: info.technician3 ?? '',
        showTechnician3: (info.technician3 ?? '').isNotEmpty,
        tempIn: info.temperatureIn ?? '',
        tempOut: info.temperatureOut ?? '',
        serviceTime: info.serviceTime ?? '',
        picImageDetail: info.picImageDetail,
        temperatureInImage: info.temperatureInImage,
        temperatureOutImage: info.temperatureOutImage,
        finalTempIn: info.finalTemperatureIn ?? '',
        finalTempInImage: info.finalTemperatureInImage,
        isTempInSkipped: info.isTempInSkipped ?? false,
        tempInNote: info.tempInNote ?? '',
        isTempOutSkipped: info.isTempOutSkipped ?? false,
        tempOutNote: info.tempOutNote ?? '',
        isFinalTempInSkipped: info.isFinalTempInSkipped ?? false,
        finalTempInNote: info.finalTempInNote ?? '',
      ));
    }
    _validateForm();
  }

  void tempInSkipped(bool isSkipped) {
    emit(state.copyWith(
      isTempInSkipped: isSkipped,
      tempIn: isSkipped ? '' : state.tempIn,
      temperatureInImage: isSkipped ? null : state.temperatureInImage,
      tempInNote:
          !isSkipped ? '' : state.tempInNote, // Reset note jika di-unskip
    ));
    onFieldChanged();
  }

  void tempOutSkipped(bool isSkipped) {
    emit(state.copyWith(
      isTempOutSkipped: isSkipped,
      tempOut: isSkipped ? '' : state.tempOut,
      temperatureOutImage: isSkipped ? null : state.temperatureOutImage,
      tempOutNote: !isSkipped ? '' : state.tempOutNote, // Reset note
    ));
    onFieldChanged();
  }

  void tempInNoteChanged(String value) {
    emit(state.copyWith(tempInNote: value));
    onFieldChanged();
  }

  void tempOutNoteChanged(String value) {
    emit(state.copyWith(tempOutNote: value));
    onFieldChanged();
  }

  void finalTempInNoteChanged(String value) {
    emit(state.copyWith(finalTempInNote: value));
    onFieldChanged();
  }

  void finalTempInSkipped(bool isSkipped) {
    emit(state.copyWith(
      isFinalTempInSkipped: isSkipped,
      finalTempIn: isSkipped ? '' : state.finalTempIn,
      finalTempInImage: isSkipped ? null : state.finalTempInImage,
      finalTempInNote: !isSkipped ? '' : state.finalTempInNote, // Reset note
    ));
    onFieldChanged();
  }

  void finalTempInChanged(String value) =>
      emit(state.copyWith(finalTempIn: value));

  void finalTempInImageChanged(CapturedImageDetail? image) =>
      emit(state.copyWith(finalTempInImage: image));

  void recalculateFinalTempLimit() {
    final validationBox =
        Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);

    final indoorEntries = validationBox.values.where((e) {
      bool isComplete = e.isCompleted ?? false;
      return e.transNo == transNo &&
          e.articleType?.toUpperCase() == 'IN' &&
          isComplete;
    });

    double minTemp = double.infinity; // Mulai dengan nilai yang sangat tinggi

    for (final entry in indoorEntries) {
      final tempMeasurement = entry.measurementsAfter.firstWhereOrNull((m) {
        bool isSkip = m.isSkipped ?? false;
        return m.measurementId == 'temperature' && isSkip;
      });
      if (tempMeasurement != null) {
        minTemp = min(minTemp, tempMeasurement.value);
      }
    }

    // Jika tidak ada suhu yang ditemukan, jangan set batas. Jika ada, set batasnya.
    final newLimit = (minTemp == double.infinity) ? 4.0 : minTemp;

    // Hanya emit state jika nilainya berubah
    if (state.minFinalTempInLimit != newLimit) {
      emit(state.copyWith(minFinalTempInLimit: newLimit));
    }
  }

  // --- Methods for UI events ---
  void picNameChanged(String value) => emit(state.copyWith(picName: value));

  void picNikChanged(String value) => emit(state.copyWith(picNik: value));

  void picPositionChanged(String value) =>
      emit(state.copyWith(picPosition: value));

  void picPhoneChanged(String value) => emit(state.copyWith(picPhone: value));

  void tempInChanged(String value) => emit(state.copyWith(tempIn: value));

  void tempOutChanged(String value) => emit(state.copyWith(tempOut: value));

  void technician2Changed(String value) =>
      emit(state.copyWith(technician2: value));

  void technician3Changed(String value) =>
      emit(state.copyWith(technician3: value));

  void toggleTechnician3(bool show) =>
      emit(state.copyWith(showTechnician3: show));

  void tempInImageChanged(CapturedImageDetail? image) =>
      emit(state.copyWith(temperatureInImage: image));

  void tempOutImageChanged(CapturedImageDetail? image) =>
      emit(state.copyWith(temperatureOutImage: image));

  // Semua perubahan akan memicu validasi dan penyimpanan
  void onFieldChanged() {
    _validateForm();

    // Debounce untuk efisiensi penulisan ke Hive
    EasyDebounce.debounce(
      'save-to-hive-debouncer',
      const Duration(milliseconds: 500),
      // Tunggu 500ms setelah user berhenti mengetik
      _saveStateToHive,
    );
  }

  void updateAllUnitsValidated(bool allUnitsAreValid) {
    if (state.allUnitsValidated != allUnitsAreValid) {
      emit(state.copyWith(allUnitsValidated: allUnitsAreValid));
      _validateForm();
    }
  }

  void _validateForm() {
    final picStoreValid = state.picName.isNotEmpty &&
        state.picNik.isNotEmpty &&
        state.picPosition.isNotEmpty &&
        state.picPhone.isNotEmpty;

    final bool tempInValid =
        (state.tempIn.isNotEmpty && state.temperatureInImage != null) ||
            (state.isTempInSkipped && state.tempInNote.isNotEmpty);
    final bool tempOutValid =
        (state.tempOut.isNotEmpty && state.temperatureOutImage != null) ||
            (state.isTempOutSkipped && state.tempOutNote.isNotEmpty);

    final serviceInfoValid = tempInValid && tempOutValid;

    final finalTempValid =
        (state.finalTempIn.isNotEmpty && state.finalTempInImage != null) ||
            (state.isFinalTempInSkipped && state.finalTempInNote.isNotEmpty);

    // final isReady = picStoreValid && serviceInfoValid && state.allUnitsValidated;

    final isReady = picStoreValid &&
        serviceInfoValid &&
        state.allUnitsValidated &&
        (!state.allUnitsValidated || finalTempValid);

    emit(state.copyWith(
      isPicStoreValid: picStoreValid,
      isServiceInfoValid: serviceInfoValid,
      isFormReadyToSubmit: isReady,
    ));
  }

  Future<void> _saveStateToHive() async {
    final infoToSave = PosTransactionInfoModel(transNo: transNo)
      ..picName = state.picName
      ..picNik = state.picNik
      ..picPosition = state.picPosition
      ..picPhone = state.picPhone
      ..technician2 = state.technician2
      ..technician3 = state.technician3
      ..temperatureIn = state.tempIn
      ..temperatureOut = state.tempOut
      ..serviceTime = state.serviceTime
      ..picImageDetail = state.picImageDetail
      ..temperatureInImage = state.temperatureInImage
      ..temperatureOutImage = state.temperatureOutImage
      ..finalTemperatureIn = state.finalTempIn
      ..finalTemperatureInImage = state.finalTempInImage
      ..isTempInSkipped = state.isTempInSkipped
      ..tempInNote = state.tempInNote
      ..isTempOutSkipped = state.isTempOutSkipped
      ..tempOutNote = state.tempOutNote
      ..isFinalTempInSkipped = state.isFinalTempInSkipped
      ..finalTempInNote = state.finalTempInNote;

    await _transactionInfoBox.put(transNo, infoToSave);
  }
}
