// lib/blocs/proof_of_service/pos_form/pos_form_state.dart

import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

// Enum untuk status, agar lebih jelas
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
  final String technician2;
  final String technician3;
  final bool showTechnician3;

  // --- Image Fields ---
  final CapturedImageDetail? picImageDetail;
  final CapturedImageDetail? temperatureInImage;
  final CapturedImageDetail? temperatureOutImage;

  // --- Validation & Status Fields ---
  final bool isPicStoreValid;
  final bool isServiceInfoValid;
  final bool allUnitsValidated;
  final bool isFormReadyToSubmit;
  final FormSubmissionStatus submissionStatus;

  const PosFormState({
    this.picNik = '',
    this.picPosition = '',
    this.tempIn = '',
    this.tempOut = '',
    this.serviceTime = '',
    this.picName = '',
    this.picPhone = '',
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
  });

  // Method `copyWith` sangat penting untuk memperbarui state secara immutable
  PosFormState copyWith({
    String? picNik,
    String? picPosition,
    String? tempIn,
    String? tempOut,
    String? serviceTime,
    String? picName,
    String? picPhone,
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
  }) {
    return PosFormState(
      picNik: picNik ?? this.picNik,
      picPosition: picPosition ?? this.picPosition,
      tempIn: tempIn ?? this.tempIn,
      tempOut: tempOut ?? this.tempOut,
      serviceTime: serviceTime ?? this.serviceTime,
      picName: picName ?? this.picName,
      picPhone: picPhone ?? this.picPhone,
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
    );
  }

  @override
  List<Object?> get props => [
    picNik,
    picPosition,
    tempIn,
    tempOut,
    serviceTime,
    picName,
    picPhone,
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
  ];
}