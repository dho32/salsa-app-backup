// lib/blocs/proof_of_service/pos_form/pos_form_state.dart

import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

// Enum untuk status
enum FormSubmissionStatus { initial, inProgress, success, failure }

class PosFormState extends Equatable {
  // --- Data Fields ---
  final String picNik;
  final String picPosition;
  final String tempIn;
  final String tempOut;
  final String serviceTime;
  final String picName;
  final String picPhone;
  final String technician1;
  final String technician2;
  final String technician3;
  final String technician1Nik;
  final String technician2Nik;
  final String technician3Nik;
  final bool showTechnician3;
  final String finalTempIn;
  final double? minFinalTempInLimit;

  // --- Image Fields ---
  final CapturedImageDetail? picImageDetail;
  final CapturedImageDetail? temperatureInImage;
  final CapturedImageDetail? temperatureOutImage;
  final CapturedImageDetail? finalTempInImage;

  // --- Validation & Status Fields ---
  final bool isPicStoreValid;
  final bool isServiceInfoValid;
  final bool allUnitsValidated;
  final bool isFormReadyToSubmit;
  final FormSubmissionStatus submissionStatus;

  // --- Note Pengukuran Suhu Ruang ---
  final String tempInNote;
  final String tempOutNote;
  final String finalTempInNote;
  final bool isTempInSkipped;
  final bool isTempOutSkipped;
  final bool isFinalTempInSkipped;

  // --- Bukti kendala saat skip (alasan ber-flag require_remark) ---
  final String tempInSkipRemark;
  final String tempOutSkipRemark;
  final String finalTempInSkipRemark;
  final List<CapturedImageDetail> tempInSkipPhotos;
  final List<CapturedImageDetail> tempOutSkipPhotos;
  final List<CapturedImageDetail> finalTempInSkipPhotos;

  const PosFormState({
    this.picNik = '',
    this.picPosition = '',
    this.tempIn = '',
    this.tempOut = '',
    this.finalTempIn = '',
    this.finalTempInImage,
    this.minFinalTempInLimit,
    this.serviceTime = '',
    this.picName = '',
    this.picPhone = '',
    this.technician1 = '',
    this.technician2 = '',
    this.technician3 = '',
    this.technician1Nik = '',
    this.technician2Nik = '',
    this.technician3Nik = '',
    this.showTechnician3 = false,
    this.picImageDetail,
    this.temperatureInImage,
    this.temperatureOutImage,
    this.isPicStoreValid = false,
    this.isServiceInfoValid = false,
    this.allUnitsValidated = false,
    this.isFormReadyToSubmit = false,
    this.submissionStatus = FormSubmissionStatus.initial,
    this.tempInNote = '',
    this.tempOutNote = '',
    this.finalTempInNote = '',
    this.isTempInSkipped = false,
    this.isTempOutSkipped = false,
    this.isFinalTempInSkipped = false,
    this.tempInSkipRemark = '',
    this.tempOutSkipRemark = '',
    this.finalTempInSkipRemark = '',
    this.tempInSkipPhotos = const [],
    this.tempOutSkipPhotos = const [],
    this.finalTempInSkipPhotos = const [],
  });

