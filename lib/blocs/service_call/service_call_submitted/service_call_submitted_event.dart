import 'package:equatable/equatable.dart';

import '../../../models/service_call/problem_source_model.dart';
import '../../upload_progress/upload_progress_cubit.dart';
import '../sc_form/sc_form_state.dart';

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
  final ScFormState formState;
  final String storeName;
  final String? ahoNumber;

  const SubmitValidation({
    required this.transNo,
    required this.createdBy,
    required this.createdByName,
    required this.createdByIP,
    required this.pathAttachment,
    required this.progressCubit,
    required this.formState,
    required this.storeName,
    this.ahoNumber,
  });

  @override
  List<Object?> get props => [transNo, progressCubit, ahoNumber];
}

class ScFinalValidationRequested extends ServiceCallSubmittedEvent {
  final String transNo;
  final ScFormState formState;
  final List<ProblemSourceModel> problemSources;

  const ScFinalValidationRequested({
    required this.transNo,
    required this.formState,
    required this.problemSources,
  });

  @override
  List<Object?> get props => [transNo, formState, problemSources];
}

class AhoInputCompleted extends ServiceCallSubmittedEvent {
  final ScFormState formState;
  final String ahoNumber;

  const AhoInputCompleted({
    required this.formState,
    required this.ahoNumber,
  });

  @override
  List<Object?> get props => [formState, ahoNumber];
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
