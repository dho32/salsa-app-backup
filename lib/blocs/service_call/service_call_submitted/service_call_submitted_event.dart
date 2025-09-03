import 'package:equatable/equatable.dart';

import '../../upload_progress/upload_progress_cubit.dart';

abstract class ServiceCallSubmittedEvent extends Equatable {
  const ServiceCallSubmittedEvent();

  @override
  List<Object?> get props => [];
}

class SubmitValidation extends ServiceCallSubmittedEvent {
  final String transNo;
  final String createdBy;
  final String createdByName;
  final String createdByIP;
  final String pathAttachment;
  final UploadProgressCubit progressCubit;

  const SubmitValidation({
    required this.transNo,
    required this.createdBy,
    required this.createdByName,
    required this.createdByIP,
    required this.pathAttachment,
    required this.progressCubit,
  });

  @override
  List<Object?> get props => [transNo, progressCubit];
}

class RetryUpload extends ServiceCallSubmittedEvent {
  final String transNo;
  final List<String> failedFiles; // format: "serialNo - filename"
  final List<dynamic> presignedDetail;
  final UploadProgressCubit progressCubit;

  const RetryUpload({
    required this.transNo,
    required this.failedFiles,
    required this.presignedDetail,
    required this.progressCubit,
  });

  @override
  List<Object?> get props =>
      [transNo, failedFiles, presignedDetail, progressCubit];
}

class LoadValidationPartial extends ServiceCallSubmittedEvent {
  final String transNo;

  const LoadValidationPartial(this.transNo);

  @override
  List<Object?> get props => [transNo];
}
