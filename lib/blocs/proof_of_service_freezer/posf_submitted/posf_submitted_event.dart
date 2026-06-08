part of 'posf_submitted_bloc.dart';

abstract class PosfSubmittedEvent extends Equatable {
  const PosfSubmittedEvent();

  @override
  List<Object?> get props => [];
}

/// Submit seluruh data Cuci Freezer (header info + entries) + upload foto ke S3.
class SubmitPosfValidation extends PosfSubmittedEvent {
  final String transNo;
  final String createdBy;
  final String createdByName;
  final String createdByIP;
  final UploadProgressCubit progressCubit;

  const SubmitPosfValidation({
    required this.transNo,
    required this.createdBy,
    required this.createdByName,
    required this.createdByIP,
    required this.progressCubit,
  });

  @override
  List<Object?> get props => [transNo, createdBy, createdByName, createdByIP];
}
