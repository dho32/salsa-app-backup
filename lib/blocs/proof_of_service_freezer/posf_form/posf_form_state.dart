import 'package:equatable/equatable.dart';

import '../../../models/common/captured_image_detail.dart';

/// State form level-transaksi Cuci Freezer (PIC toko + teknisi bertugas).
/// Pola PosFormState, tanpa field suhu (suhu dicatat per-unit di wizard).
class PosfFormState extends Equatable {
  final String picName;
  final String picNik;
  final String picPosition;
  final String picPhone;
  final String technician1;
  final String technician2;
  final String technician3;
  final String technician1Nik;
  final String technician2Nik;
  final String technician3Nik;
  final bool showTechnician3;
  final CapturedImageDetail? picImageDetail;

  // Validasi
  final bool isPicStoreValid;
  final bool allUnitsValidated;
  final bool isFormReadyToSubmit;

  const PosfFormState({
    this.picName = '',
    this.picNik = '',
    this.picPosition = '',
    this.picPhone = '',
    this.technician1 = '',
    this.technician2 = '',
    this.technician3 = '',
    this.technician1Nik = '',
    this.technician2Nik = '',
    this.technician3Nik = '',
    this.showTechnician3 = false,
    this.picImageDetail,
    this.isPicStoreValid = false,
    this.allUnitsValidated = false,
    this.isFormReadyToSubmit = false,
  });

  PosfFormState copyWith({
    String? picName,
    String? picNik,
    String? picPosition,
    String? picPhone,
    String? technician1,
    String? technician2,
    String? technician3,
    String? technician1Nik,
    String? technician2Nik,
    String? technician3Nik,
    bool? showTechnician3,
    CapturedImageDetail? picImageDetail,
    bool clearPicImageDetail = false,
    bool? isPicStoreValid,
    bool? allUnitsValidated,
    bool? isFormReadyToSubmit,
  }) {
    return PosfFormState(
      picName: picName ?? this.picName,
      picNik: picNik ?? this.picNik,
      picPosition: picPosition ?? this.picPosition,
      picPhone: picPhone ?? this.picPhone,
      technician1: technician1 ?? this.technician1,
      technician2: technician2 ?? this.technician2,
      technician3: technician3 ?? this.technician3,
      technician1Nik: technician1Nik ?? this.technician1Nik,
      technician2Nik: technician2Nik ?? this.technician2Nik,
      technician3Nik: technician3Nik ?? this.technician3Nik,
      showTechnician3: showTechnician3 ?? this.showTechnician3,
      picImageDetail:
          clearPicImageDetail ? null : (picImageDetail ?? this.picImageDetail),
      isPicStoreValid: isPicStoreValid ?? this.isPicStoreValid,
      allUnitsValidated: allUnitsValidated ?? this.allUnitsValidated,
      isFormReadyToSubmit: isFormReadyToSubmit ?? this.isFormReadyToSubmit,
    );
  }

  @override
  List<Object?> get props => [
        picName,
        picNik,
        picPosition,
        picPhone,
        technician1,
        technician2,
        technician3,
        technician1Nik,
        technician2Nik,
        technician3Nik,
        showTechnician3,
        picImageDetail,
        isPicStoreValid,
        allUnitsValidated,
        isFormReadyToSubmit,
      ];
}
