import 'package:flutter_bloc/flutter_bloc.dart';
import '../../components/shared_function.dart';
import '../../models/auth/maintenance_info_model.dart';
import 'auth_event.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_storage.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<MaintenanceSelected>(_onMaintenanceSelected);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthFirstLoading());

    final hasToken = await authRepository.hasToken();
    final isExpired = await AuthStorage.isTokenExpired();

    if (hasToken && !isExpired) {
      emit(AuthAuthenticated());
    } else {
      await authRepository.recordLogout();
      await authRepository.deleteToken(); // clean-up
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.login(event.email, event.password);
      final payload = JwtHelper.decode(token);
      if (payload == null) throw Exception("Token tidak valid");

      final List<dynamic> maintenanceList = payload['maintenance'] ?? [];
      final options = maintenanceList.map((json) => MaintenanceInfo.fromJson(json)).toList();

      if (options.length > 1) {
        // Jika ada lebih dari 1 pilihan, minta pengguna memilih
        emit(AuthRequiresMaintenanceSelection(options, token));
      } else {
        // Jika hanya 1 (atau 0), langsung simpan dan autentikasi
        await authRepository.saveUserSession(token);
        final String vendorId = options.isNotEmpty ? options.first.maintenanceBy : '';
        await authRepository.recordLogin(token, vendorId);
        emit(AuthAuthenticated());
      }
    } catch (e) {
      final message = e.toString().replaceAll(RegExp(r'Exception:\s*'), '');
      emit(AuthFailure(message));
    }
  }
  Future<void> _onMaintenanceSelected(MaintenanceSelected event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.saveUserSession(event.token, selectedMaintenance: event.selectedMaintenance);
      await authRepository.recordLogin(event.token, event.selectedMaintenance.maintenanceBy);
      emit(AuthAuthenticated());
    } catch(e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepository.recordLogout();
    await authRepository.deleteToken();
    emit(AuthUnauthenticated());
  }
}
