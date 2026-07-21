import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';
import '../../auth/auth_storage.dart';
import 'posf_form_state.dart';

/// Cubit form level-transaksi Cuci Freezer (PIC + teknisi). Pola PosFormCubit
/// tanpa field suhu. Reuse dropdown teknisi WH (technicianList dari app config).
class PosfFormCubit extends Cubit<PosfFormState> {
  final String transNo;
  final Box<ProofOfServiceFreezerInfoModel> _infoBox;

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
    for (final t in _technicianList) {
      if (t['technician_name'] == name) return t['technician_id'] ?? '';
    }
    return '';
  }

  String _getHiveKey(String transNo) =>
      transNo.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  PosfFormCubit({required this.transNo})
      : _infoBox = Hive.box<ProofOfServiceFreezerInfoModel>(kProofOfServiceFreezerInfoBox),
        super(const PosfFormState()) {
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
      _technicianList = rawList.whereType<Map>().map((t) {
        return {
          'technician_id': (t['technician_id'] ?? '').toString(),
          'technician_name': (t['technician_name'] ?? '').toString(),
        };
      }).toList();
    }

    _loadInitialData();
  }

  void _loadInitialData() {
    final key = _getHiveKey(transNo);
    final info = _infoBox.get(key);
    if (info != null) {
      emit(state.copyWith(
        picName: info.picName ?? '',
        picNik: info.picNik ?? '',
        picPosition: info.picPosition ?? '',
        picPhone: info.picPhone ?? '',
        technician1: info.technician1 ?? '',
        technician2: info.technician2 ?? '',
        technician3: info.technician3 ?? '',
        technician1Nik: (info.technician1 ?? '').isEmpty ? '' : _userId,
        technician2Nik: (info.technician2Nik?.isNotEmpty ?? false)
            ? info.technician2Nik!
            : _nikForName(info.technician2 ?? ''),
        technician3Nik: (info.technician3Nik?.isNotEmpty ?? false)
            ? info.technician3Nik!
            : _nikForName(info.technician3 ?? ''),
        showTechnician3: (info.technician3 ?? '').isNotEmpty,
        picImageDetail: info.picImageDetail,
      ));
    } else {
      final initialTech1 = _userType == 'WH' ? _userName : '';
      final initialTech1Nik = initialTech1.isEmpty ? '' : _userId;
      _infoBox.put(
        key,
        ProofOfServiceFreezerInfoModel(
          transNo: transNo,
          technician1: initialTech1,
          technician1Nik: initialTech1Nik,
        ),
      );
      emit(state.copyWith(
        technician1: initialTech1,
        technician1Nik: initialTech1Nik,
      ));
    }
    _validateForm();
  }

  // --- UI events ---
  void picNameChanged(String v) => emit(state.copyWith(picName: v));
  void picNikChanged(String v) => emit(state.copyWith(picNik: v));
  void picPositionChanged(String v) => emit(state.copyWith(picPosition: v));
  void picPhoneChanged(String v) => emit(state.copyWith(picPhone: v));
  void technician1Changed(String v) => emit(state.copyWith(
        technician1: v,
        technician1Nik: v.isEmpty ? '' : _userId,
      ));
  void technician2Changed(String v) => emit(state.copyWith(
        technician2: v,
        technician2Nik: _nikForName(v),
      ));
  void technician3Changed(String v) => emit(state.copyWith(
        technician3: v,
        technician3Nik: _nikForName(v),
      ));
  void toggleTechnician3(bool show) => emit(state.copyWith(showTechnician3: show));

  void picImageChanged(CapturedImageDetail? image) {
    if (image == null) {
      emit(state.copyWith(clearPicImageDetail: true));
    } else {
      emit(state.copyWith(picImageDetail: image));
    }
  }

  /// Dipanggil dari detail screen saat status validasi seluruh freezer berubah.
  void updateAllUnitsValidated(bool allValid) {
    if (state.allUnitsValidated != allValid) {
      emit(state.copyWith(allUnitsValidated: allValid));
      _validateForm();
    }
  }

  void onFieldChanged() {
    _validateForm();
    EasyDebounce.debounce(
      'posf-save-hive-debouncer',
      const Duration(milliseconds: 500),
      _saveStateToHive,
    );
  }

  void _validateForm() {
    final picStoreValid = state.picName.isNotEmpty &&
        state.picNik.isNotEmpty &&
        state.picPosition.isNotEmpty &&
        state.picPhone.isNotEmpty;
    final technicianValid = state.technician1.isNotEmpty;
    final isReady =
        picStoreValid && technicianValid && state.allUnitsValidated;

    emit(state.copyWith(
      isPicStoreValid: picStoreValid,
      isFormReadyToSubmit: isReady,
    ));
  }

  Future<void> _saveStateToHive() async {
    final key = _getHiveKey(transNo);
    final info = _infoBox.get(key) ?? ProofOfServiceFreezerInfoModel(transNo: transNo);
    info.picName = state.picName;
    info.picNik = state.picNik;
    info.picPosition = state.picPosition;
    info.picPhone = state.picPhone;
    info.technician1 = state.technician1;
    info.technician2 = state.technician2;
    info.technician3 = state.technician3;
    info.technician1Nik = state.technician1Nik;
    info.technician2Nik = state.technician2Nik;
    info.technician3Nik = state.technician3Nik;
    info.picImageDetail = state.picImageDetail;
    await _infoBox.put(key, info);
  }
}
