import '../../models/auth/maintenance_info_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthFirstLoading extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthRequiresMaintenanceSelection extends AuthState {
  final List<MaintenanceInfo> maintenanceOptions;
  final String token; // Bawa token sementara

  AuthRequiresMaintenanceSelection(this.maintenanceOptions, this.token);
}
