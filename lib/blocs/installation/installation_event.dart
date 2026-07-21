import 'package:equatable/equatable.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';

abstract class InstallationEvent extends Equatable {
  const InstallationEvent();

  @override
  List<Object?> get props => [];
}

// --- INITIALIZATION ---
class LoadInstallationData extends InstallationEvent {
  final String transNo;

  const LoadInstallationData(this.transNo);

  @override
  List<Object?> get props => [transNo];
}

// --- HEADER INFO ---
class UpdateTeamInfo extends InstallationEvent {
  final String? technician2;
  final String? technician3;
  final DateTime? startDate;

  const UpdateTeamInfo({this.technician2, this.technician3, this.startDate});

  @override
  List<Object?> get props => [technician2, technician3, startDate];
}

class UpdateTransportStatus extends InstallationEvent {
  final bool hasTransport;

  const UpdateTransportStatus(this.hasTransport);

  @override
  List<Object?> get props => [hasTransport];
}

// --- PIC TOKO (mirror RRO Cut Off) ---
class UpdatePicInfo extends InstallationEvent {
  final String? picName;
  final String? picPhone;
  final String? picNik;
  final String? picPosition;
  final bool? isPicActive;

  const UpdatePicInfo({
    this.picName,
    this.picPhone,
    this.picNik,
    this.picPosition,
    this.isPicActive,
  });

  @override
  List<Object?> get props =>
      [picName, picPhone, picNik, picPosition, isPicActive];
}

// Simpan foto PIC hasil validasi lokasi (di OtpDialog) sebelum submit
class UpdatePicPhoto extends InstallationEvent {
  final InstallationPhotoModel? photo;

  const UpdatePicPhoto(this.photo);

  @override
  List<Object?> get props => [photo];
}

// --- FASE 1: INDOOR ---
class SaveIndoorUnit extends InstallationEvent {
  final InstallationUnitModel unit;

  const SaveIndoorUnit(this.unit);

  @override
  List<Object?> get props => [unit];
}

// --- FASE 2: OUTDOOR (+ PAIRING) ---
class SaveOutdoorUnit extends InstallationEvent {
  final InstallationUnitModel unit;
  final String pairedIndoorSerial;

  const SaveOutdoorUnit({required this.unit, required this.pairedIndoorSerial});

  @override
  List<Object?> get props => [unit, pairedIndoorSerial];
}

// --- FASE 3: MATERIAL & EVIDENCE ---
class SaveMaterialSet extends InstallationEvent {
  final int unitIndex;
  final InstallationMaterialsModel materials;
  final bool isFinal;

  const SaveMaterialSet({
    required this.unitIndex,
    required this.materials,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [unitIndex, materials, isFinal];
}

// [UPDATED] Menggunakan Key & Path agar sesuai logic mapping di Repository
class SaveMaterialEvidence extends InstallationEvent {
  final String key;
  final String path;
  final String title;

  const SaveMaterialEvidence({
    required this.key,
    required this.path,
    required this.title,
  });

  @override
  List<Object?> get props => [key, path, title];
}

// --- FINALIZATION ---
class UpdateFinalPhotos extends InstallationEvent {
  final List<InstallationPhotoModel> photos;
  final String? note;

  const UpdateFinalPhotos({required this.photos, this.note});

  @override
  List<Object?> get props => [photos, note];
}

class ValidateDraftOnServer extends InstallationEvent {
  const ValidateDraftOnServer();
}

class ValidateSerialNumbers extends InstallationEvent {
  const ValidateSerialNumbers();
}

// [NEW] Event untuk Hapus Draft (Dipanggil saat Sukses/Partial)
class DeleteInstallationDraft extends InstallationEvent {
  final String transNo;

  const DeleteInstallationDraft(this.transNo);

  @override
  List<Object?> get props => [transNo];
}

// --- SUBMIT FINAL (Dengan Progress) ---
class SubmitInstallationFinal extends InstallationEvent {
  final String transNo;
  final String remark;
  final UploadProgressCubit progressCubit; // Wajib inject dari UI

  const SubmitInstallationFinal({
    required this.transNo,
    required this.remark,
    required this.progressCubit,
  });

  @override
  List<Object?> get props => [transNo, remark, progressCubit];
}

class SaveStoreFrontPhoto extends InstallationEvent {
  final InstallationPhotoModel? photo;

  const SaveStoreFrontPhoto(this.photo);

  @override
  List<Object?> get props => [photo];
}

class UpdateTransportData extends InstallationEvent {
  final bool hasTransport;
  final double? distance;
  final InstallationPhotoModel? photo;

  const UpdateTransportData({
    required this.hasTransport,
    this.distance,
    this.photo,
  });
}

class UpdateTidyingData extends InstallationEvent {
  final bool hasTidyingService;
  final int tidyingQty;

  const UpdateTidyingData({
    required this.hasTidyingService,
    required this.tidyingQty,
  });

  @override
  List<Object?> get props => [hasTidyingService, tidyingQty];
}

