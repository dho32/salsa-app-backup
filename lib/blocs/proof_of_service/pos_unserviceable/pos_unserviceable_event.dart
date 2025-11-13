import 'package:equatable/equatable.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

abstract class PosUnserviceableEvent extends Equatable {
  const PosUnserviceableEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnserviceableDraft extends PosUnserviceableEvent {}

class TakeProofPhoto extends PosUnserviceableEvent {}

class RemoveProofPhoto extends PosUnserviceableEvent {
  final CapturedImageDetail photoToRemove;
  const RemoveProofPhoto(this.photoToRemove);

  @override
  List<Object?> get props => [photoToRemove];
}

class ReasonSelected extends PosUnserviceableEvent {
  final String? reason;
  const ReasonSelected(this.reason);

  @override
  List<Object?> get props => [reason];
}

class NotesChanged extends PosUnserviceableEvent {
  final String notes;
  const NotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class TechnicianNameChanged extends PosUnserviceableEvent {
  final String name;
  const TechnicianNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class SubmitUnserviceableReport extends PosUnserviceableEvent {
  final UploadProgressCubit progressCubit;
  const SubmitUnserviceableReport(this.progressCubit);

  @override
  List<Object?> get props => [progressCubit];
}

class RetryUnserviceableUpload extends PosUnserviceableEvent {
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