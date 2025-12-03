import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../components/shared_function.dart';
import '../../models/auth/maintenance_info_model.dart';
import 'auth_event.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_storage.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppLoaded>(_onAppLoaded);
    on<LoginRequested>(_onLoginRequested);
    on<MaintenanceSelected>(_onMaintenanceSelected);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppLoaded(AppLoaded event, Emitter<AuthState> emit) async {
    emit(AuthFirstLoading());
    try {
      // Langkah 1: Pengecekan versi aplikasi
      final appConfig = await authRepository.getAppConfig();

      final String requiredVersion = appConfig['requiredVersion']!;
      final String updateUrl = appConfig['updateUrl']!;

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      if (_isUpdateRequired(currentVersion, requiredVersion)) {
        emit(AuthUpdateRequired(updateUrl));
        return; // Hentikan proses jika perlu update
      }

      // Langkah 2: Jika versi OK, lanjutkan pengecekan token
      final hasToken = await authRepository.hasToken();
      final isExpired = await AuthStorage.isTokenExpired();

      if (hasToken && !isExpired) {
        emit(AuthAuthenticated());
      } else {
        await authRepository.recordLogout();
        await authRepository.deleteToken();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Jika gagal (cth: tidak ada internet), arahkan ke halaman login
      await authRepository.recordLogout();
      await authRepository.deleteToken();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // BARU: Ambil versi aplikasi di sini
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      final token =
          await authRepository.login(event.email, event.password, appVersion);
      final payload = JwtHelper.decode(token);
      if (payload == null) throw Exception("Token tidak valid");

      final List<dynamic> maintenanceList = payload['maintenance'] ?? [];
      final options = maintenanceList
          .map((json) => MaintenanceInfo.fromJson(json))
          .toList();

      if (options.length > 1) {
        // Jika ada lebih dari 1 pilihan, minta pengguna memilih
        emit(AuthRequiresMaintenanceSelection(options, token));
      } else {
        // Jika hanya 1 (atau 0), langsung simpan dan autentikasi
        await authRepository.saveUserSession(token);
        final String vendorId =
            options.isNotEmpty ? options.first.maintenanceBy : '';
        await authRepository.recordLogin(token, vendorId, appVersion);
        emit(AuthAuthenticated());
      }
    } catch (e) {
      await Hive.deleteFromDisk();
      final message = e.toString().replaceAll(RegExp(r'Exception:\s*'), '');
      emit(AuthFailure(message));
    }
  }

  Future<void> _onMaintenanceSelected(
      MaintenanceSelected event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      await authRepository.saveUserSession(event.token,
          selectedMaintenance: event.selectedMaintenance);
      await authRepository.recordLogin(
          event.token, event.selectedMaintenance.maintenanceBy, appVersion);
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepository.recordLogout();
    await authRepository.deleteToken();
    emit(AuthUnauthenticated());
  }

  bool _isUpdateRequired(String currentVersion, String requiredVersion) {
    final List<int> currentParts = currentVersion
        .split('.')
        .map(
            (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final List<int> requiredParts = requiredVersion
        .split('.')
        .map(
            (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    int maxLength = currentParts.length > requiredParts.length
        ? currentParts.length
        : requiredParts.length;

    for (int i = 0; i < maxLength; i++) {
      final int current = (i < currentParts.length) ? currentParts[i] : 0;
      final int required = (i < requiredParts.length) ? requiredParts[i] : 0;
      if (current < required) return true;
      if (current > required) return false;
    }
    return false;
  }
}
