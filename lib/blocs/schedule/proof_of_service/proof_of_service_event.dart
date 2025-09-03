// lib/blocs/proof_of_service/proof_of_service_detail_event.dart

part of 'proof_of_service_bloc.dart';

abstract class ProofOfServiceEvent extends Equatable {
  const ProofOfServiceEvent();
  @override
  List<Object> get props => [];
}

// Event untuk memuat data form awal
class FetchPOSDetail extends ProofOfServiceEvent {
  final String transNo;
  const FetchPOSDetail(this.transNo);
  @override
  List<Object> get props => [transNo];
}

class UpdateMeasurements extends ProofOfServiceEvent {
  final POSMeasurementData newMeasurements;

  const UpdateMeasurements(this.newMeasurements);

  @override
  List<Object> get props => [newMeasurements];
}