// lib/blocs/proof_of_service_detail/proof_of_service_detail_state.dart

part of 'proof_of_service_detail_bloc.dart';

abstract class ProofOfServiceDetailState extends Equatable {
  const ProofOfServiceDetailState();
  @override
  List<Object?> get props => [];
}

class ProofOfServiceDetailInitial extends ProofOfServiceDetailState {}
class ProofOfServiceDetailLoading extends ProofOfServiceDetailState {}
class ProofOfServiceDetailError extends ProofOfServiceDetailState {
  final String message;
  const ProofOfServiceDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProofOfServiceDetailLoaded extends ProofOfServiceDetailState {
  final String transNo;
  final POSUnitItem unitInfo; // Data unit yg tidak berubah
  final ProofOfServiceDetailData inputData; // Data form yg bisa berubah

  const ProofOfServiceDetailLoaded({
    required this.transNo,
    required this.unitInfo,
    required this.inputData,
  });

  @override
  List<Object?> get props => [transNo, unitInfo, inputData];
}