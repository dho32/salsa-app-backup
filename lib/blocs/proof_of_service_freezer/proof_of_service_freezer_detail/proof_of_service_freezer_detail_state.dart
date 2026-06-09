part of 'proof_of_service_freezer_detail_bloc.dart';

/// Status validasi per-freezer (dipakai untuk ikon di list & gating tombol Selesai).
enum FreezerValidationStatus { notStarted, inProgress, completed }

abstract class ProofOfServiceFreezerDetailState extends Equatable {
  const ProofOfServiceFreezerDetailState();

  @override
  List<Object?> get props => [];
}

class ProofOfServiceFreezerDetailInitial extends ProofOfServiceFreezerDetailState {}

class ProofOfServiceFreezerDetailLoading extends ProofOfServiceFreezerDetailState {}

class ProofOfServiceFreezerDetailError extends ProofOfServiceFreezerDetailState {
  final String message;

  const ProofOfServiceFreezerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProofOfServiceFreezerDetailLoaded extends ProofOfServiceFreezerDetailState {
  final ProofOfServiceFreezerDetailModel data;

  /// key = freezerEntryKey(...), value = status validasi unit tsb.
  final Map<String, FreezerValidationStatus> statuses;

  /// true bila semua freezer sudah berstatus completed.
  final bool allUnitsValidated;

  const ProofOfServiceFreezerDetailLoaded({
    required this.data,
    required this.statuses,
    required this.allUnitsValidated,
  });

  @override
  List<Object?> get props => [data, statuses, allUnitsValidated];
}
