// lib/blocs/proof_of_service_detail/proof_of_service_detail_event.dart

part of 'proof_of_service_detail_bloc.dart';

abstract class ProofOfServiceDetailEvent extends Equatable {
  const ProofOfServiceDetailEvent();
  @override
  List<Object> get props => [];
}

// Event untuk memuat data awal dari Hive
class FetchProofOfServiceDetail extends ProofOfServiceDetailEvent {
  final String transNo;
  final POSUnitItem unit;
  const FetchProofOfServiceDetail(this.transNo, this.unit);
  @override
  List<Object> get props => [transNo, unit];
}

// Event saat nilai di form berubah
class UpdateProofOfServiceDetail extends ProofOfServiceDetailEvent {
  final ProofOfServiceDetailData newData;
  const UpdateProofOfServiceDetail(this.newData);
  @override
  List<Object> get props => [newData];
}

// Event saat form disimpan
class SaveProofOfServiceDetail extends ProofOfServiceDetailEvent {}