import 'package:equatable/equatable.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

abstract class SCUnserviceableEvent extends Equatable {
  const SCUnserviceableEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnserviceableDraft extends SCUnserviceableEvent {}

class TakeProofPhoto extends SCUnserviceableEvent {}

class RemoveProofPhoto extends SCUnserviceableEvent {
  final CapturedImageDetail photoToRemove;
  const RemoveProofPhoto(this.photoToRemove);

  @override
  List<Object?> get props => [photoToRemove];
}

class ReasonSelected extends SCUnserviceableEvent {
  final String? reason;
  const ReasonSelected(this.reason);

  @override
  List<Object?> get props => [reason];
}

class NotesChanged extends SCUnserviceableEvent {
  final String notes;
  const NotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class SubmitUnserviceableReport extends SCUnserviceableEvent {
  final UploadProgressCubit progressCubit;
  final String pathAttachment;
  const SubmitUnserviceableReport(this.progressCubit, this.pathAttachment);

  @override
  List<Object?> get props => [progressCubit, pathAttachment];
}

class RetryUnserviceableUpload extends SCUnserviceableEvent {
  final List<dynamic> presignedDetail;
  final List<String> failedFiles;
  final UploadProgressCubit progressCubit;

  const RetryUnserviceableUpload({
    required this.presignedDetail,
    required this.failedFiles,
    required this.progressCubit,
  });

  @override
  List<Object?> get props => [presignedDetail, failedFiles, progressCubit];
}