import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/service_call/sc_form/sc_form_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/service_call/transaction_info_model.dart';
import 'package:easy_debounce/easy_debounce.dart';

import '../../../models/service_call/service_call_detail_model.dart';
import '../../../models/service_call/service_call_validation_entry_model.dart';
import '../../auth/auth_storage.dart';

class ScFormCubit extends Cubit<ScFormState> {
  final String transNo;
  late final Box<TransactionInfoModel> _transactionInfoBox;
  String _userType = '';
  String _userName = '';
  List<Map<String, String>> _technicianList = [];

  String get userType => _userType;
  List<Map<String, String>> get technicianList => _technicianList;

  String _normalizeHiveKey(String key) =>
      key.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  ScFormCubit({required this.transNo}) : super(const ScFormState()) {
    _initAndLoadData();
  }

  // Gabungkan inisialisasi dan load data
  Future<void> _initAndLoadData() async {
    final userData = await AuthStorage.getUser();
    _userType = userData['maintenance_type'] ?? 'WH'; // (Default 'WH')
    _userName = userData['name'] ?? '';

    final configBox = Hive.box(kAppConfigBox);
    final rawList = configBox.get('technician_list');
    if (rawList is List) {
      _technicianList = rawList.whereType<Map>().map((t) => {
        'technician_id': (t['technician_id'] ?? '') as String,
        'technician_name': (t['technician_name'] ?? '') as String,
      }).toList();
    }

    _transactionInfoBox =
        await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
    _loadInitialData();
  }

  void _loadInitialData() {
    final String normalizedKey =
        _normalizeHiveKey(transNo); // ✅ Normalisasi kunci
    try {
      final info =
          _transactionInfoBox.get(normalizedKey); // ✅ Gunakan kunci baru
      final String? validPosition =
          kJabatanOptions.contains(info?.picPosition ?? '')
              ? info?.picPosition!
              : '';
      if (info != null) {
        emit(state.copyWith(
          picName: info.picName ?? '',
          picNik: info.picNik ?? '',
          picPosition: validPosition ?? '',
          picPhone: info.picPhone ?? '',
          technician1: info.technician1 ?? '',
          technician2: info.technician2 ?? '',
          technician3: info.technician3 ?? '',
          showTechnician3: (info.technician3 ?? '').isNotEmpty,
          picImageDetail: info.picImageDetail,
          finalTempIn: info.finalTemperatureIn ?? '',
          finalTempInImage: info.finalTemperatureInImage,
          isFinalTempSkipped: info.isFinalTempSkipped ?? false,
          finalTempNote: info.finalTempNote,
        ));
      } else {
        String initialTechnician1 = '';
        if (_userType == 'WH') {
          initialTechnician1 = _userName; // Otomatis isi jika 'WH'
        }

        final newDraft = TransactionInfoModel(
          transNo: transNo,
          technician1: initialTechnician1,
        );
        _transactionInfoBox.put(normalizedKey, newDraft);
        emit(state.copyWith(technician1: initialTechnician1));
      }
    } catch (e) {
      // print(
      //     "🔴 Gagal memuat draft ScFormCubit (kemungkinan data lama tidak kompatibel): $e");
      _transactionInfoBox.delete(normalizedKey); // ✅ Gunakan kunci baru
    } finally {
      _validateForm();
    }
  }

  // --- Methods for UI events ---
  void picNameChanged(String value) => emit(state.copyWith(picName: value));

  void picNikChanged(String value) => emit(state.copyWith(picNik: value));

  void picPositionChanged(String value) =>
      emit(state.copyWith(picPosition: value));

  void picPhoneChanged(String value) => emit(state.copyWith(picPhone: value));

  void picImageChanged(CapturedImageDetail? image) =>
      emit(state.copyWith(picImageDetail: image));

  void technician1Changed(String value) =>
      emit(state.copyWith(technician1: value));

  void technician2Changed(String value) =>
      emit(state.copyWith(technician2: value));

  void technician3Changed(String value) =>
      emit(state.copyWith(technician3: value));

  void toggleTechnician3(bool show) =>
      emit(state.copyWith(showTechnician3: show));

  void finalTempInChanged(String value) =>
      emit(state.copyWith(finalTempIn: value));

  void finalTempInImageChanged(CapturedImageDetail? image) {
    if (image == null) {
      emit(state.copyWith(clearFinalTempInImage: true));
    } else {
      emit(state.copyWith(finalTempInImage: image));
    }
  }

  // Panggil ini dari listener di ServiceCallDetailScreen saat status unit berubah
  void updateAllUnitsValidated(bool allUnitsAreValid) {
    if (state.allUnitsValidated != allUnitsAreValid) {
      emit(state.copyWith(allUnitsValidated: allUnitsAreValid));
      _validateForm(); // Validasi ulang saat status unit berubah
    }
  }

