import '../../models/auth/maintenance_info_model.dart';

abstract class AuthEvent {}

class AppLoaded extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String version;

  LoginRequested(this.email, this.password, this.version);
}

class LoggedOut extends AuthEvent {}

class MaintenanceSelected extends AuthEvent {
  final MaintenanceInfo selectedMaintenance;
  final String token;

  MaintenanceSelected(this.selectedMaintenance, this.token);
}
