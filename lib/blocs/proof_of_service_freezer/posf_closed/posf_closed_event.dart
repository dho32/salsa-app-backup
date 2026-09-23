part of 'posf_closed_bloc.dart';

abstract class PosfClosedEvent extends Equatable {
  const PosfClosedEvent();

  @override
  List<Object?> get props => [];
}

class TakeClosedProofPhoto extends PosfClosedEvent {}

class RemoveClosedProofPhoto extends PosfClosedEvent {
  final CapturedImageDetail photo;
  const RemoveClosedProofPhoto(this.photo);

  @override
  List<Object?> get props => [photo];
}

class ClosedReasonSelected extends PosfClosedEvent {
  final String? reason;
  const ClosedReasonSelected(this.reason);

  @override
  List<Object?> get props => [reason];
}

class ClosedNotesChanged extends PosfClosedEvent {
  final String notes;
  const ClosedNotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class SubmitClosedReport extends PosfClosedEvent {
  final UploadProgressCubit progressCubit;
  const SubmitClosedReport(this.progressCubit);

  @override
  List<Object?> get props => [progressCubit];
}
