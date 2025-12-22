part of 'failed_uploads_bloc.dart';

abstract class FailedUploadsEvent extends Equatable {
  const FailedUploadsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFailedUploads extends FailedUploadsEvent {}

class RetryTransaction extends FailedUploadsEvent {
  final String transNo;
  final bool isZombie; // True = Reset Server, False = Upload S3

  const RetryTransaction({
    required this.transNo,
    required this.isZombie,
  });

  @override
  List<Object?> get props => [transNo, isZombie];
}

class RetrySingleFailedUpload extends FailedUploadsEvent {
  final Map<String, dynamic> transactionData;
  const RetrySingleFailedUpload(this.transactionData);
}

class ClearSnackbarMessage extends FailedUploadsEvent {}
class ClearSuccessMessage extends FailedUploadsEvent {}

class SyncWithApiPending extends FailedUploadsEvent {
  final List<TransactionSuggestion> apiPendingList;

  const SyncWithApiPending(this.apiPendingList);

  @override
  List<Object?> get props => [apiPendingList];
}