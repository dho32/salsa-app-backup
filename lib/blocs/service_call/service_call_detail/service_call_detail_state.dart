import 'package:salsa/models/service_call/service_call_detail_model.dart';
import 'package:salsa/models/common/measurement_limits.dart'; // Pastikan path ini sesuai

abstract class ServiceCallDetailState {}

class ServiceCallDetailInitial extends ServiceCallDetailState {}

class ServiceCallDetailLoading extends ServiceCallDetailState {}

class ServiceCallDetailLoaded extends ServiceCallDetailState {
  final ServiceCallDetailModel data; // Biar nggak banyak ubah di UI lama Akang

  // --- [TAMBAHAN: Limit Dinamis untuk UI] ---
  final Map<String, MeasurementLimits> limitsBefore;
  final Map<String, MeasurementLimits> limitsAfter;

  ServiceCallDetailLoaded({
    required this.data,
    required this.limitsBefore,
    required this.limitsAfter,
  });
}

class ServiceCallDetailError extends ServiceCallDetailState {
  final String message;

  ServiceCallDetailError(this.message);
}