  // Semua perubahan field akan memicu validasi dan penyimpanan
  void onFieldChanged() {
    _validateForm();
    EasyDebounce.debounce(
      'sc-save-hive-debouncer',
      const Duration(milliseconds: 500),
      _saveStateToHive,
    );
  }

  void finalTempSkippedChanged(bool isSkipped) {
    if (isSkipped) {
      emit(state.copyWith(
        isFinalTempSkipped: true,
        finalTempIn: '',
        clearFinalTempInImage: true,
        finalTempNote: null,
      ));
    } else {
      emit(state.copyWith(isFinalTempSkipped: false));
    }
    onFieldChanged();
  }

  void finalTempNoteChanged(String? note) =>
      emit(state.copyWith(finalTempNote: note));

  void _validateForm() {
    final picStoreValid = state.picName.isNotEmpty &&
        state.picNik.isNotEmpty &&
        state.picPosition.isNotEmpty &&
        state.picPhone.isNotEmpty;

    final technicianValid = state.technician1.isNotEmpty;

    final bool isSkipped = state.isFinalTempSkipped;
    final bool isFilled =
        state.finalTempIn.isNotEmpty && state.finalTempInImage != null;
    final bool noteFilled =
        state.finalTempNote != null && state.finalTempNote!.isNotEmpty;

    final finalTempValid =
        (isFilled && !isSkipped) || (isSkipped && noteFilled);

    final isReady = picStoreValid &&
        technicianValid &&
        state.allUnitsValidated &&
        finalTempValid;

    emit(state.copyWith(
      isPicStoreValid: picStoreValid,
      isFinalTempValid: finalTempValid,
      isFormReadyToSubmit: isReady,
    ));
  }

  Future<void> _saveStateToHive() async {
    if (!_transactionInfoBox.isOpen) {
      _transactionInfoBox =
          await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
    }

    final String normalizedKey = _normalizeHiveKey(transNo);
    final infoToSave = _transactionInfoBox.get(normalizedKey);

    if (infoToSave == null) {
      // print("PERINGATAN: Draft SC $normalizedKey hilang, membuat ulang.");
      _loadInitialData(); // Panggil ini untuk membuat ulang draft
      return;
    }

    infoToSave.picName = state.picName;
    infoToSave.picNik = state.picNik;
    infoToSave.picPosition = state.picPosition;
    infoToSave.picPhone = state.picPhone;
    infoToSave.technician1 = state.technician1;
    infoToSave.technician2 = state.technician2;
    infoToSave.technician3 = state.technician3;
    infoToSave.picImageDetail = state.picImageDetail;
    infoToSave.finalTemperatureIn = state.finalTempIn;
    infoToSave.finalTemperatureInImage = state.finalTempInImage;
    infoToSave.isFinalTempSkipped = state.isFinalTempSkipped;
    infoToSave.finalTempNote = state.finalTempNote;

    await infoToSave.save();
  }

  void updateValidationProgress(
    List<ServiceCallUnitDetail> allUnits,
    List<ServiceCallValidationEntryModel> entries,
  ) {
    // 1. Ambil state saat ini
    final currentState = state;

    int completedCount = 0;
    for (final unit in allUnits) {
      final serialKey = unit.serialNo.trim().toUpperCase();

      // Cari entry yang sesuai
      final entry = entries.firstWhereOrNull(
          (e) => e.serialNo.trim().toUpperCase() == serialKey);

      // Jika entry ada dan 'isCompleted' adalah true
      if (entry != null && entry.isCompleted) {
        completedCount++;
      }
    }
    final bool allValidated = completedCount == allUnits.length;
    double? maxIndoorTemp;

    for (final entry in entries) {
      // Kita hanya peduli suhu 'Sesudah' (After) untuk jadi batas minimal
      for (final measurement in entry.measurementsAfter) {
        final id = measurement.measurementId.toLowerCase();

        // Berdasarkan kode Anda sebelumnya, 'temperature' adalah ID untuk suhu indoor
        bool isSkip = measurement.isSkipped ?? false;
        if (id.contains('temperature') && !isSkip && measurement.value > 0.0) {
          if (maxIndoorTemp == null || measurement.value > maxIndoorTemp) {
            maxIndoorTemp = measurement.value; // Temukan nilai tertinggi
          }
        }
      }
    }

    if (maxIndoorTemp != null) {
      // print("❄️ Max Indoor Temp ditemukan: $maxIndoorTemp");
    }

    // 3. Panggil copyWith pada 'currentState' (yang sudah pasti ScFormLoaded)
    emit(currentState.copyWith(
      allUnitsValidated: allValidated,
      minFinalTempInLimit: maxIndoorTemp, // Kirim suhu max (atau null) ke state
    ));
  }
}
