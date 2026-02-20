import 'package:equatable/equatable.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/service_call/validation_status.dart';

abstract class ProofOfServiceDetailState extends Equatable {
  const ProofOfServiceDetailState();

  @override
  List<Object> get props => [];
}

class ProofOfServiceDetailInitial extends ProofOfServiceDetailState {}
class ProofOfServiceDetailLoading extends ProofOfServiceDetailState {}

class ProofOfServiceDetailLoaded extends ProofOfServiceDetailState {
  final ProofOfServiceDetailModel data;
  final Map<String, ValidationStatus> validationStatuses;

  // 🔥 KERANJANG BARU UNTUK NYIMPEN SN HASIL INPUTAN
  final Map<String, String> savedSerials;

  const ProofOfServiceDetailLoaded(
      this.data,
      this.validationStatuses,
      {this.savedSerials = const {}}
      );
}

class ProofOfServiceDetailError extends ProofOfServiceDetailState {
  final String message;

  const ProofOfServiceDetailError(this.message);
}