  PosFormState copyWith({
    String? picNik,
    String? picPosition,
    String? tempIn,
    String? tempOut,
    String? finalTempIn,
    CapturedImageDetail? finalTempInImage,
    bool clearFinalTempInImage = false,
    double? minFinalTempInLimit,
    String? serviceTime,
    String? picName,
    String? picPhone,
    String? technician1,
    String? technician2,
    String? technician3,
    String? technician1Nik,
    String? technician2Nik,
    String? technician3Nik,
    bool? showTechnician3,
    CapturedImageDetail? picImageDetail,
    CapturedImageDetail? temperatureInImage,
    bool clearTemperatureInImage = false,
    CapturedImageDetail? temperatureOutImage,
    bool clearTemperatureOutImage = false,
    bool? isPicStoreValid,
    bool? isServiceInfoValid,
    bool? allUnitsValidated,
    bool? isFormReadyToSubmit,
    FormSubmissionStatus? submissionStatus,
    String? tempInNote,
    String? tempOutNote,
    String? finalTempInNote,
    bool? isTempInSkipped,
    bool? isTempOutSkipped,
    bool? isFinalTempInSkipped,
    String? tempInSkipRemark,
    String? tempOutSkipRemark,
    String? finalTempInSkipRemark,
    List<CapturedImageDetail>? tempInSkipPhotos,
    List<CapturedImageDetail>? tempOutSkipPhotos,
    List<CapturedImageDetail>? finalTempInSkipPhotos,
  }) {
    return PosFormState(
      picNik: picNik ?? this.picNik,
      picPosition: picPosition ?? this.picPosition,
      tempIn: tempIn ?? this.tempIn,
      tempOut: tempOut ?? this.tempOut,
      finalTempIn: finalTempIn ?? this.finalTempIn,
      finalTempInImage: clearFinalTempInImage ? null : (finalTempInImage ?? this.finalTempInImage),
      minFinalTempInLimit: minFinalTempInLimit ?? this.minFinalTempInLimit,
      serviceTime: serviceTime ?? this.serviceTime,
      picName: picName ?? this.picName,
      picPhone: picPhone ?? this.picPhone,
      technician1: technician1 ?? this.technician1,
      technician2: technician2 ?? this.technician2,
      technician3: technician3 ?? this.technician3,
      technician1Nik: technician1Nik ?? this.technician1Nik,
      technician2Nik: technician2Nik ?? this.technician2Nik,
      technician3Nik: technician3Nik ?? this.technician3Nik,
      showTechnician3: showTechnician3 ?? this.showTechnician3,
      picImageDetail: picImageDetail ?? this.picImageDetail,
      temperatureInImage: clearTemperatureInImage ? null : (temperatureInImage ?? this.temperatureInImage),
      temperatureOutImage: clearTemperatureOutImage ? null : (temperatureOutImage ?? this.temperatureOutImage),
      isPicStoreValid: isPicStoreValid ?? this.isPicStoreValid,
      isServiceInfoValid: isServiceInfoValid ?? this.isServiceInfoValid,
      allUnitsValidated: allUnitsValidated ?? this.allUnitsValidated,
      isFormReadyToSubmit: isFormReadyToSubmit ?? this.isFormReadyToSubmit,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      tempInNote: tempInNote ?? this.tempInNote,
      tempOutNote: tempOutNote ?? this.tempOutNote,
      finalTempInNote: finalTempInNote ?? this.finalTempInNote,
      isTempInSkipped: isTempInSkipped ?? this.isTempInSkipped,
      isTempOutSkipped: isTempOutSkipped ?? this.isTempOutSkipped,
      isFinalTempInSkipped: isFinalTempInSkipped ?? this.isFinalTempInSkipped,
      tempInSkipRemark: tempInSkipRemark ?? this.tempInSkipRemark,
      tempOutSkipRemark: tempOutSkipRemark ?? this.tempOutSkipRemark,
      finalTempInSkipRemark:
          finalTempInSkipRemark ?? this.finalTempInSkipRemark,
      tempInSkipPhotos: tempInSkipPhotos ?? this.tempInSkipPhotos,
      tempOutSkipPhotos: tempOutSkipPhotos ?? this.tempOutSkipPhotos,
      finalTempInSkipPhotos:
          finalTempInSkipPhotos ?? this.finalTempInSkipPhotos,
    );
  }

  @override
  List<Object?> get props => [
        picNik,
        picPosition,
        tempIn,
        tempOut,
        finalTempIn,
        finalTempInImage,
        minFinalTempInLimit,
        serviceTime,
        picName,
        picPhone,
        technician1,
        technician2,
        technician3,
        technician1Nik,
        technician2Nik,
        technician3Nik,
        showTechnician3,
        picImageDetail,
        temperatureInImage,
        temperatureOutImage,
        isPicStoreValid,
        isServiceInfoValid,
        allUnitsValidated,
        isFormReadyToSubmit,
        submissionStatus,
        tempInNote,
        tempOutNote,
        finalTempInNote,
        isTempInSkipped,
        isTempOutSkipped,
        isFinalTempInSkipped,
        tempInSkipRemark,
        tempOutSkipRemark,
        finalTempInSkipRemark,
        tempInSkipPhotos,
        tempOutSkipPhotos,
        finalTempInSkipPhotos,
      ];
}
