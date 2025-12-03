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
  });

  PosFormState copyWith({
    String? picNik,
    String? picPosition,
    String? tempIn,
    String? tempOut,
    String? finalTempIn,
    CapturedImageDetail? finalTempInImage,
    double? minFinalTempInLimit,
    String? serviceTime,
    String? picName,
    String? picPhone,
    String? technician1,
    String? technician2,
    String? technician3,
    bool? showTechnician3,
    CapturedImageDetail? picImageDetail,
    CapturedImageDetail? temperatureInImage,
    CapturedImageDetail? temperatureOutImage,
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
  }) {
    return PosFormState(
      picNik: picNik ?? this.picNik,
      picPosition: picPosition ?? this.picPosition,
      tempIn: tempIn ?? this.tempIn,
      tempOut: tempOut ?? this.tempOut,
      finalTempIn: finalTempIn ?? this.finalTempIn,
      finalTempInImage: finalTempInImage ?? this.finalTempInImage,
      minFinalTempInLimit: minFinalTempInLimit ?? this.minFinalTempInLimit,
      serviceTime: serviceTime ?? this.serviceTime,
      picName: picName ?? this.picName,
      picPhone: picPhone ?? this.picPhone,
      technician1: technician1 ?? this.technician1,
      technician2: technician2 ?? this.technician2,
      technician3: technician3 ?? this.technician3,
      showTechnician3: showTechnician3 ?? this.showTechnician3,
      picImageDetail: picImageDetail ?? this.picImageDetail,
      temperatureInImage: temperatureInImage ?? this.temperatureInImage,
      temperatureOutImage: temperatureOutImage ?? this.temperatureOutImage,
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
      ];
}
