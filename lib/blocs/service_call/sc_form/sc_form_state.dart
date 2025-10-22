import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

// Mirip PosFormState, tapi tanpa suhu awal POS
class ScFormState extends Equatable {
  // Data Fields (PIC, Teknisi)
  final String picNik;
  final String picName;
  final String picPosition;
  final String picPhone;
  final String technician2;
  final String technician3;
  final bool showTechnician3;
  final CapturedImageDetail? picImageDetail;

  // Data Suhu Akhir
  final String finalTempIn;
  final CapturedImageDetail? finalTempInImage;
  final double? minFinalTempInLimit;

  // Validation & Status Fields
  final bool isPicStoreValid;
  final bool allUnitsValidated; // Status validasi semua unit SC
  final bool isFinalTempValid; // Status validasi suhu akhir
  final bool isFormReadyToSubmit;

  const ScFormState({
    this.picNik = '',
    this.picName = '',
    this.picPosition = '',
    this.picPhone = '',
    this.technician2 = '',
    this.technician3 = '',
    this.showTechnician3 = false,
    this.picImageDetail,
    this.finalTempIn = '',
    this.finalTempInImage,
    this.minFinalTempInLimit,
    this.isPicStoreValid = false,
    this.allUnitsValidated = false,
    this.isFinalTempValid = false,
    this.isFormReadyToSubmit = false,
  });

  ScFormState copyWith({
    String? picNik, String? picName, String? picPosition, String? picPhone,
    String? technician2, String? technician3, bool? showTechnician3,
    CapturedImageDetail? picImageDetail,
    double? minFinalTempInLimit,
    String? finalTempIn, CapturedImageDetail? finalTempInImage,
    bool? isPicStoreValid, bool? allUnitsValidated, bool? isFinalTempValid,
    bool? isFormReadyToSubmit,
  }) {
    return ScFormState(
      picNik: picNik ?? this.picNik,
      picName: picName ?? this.picName,
      picPosition: picPosition ?? this.picPosition,
      picPhone: picPhone ?? this.picPhone,
      technician2: technician2 ?? this.technician2,
      technician3: technician3 ?? this.technician3,
      showTechnician3: showTechnician3 ?? this.showTechnician3,
      picImageDetail: picImageDetail ?? this.picImageDetail,
      finalTempIn: finalTempIn ?? this.finalTempIn,
      finalTempInImage: finalTempInImage ?? this.finalTempInImage,
      minFinalTempInLimit: minFinalTempInLimit ?? this.minFinalTempInLimit,
      isPicStoreValid: isPicStoreValid ?? this.isPicStoreValid,
      allUnitsValidated: allUnitsValidated ?? this.allUnitsValidated,
      isFinalTempValid: isFinalTempValid ?? this.isFinalTempValid,
      isFormReadyToSubmit: isFormReadyToSubmit ?? this.isFormReadyToSubmit,
    );
  }

  @override
  List<Object?> get props => [
    picNik, picName, picPosition, picPhone, technician2, technician3,
    showTechnician3, picImageDetail, finalTempIn, finalTempInImage,
    isPicStoreValid, allUnitsValidated, isFinalTempValid, isFormReadyToSubmit,
  ];
}