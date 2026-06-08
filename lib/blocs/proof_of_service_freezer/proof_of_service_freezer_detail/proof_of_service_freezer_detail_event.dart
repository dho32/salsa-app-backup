part of 'proof_of_service_freezer_detail_bloc.dart';

abstract class ProofOfServiceFreezerDetailEvent extends Equatable {
  const ProofOfServiceFreezerDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Ambil detail tugas (header customer + tiket + list freezer) dari repository.
class FetchProofOfServiceFreezerDetail extends ProofOfServiceFreezerDetailEvent {
  final String transNo;

  const FetchProofOfServiceFreezerDetail(this.transNo);

  @override
  List<Object?> get props => [transNo];
}
