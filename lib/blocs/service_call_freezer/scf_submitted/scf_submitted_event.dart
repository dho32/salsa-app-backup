part of 'scf_submitted_bloc.dart';

abstract class ScfSubmittedEvent extends Equatable {
  const ScfSubmittedEvent();

  @override
  List<Object?> get props => [];
}

/// Cek apakah butuh AHO (ada solusi ber-ahoFlag 'Y'); arahkan ke dialog AHO/OTP.
class ScfFinalValidationRequested extends ScfSubmittedEvent {
  final String transNo;
  final ScfFormState formState;
  final List<ProblemSourceModel> problemSources;

  const ScfFinalValidationRequested({
    required this.transNo,
    required this.formState,
    required this.problemSources,
  });

  @override
  List<Object?> get props => [transNo, formState, problemSources];
}

/// Nomor AHO diinput → lanjut ke OTP.
class ScfAhoInputCompleted extends ScfSubmittedEvent {
  final ScfFormState formState;
  final String ahoNumber;

  const ScfAhoInputCompleted({
    required this.formState,
    required this.ahoNumber,
  });

  @override
  List<Object?> get props => [formState, ahoNumber];
}

/// Submit seluruh data SCF (header info + entries) + upload foto ke S3.
class SubmitScfValidation extends ScfSubmittedEvent {
  final String transNo;
  final String createdBy;
  final String createdByName;
  final String createdByIP;
  final UploadProgressCubit progressCubit;
  final String storeName;
  final String? ahoNumber;

  /// Dari `ScfHeader.pathAttachment`; dipakai backend sebagai segmen S3 key.
  final String pathAttachment;

  const SubmitScfValidation({
    required this.transNo,
    required this.createdBy,
    required this.createdByName,
    required this.createdByIP,
    required this.progressCubit,
    this.storeName = '',
    this.ahoNumber,
    this.pathAttachment = '',
  });

  @override
  List<Object?> get props =>
      [transNo, createdBy, createdByName, createdByIP, ahoNumber];
}

class RetryScfUpload extends ScfSubmittedEvent {
  final String transNo;
  final List<String> failedFiles;
  final List<dynamic> presignedDetail;
  final UploadProgressCubit progressCubit;

  const RetryScfUpload({
    required this.transNo,
    required this.failedFiles,
    required this.presignedDetail,
    required this.progressCubit,
  });

  @override
  List<Object?> get props => [transNo, failedFiles, presignedDetail];
}

class LoadScfPartial extends ScfSubmittedEvent {
  final String transNo;

  const LoadScfPartial(this.transNo);

  @override
  List<Object?> get props => [transNo];
}
