import 'package:equatable/equatable.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';
import '../../../models/service_call/validation_status.dart';
import '../../../models/common/measurement_limits.dart'; // <-- IMPORT LIMIT

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

  // --- [TAMBAHAN: Limit Dinamis untuk UI POS] ---
  final Map<String, MeasurementLimits> limitsMap;

  const ProofOfServiceDetailLoaded(
      this.data,
      this.validationStatuses, {
        this.savedSerials = const {},
        this.limitsMap = const {}, // Default kosong biar aman
      });

  // Wajib ditambahin ke props biar UI nge-refresh pas limit-nya berubah
  @override
  List<Object> get props => [data, validationStatuses, savedSerials, limitsMap];
}

class ProofOfServiceDetailError extends ProofOfServiceDetailState {
  final String message;

  const ProofOfServiceDetailError(this.message);

  @override
  List<Object> get props => [message];
}