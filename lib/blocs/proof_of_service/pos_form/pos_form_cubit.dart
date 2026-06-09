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

import '../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../auth/auth_storage.dart';

class PosFormCubit extends Cubit<PosFormState> {
  final String transNo;
  final Box<PosTransactionInfoModel> _transactionInfoBox;
  String _userType = '';
  String _userName = '';
  String _userId = '';
  List<Map<String, String>> _technicianList = [];

  String get userType => _userType;
  List<Map<String, String>> get technicianList => _technicianList;

  /// Cari NIK (technician_id) teknisi berdasarkan nama di technicianList.
  /// Kembalikan '' bila tidak ketemu (mis. nama diketik manual / di luar list).
  String _nikForName(String name) {
    if (name.isEmpty) return '';
    final match = _technicianList
        .firstWhereOrNull((t) => t['technician_name'] == name);
    return match?['technician_id'] ?? '';
  }

  // Helper Key Konsisten
  String _getHiveKey(String transNo) =>
      transNo.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  PosFormCubit({required this.transNo, required bool initialAllUnitsValidated})
      : _transactionInfoBox =
  Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox),
        super(const PosFormState()) {
    _initAsync();
  }

  Future<void> _initAsync() async {
    final userData = await AuthStorage.getUser();
    _userType = userData['maintenance_type'] ?? 'WH';
    _userName = userData['name'] ?? '';
    _userId = userData['user_id'] ?? '';

    final configBox = Hive.box(kAppConfigBox);
    final rawList = configBox.get('technician_list');
    if (rawList is List) {
      _technicianList = rawList.whereType<Map>().map((t) => {
        'technician_id': (t['technician_id'] ?? '') as String,
        'technician_name': (t['technician_name'] ?? '') as String,
      }).toList();
    }

    _loadInitialData();
  }

  void _loadInitialData() {
    final String hiveKey = _getHiveKey(transNo);
    final info = _transactionInfoBox.get(hiveKey);

    if (info != null) {
      emit(state.copyWith(
        picName: info.picName ?? '',
        picNik: info.picNik ?? '',
        picPosition: info.picPosition ?? '',
        picPhone: info.picPhone ?? '',
        technician1: info.technician1 ?? '',
        technician2: info.technician2 ?? '',
        technician3: info.technician3 ?? '',
        // Teknisi 1 = user yang login → NIK selalu user_id.
        // Teknisi 2/3 pakai NIK tersimpan, fallback resolve dari nama (draft lama).
        technician1Nik:
            (info.technician1 ?? '').isEmpty ? '' : _userId,
        technician2Nik: (info.technician2Nik?.isNotEmpty ?? false)
            ? info.technician2Nik!
            : _nikForName(info.technician2 ?? ''),
        technician3Nik: (info.technician3Nik?.isNotEmpty ?? false)
            ? info.technician3Nik!
            : _nikForName(info.technician3 ?? ''),
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
    } else {
      String initialTechnician1 = '';
      if (_userType == 'WH') {
        initialTechnician1 = _userName;
      }

      final String initialTechnician1Nik =
          initialTechnician1.isEmpty ? '' : _userId;

      final newDraft = PosTransactionInfoModel(
        transNo: transNo,
        technician1: initialTechnician1,
        technician1Nik: initialTechnician1Nik,
      );
      _transactionInfoBox.put(hiveKey, newDraft);
      emit(state.copyWith(
        technician1: initialTechnician1,
        technician1Nik: initialTechnician1Nik,
      ));
    }
    _validateForm();
  }

  // --- 🔥 TAMBAHAN UTAMA: Method Sync Foto dari Screen ---
  void picImageChanged(CapturedImageDetail? image) =>
      emit(state.copyWith(picImageDetail: image));
  // -----------------------------------------------------

  void tempInSkipped(bool isSkipped) {
    emit(state.copyWith(
      isTempInSkipped: isSkipped,
      tempIn: isSkipped ? '' : state.tempIn,
      clearTemperatureInImage: isSkipped,
      tempInNote: !isSkipped ? '' : state.tempInNote,
    ));
    onFieldChanged();
  }

  void tempOutSkipped(bool isSkipped) {
    emit(state.copyWith(
      isTempOutSkipped: isSkipped,
      tempOut: isSkipped ? '' : state.tempOut,
      clearTemperatureOutImage: isSkipped,
      tempOutNote: !isSkipped ? '' : state.tempOutNote,
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
      clearFinalTempInImage: isSkipped,
      finalTempInNote: !isSkipped ? '' : state.finalTempInNote,
    ));
    onFieldChanged();
  }

  void finalTempInChanged(String value) =>
      emit(state.copyWith(finalTempIn: value));

  void finalTempInImageChanged(CapturedImageDetail? image) {
    if (image == null) {
      emit(state.copyWith(clearFinalTempInImage: true));
    } else {
      emit(state.copyWith(finalTempInImage: image));
    }
  }

  void recalculateFinalTempLimit() {
    final validationBox =
    Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);

    final indoorEntries = validationBox.values.where((e) {
      bool isComplete = e.isCompleted ?? false;
      return e.transNo == transNo &&
          e.articleType?.toUpperCase() == 'IN' &&
          isComplete;
    });

    double minTemp = double.infinity;

    for (final entry in indoorEntries) {
      final tempMeasurement = entry.measurementsAfter.firstWhereOrNull((m) {
        bool isSkip = m.isSkipped ?? false;
        return m.measurementId == 'temperature' && !isSkip;
      });
      if (tempMeasurement != null) {
        minTemp = min(minTemp, tempMeasurement.value);
      }
    }

    final newLimit = (minTemp == double.infinity) ? 4.0 : minTemp;
    if (state.minFinalTempInLimit != newLimit) {
      emit(state.copyWith(minFinalTempInLimit: newLimit));
    }
  }

  // --- Methods for UI events ---
  void picNameChanged(String value) => emit(state.copyWith(picName: value));
  void picNikChanged(String value) => emit(state.copyWith(picNik: value));
  void picPositionChanged(String value) => emit(state.copyWith(picPosition: value));
  void picPhoneChanged(String value) => emit(state.copyWith(picPhone: value));
  void tempInChanged(String value) => emit(state.copyWith(tempIn: value));
  void tempOutChanged(String value) => emit(state.copyWith(tempOut: value));
  void technician1Changed(String value) => emit(state.copyWith(
        technician1: value,
        technician1Nik: value.isEmpty ? '' : _userId,
      ));
  void technician2Changed(String value) => emit(state.copyWith(
        technician2: value,
        technician2Nik: _nikForName(value),
      ));
  void technician3Changed(String value) => emit(state.copyWith(
        technician3: value,
        technician3Nik: _nikForName(value),
      ));
  void toggleTechnician3(bool show) => emit(state.copyWith(showTechnician3: show));
  void tempInImageChanged(CapturedImageDetail? image) {
    if (image == null) {
      emit(state.copyWith(clearTemperatureInImage: true));
    } else {
      emit(state.copyWith(temperatureInImage: image));
    }
  }

  void tempOutImageChanged(CapturedImageDetail? image) {
    if (image == null) {
      emit(state.copyWith(clearTemperatureOutImage: true));
    } else {
      emit(state.copyWith(temperatureOutImage: image));
    }
  }

  void onFieldChanged() {
    _validateForm();
    EasyDebounce.debounce(
      'save-to-hive-debouncer',
      const Duration(milliseconds: 500),
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

    final technicianValid = state.technician1.isNotEmpty;

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

    final isReady = picStoreValid &&
        technicianValid &&
        serviceInfoValid &&
        state.allUnitsValidated &&
        finalTempValid;

    emit(state.copyWith(
      isPicStoreValid: picStoreValid,
      isServiceInfoValid: serviceInfoValid,
      isFormReadyToSubmit: isReady,
    ));
  }

  // 🔥 FIX LOGIC SAVE (Baca dulu, baru update)
  Future<void> _saveStateToHive() async {
    final String key = _getHiveKey(transNo);

    // 1. Ambil data lama
    var infoToSave = _transactionInfoBox.get(key);

    // 2. Jika tidak ada, baru buat baru
    if (infoToSave == null) {
      infoToSave = PosTransactionInfoModel(transNo: transNo);
    }

    // 3. Update field
    infoToSave.picName = state.picName;
    infoToSave.picNik = state.picNik;
    infoToSave.picPosition = state.picPosition;
    infoToSave.picPhone = state.picPhone;
    infoToSave.technician1 = state.technician1;
    infoToSave.technician2 = state.technician2;
    infoToSave.technician3 = state.technician3;
    infoToSave.technician1Nik = state.technician1Nik;
    infoToSave.technician2Nik = state.technician2Nik;
    infoToSave.technician3Nik = state.technician3Nik;
    infoToSave.temperatureIn = state.tempIn;
    infoToSave.temperatureOut = state.tempOut;
    infoToSave.serviceTime = state.serviceTime;

    // Pastikan foto ikut tersimpan jika sudah ada di state
    infoToSave.picImageDetail = state.picImageDetail;

    infoToSave.temperatureInImage = state.temperatureInImage;
    infoToSave.temperatureOutImage = state.temperatureOutImage;
    infoToSave.finalTemperatureIn = state.finalTempIn;
    infoToSave.finalTemperatureInImage = state.finalTempInImage;
    infoToSave.isTempInSkipped = state.isTempInSkipped;
    infoToSave.tempInNote = state.tempInNote;
    infoToSave.isTempOutSkipped = state.isTempOutSkipped;
    infoToSave.tempOutNote = state.tempOutNote;
    infoToSave.isFinalTempInSkipped = state.isFinalTempInSkipped;
    infoToSave.finalTempInNote = state.finalTempInNote;

    // 4. Save
    await _transactionInfoBox.put(key, infoToSave);
  }
}