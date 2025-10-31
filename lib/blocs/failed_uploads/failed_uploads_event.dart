part of 'failed_uploads_bloc.dart';

abstract class FailedUploadsEvent extends Equatable {
  const FailedUploadsEvent();
  @override
  List<Object?> get props => [];
}

class LoadFailedUploads extends FailedUploadsEvent {}

class RetrySingleFailedUpload extends FailedUploadsEvent {
  final Map<String, dynamic> transactionData;

  const RetrySingleFailedUpload(this.transactionData);

  @override
  List<Object?> get props => [transactionData];
}

class ClearSnackbarMessage extends FailedUploadsEvent {}

class ClearSuccessMessage extends FailedUploadsEvent {}
