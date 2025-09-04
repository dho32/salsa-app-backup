// lib/blocs/proof_of_service/pos_form/pos_form_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_state.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:easy_debounce/easy_debounce.dart'; // Tambahkan package ini: flutter pub add easy_debounce

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
      ));
    }
    _validateForm();
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

    final serviceInfoValid = state.tempIn.isNotEmpty &&
        state.tempOut.isNotEmpty &&
        state.temperatureInImage != null &&
        state.temperatureOutImage != null;

    final isReady = picStoreValid && serviceInfoValid && state.allUnitsValidated;

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
      ..temperatureOutImage = state.temperatureOutImage;

    await _transactionInfoBox.put(transNo, infoToSave);
    print('✅ Form state saved to Hive for $transNo');
  }
}
