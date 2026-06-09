part of 'posf_submitted_bloc.dart';

abstract class PosfSubmittedState extends Equatable {
  const PosfSubmittedState();

  @override
  List<Object?> get props => [];
}

class PosfSubmittedInitial extends PosfSubmittedState {}

class PosfSubmitting extends PosfSubmittedState {}

class PosfUploadInProgress extends PosfSubmittedState {}

class PosfSubmitSuccess extends PosfSubmittedState {}

class PosfSubmitFailure extends PosfSubmittedState {
  final String error;

  const PosfSubmitFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class PosfUploadPartial extends PosfSubmittedState {
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;
  final String transNo;

  const PosfUploadPartial({
    required this.successCount,
    required this.failureCount,
    required this.failedFiles,
    required this.transNo,
  });

  @override
  List<Object?> get props => [successCount, failureCount, failedFiles, transNo];
}
