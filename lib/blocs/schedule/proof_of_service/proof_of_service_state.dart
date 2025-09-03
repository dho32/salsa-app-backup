// lib/blocs/proof_of_service/proof_of_service_detail_state.dart

part of 'proof_of_service_bloc.dart';

abstract class ProofOfServiceState extends Equatable {
  const ProofOfServiceState();
  @override
  List<Object> get props => [];
}

class POSInitial extends ProofOfServiceState {}
class POSLoading extends ProofOfServiceState {}
class POSError extends ProofOfServiceState {
  final String message;
  const POSError(this.message);
  @override
  List<Object> get props => [message];
}

class POSLoaded extends ProofOfServiceState {
  final POSHeaderData headerData;
  final POSMeasurementData measurements;
  final List<POSUnitItem> unitList;

  const POSLoaded({
    required this.headerData,
    required this.measurements,
    required this.unitList,
  });

  POSLoaded copyWith({
    POSHeaderData? headerData,
    POSMeasurementData? measurements,
    List<POSUnitItem>? unitList,
  }) {
    return POSLoaded(
      headerData: headerData ?? this.headerData,
      measurements: measurements ?? this.measurements,
      unitList: unitList ?? this.unitList,
    );
  }

  @override
  List<Object> get props => [headerData, measurements, unitList];
}