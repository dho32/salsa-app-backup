import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salsa/models/service_call/sc_unserviceable_model.dart';
import 'package:salsa/models/service_call/transaction_info_model.dart';
import 'package:salsa/screens/common/auth_gate/auth_gate.dart';
import 'package:salsa/screens/common/error_page/error_retry_screen.dart';
import 'package:salsa/screens/common/services/confirmation_service.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_repository.dart';
import 'components/constants.dart';
import 'components/salsa_theme.dart';
import 'firebase_options.dart';
import 'models/common/captured_image_detail.dart';
import 'models/common/measurement_entry.dart';
import 'models/common/measurement_limits.dart';
import 'models/common/note_option.dart';
import 'models/common/otp_tracking_model.dart';
import 'models/proof_of_service/pos_transaction_info_model.dart';
import 'models/proof_of_service/pos_unserviceable_model.dart';
import 'models/proof_of_service/pos_validation_entry_model.dart';
import 'models/proof_of_service/proof_of_service_detail_model.dart';
import 'models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import 'models/service_call/service_call_validation_entry_model.dart';
import 'models/task_maintenance/confirmation_task_queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppInitializer());
}


class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initializationFuture;
  bool _oneTimeSetupDone = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  // Fungsi ini dipanggil oleh initState dan future-nya ditampung
  Future<void> _initialize() async {
    if (!_oneTimeSetupDone) {
      await _setupOneTimeThings();
    }
    // Langsung panggil (tanpa setState)
    await _loadRetryableData();
  }

  // Fungsi setup sekali jalan (TETAP SAMA)
  Future<void> _setupOneTimeThings() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await initializeDateFormatting('id_ID', null);
    await Hive.initFlutter();

    // Registrasi adapter
    _registerHiveAdapters();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _oneTimeSetupDone = true;
  }

  void _registerHiveAdapters() {
    Hive.registerAdapter(ValidationProblemAdapter());
    Hive.registerAdapter(ServiceCallValidationEntryModelAdapter());
    Hive.registerAdapter(ProofOfServiceDetailDataAdapter());
    Hive.registerAdapter(CapturedImageDetailAdapter());
    Hive.registerAdapter(MeasurementEntryAdapter());
    Hive.registerAdapter(TransactionInfoModelAdapter());
    Hive.registerAdapter(ConfirmationTaskModelAdapter());
    Hive.registerAdapter(PosTransactionInfoModelAdapter());
    Hive.registerAdapter(PosValidationEntryModelAdapter());
    Hive.registerAdapter(ProofOfServiceDetailModelAdapter());
    Hive.registerAdapter(ProofOfServiceHeaderAdapter());
    Hive.registerAdapter(ProofOfServiceItemDetailAdapter());
    Hive.registerAdapter(PosUnserviceableModelAdapter());
    Hive.registerAdapter(SCUnserviceableModelAdapter());
    Hive.registerAdapter(MeasurementLimitsAdapter());
    Hive.registerAdapter(NoteOptionAdapter());
    Hive.registerAdapter(OtpTrackingModelAdapter());
  }

  // Fungsi yang bisa di-retry (TETAP SAMA)
  Future<void> _loadRetryableData() async {
    try {
      // Gunakan _openBoxSafely untuk setiap box penting
      // Ini mencegah aplikasi Force Close jika salah satu box korup/beda schema

      await _openBoxSafely<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      await _openBoxSafely<ProofOfServiceDetailData>(kProofOfServiceHiveBox);
      await _openBoxSafely<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);

      // Box Utama POS (Sering Crash disini biasanya)
      await _openBoxSafely<PosValidationEntryModel>(kPosValidationHiveBox);

      await _openBoxSafely<ProofOfServiceDetailModel>(kPosDetailCacheBox);
      await _openBoxSafely(null, boxName: 'otp_state'); // Box tanpa tipe generik
      await _openBoxSafely<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
      await _openBoxSafely<SCUnserviceableModel>(kScUnserviceableDraftsBox);
      await _openBoxSafely(null, boxName: kAppConfigBox);
      await _openBoxSafely<OtpTrackingModel>(kOtpTrackingBox);
    } catch (e) {
      // Jika error sangat fatal (Disk Penuh Total / Permission Error)
      print("💀 Fatal Init Error: $e");
      throw Exception("Gagal memuat penyimpanan lokal. Pastikan memori HP tidak penuh.");
    }

    ConfirmationService().processQueue();
  }

  Future<void> _openBoxSafely<T>(String? boxNameGeneric, {String? boxName}) async {
    final name = boxNameGeneric ?? boxName!;
    try {
      if (T != dynamic && T != Null) {
        await Hive.openBox<T>(name);
      } else {
        await Hive.openBox(name);
      }
    } catch (e) {
      print("🔥 Hive Box '$name' Korup/Mismatch: $e");
      print("🧹 Melakukan Self-Healing untuk box '$name'...");
      try {
        // Hapus file box yang rusak dari disk
        await Hive.deleteBoxFromDisk(name);
        // Coba buka lagi (seharusnya sekarang bersih)
        if (T != dynamic && T != Null) {
          await Hive.openBox<T>(name);
        } else {
          await Hive.openBox(name);
        }
        print("✅ Box '$name' berhasil dipulihkan (Data lama di box ini terhapus).");
      } catch (e2) {
        // Kalau masih gagal juga, berarti masalah disk fisik/permission
        print("❌ Gagal recovery box '$name': $e2");
        throw e2;
      }
    }
  }

  void _retryInitialization() {
    setState(() {
      _initializationFuture = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: ErrorRetryScreen(
                errorMessage: snapshot.error.toString(),
                onRetry: _retryInitialization,
              ),
            );
          }

          final authRepository = AuthRepository();
          return RepositoryProvider.value(
            value: authRepository,
            child: BlocProvider(
              create: (_) => AuthBloc(authRepository: authRepository)..add(AppLoaded()),
              child: const MyApp(),
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memuat data aplikasi...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isImagePrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImage();
  }

  Future<void> _precacheImage() async {
    if (_isImagePrecached) return;
    try {
      await precacheImage(const AssetImage("assets/images/bg_app.png"), context);
    } catch (e) {
      print("Gagal precache image: $e");
    }
    if (mounted) {
      setState(() {
        _isImagePrecached = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImagePrecached) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      title: 'SALSA',
      debugShowCheckedModeBanner: false,
      theme: SalsaTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
