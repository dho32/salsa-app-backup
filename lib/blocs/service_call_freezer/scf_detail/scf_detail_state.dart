part of 'scf_detail_bloc.dart';

/// Status validasi per-freezer (ikon di list & gating tombol Selesai).
enum ScfValidationStatus { notStarted, inProgress, completed }

abstract class ScfDetailState extends Equatable {
  const ScfDetailState();

  @override
  List<Object?> get props => [];
}

class ScfDetailInitial extends ScfDetailState {}

class ScfDetailLoading extends ScfDetailState {}

class ScfDetailError extends ScfDetailState {
  final String message;

  const ScfDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ScfDetailLoaded extends ScfDetailState {
  final ServiceCallFreezerDetailModel data;

  /// key = scfEntryKey(...), value = status validasi unit tsb.
  final Map<String, ScfValidationStatus> statuses;

  /// true bila semua freezer sudah berstatus completed.
  final bool allUnitsValidated;

  const ScfDetailLoaded({
    required this.data,
    required this.statuses,
    required this.allUnitsValidated,
  });

  @override
  List<Object?> get props => [data, statuses, allUnitsValidated];
}
