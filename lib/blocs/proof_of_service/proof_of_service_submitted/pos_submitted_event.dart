import 'package:equatable/equatable.dart';

import '../../upload_progress/upload_progress_cubit.dart';


abstract class PosSubmittedEvent extends Equatable {
  const PosSubmittedEvent();
  @override
  List<Object?> get props => [];
}

class SubmitPosValidation extends PosSubmittedEvent {
  final String transNo;
  final String createdBy;
  final String createdByName;
  final String createdByIP;
  final UploadProgressCubit progressCubit;

  const SubmitPosValidation({
    required this.transNo,
    required this.createdBy,
    required this.createdByName,
    required this.createdByIP,
    required this.progressCubit,
  });
}

class RetryPosUpload extends PosSubmittedEvent {
  final String transNo;
  final List<String> failedFiles;
  final List<dynamic> presignedDetail;
  final UploadProgressCubit progressCubit;

  const RetryPosUpload({
    required this.transNo,
    required this.failedFiles,
    required this.presignedDetail,
    required this.progressCubit,
  });
}

class LoadPosValidationPartial extends PosSubmittedEvent {
  final String transNo;
  const LoadPosValidationPartial(this.transNo);
}

class FinalValidationRequested extends PosSubmittedEvent {
  final String transNo;
  final String customerCode;

  const FinalValidationRequested({required this.transNo, required this.customerCode});

  @override
  List<Object?> get props => [transNo, customerCode];
}