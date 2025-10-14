import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salsa/models/service_call/transaction_info_model.dart';
import 'package:salsa/screens/common/auth_gate/auth_gate.dart';
import 'package:salsa/screens/common/services/confirmation_service.dart';
import 'package:upgrader/upgrader.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_repository.dart';
import 'components/constants.dart';
import 'components/salsa_theme.dart';
import 'firebase_options.dart';
import 'models/common/captured_image_detail.dart';
import 'models/common/measurement_entry.dart';
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
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
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

    // Registrasi adapter bisa tetap di sini, karena sinkron
    Hive.registerAdapter(ValidationProblemAdapter());
    Hive.registerAdapter(ServiceCallValidationEntryModelAdapter());
    Hive.registerAdapter(ProofOfServiceDetailDataAdapter());
    Hive.registerAdapter(CapturedImageDetailAdapter());
    Hive.registerAdapter(MeasurementEntryAdapter());
    Hive.registerAdapter(TransactionInfoModelAdapter());
    Hive.registerAdapter(ConfirmationTaskModelAdapter()); //6
    Hive.registerAdapter(PosTransactionInfoModelAdapter()); //7
    Hive.registerAdapter(PosValidationEntryModelAdapter()); //8
    Hive.registerAdapter(ProofOfServiceDetailModelAdapter()); // 10
    Hive.registerAdapter(ProofOfServiceHeaderAdapter()); // 11
    Hive.registerAdapter(ProofOfServiceItemDetailAdapter()); //12
    Hive.registerAdapter(PosUnserviceableModelAdapter()); //13
    await Hive.openBox<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
    await Hive.openBox<ProofOfServiceDetailData>(kProofOfServiceHiveBox);
    await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
    await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
    await Hive.openBox('otp_state');
    await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
    await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableVisitQueueBox);

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Jalankan proses background
    ConfirmationService().processQueue();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Cek status future
        if (snapshot.connectionState == ConnectionState.done) {
          // JIKA SEMUA INISIALISASI SELESAI
          if (snapshot.hasError) {
            // Jika ada error, tampilkan halaman error
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text("Gagal memulai aplikasi: ${snapshot.error}"),
                ),
              ),
            );
          }

          // Jika berhasil, bangun aplikasi utama Anda
          final authRepository = AuthRepository();
          return RepositoryProvider.value(
            value: authRepository,
            child: BlocProvider(
              create: (_) => AuthBloc(authRepository: authRepository)..add(AppLoaded()),
              child: const MyApp(), // Lanjutkan ke MyApp Anda yang lama
            ),
          );
        }

        // SELAMA MENUNGGU, tampilkan loading indicator
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
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
    // Panggil fungsi pre-cache di sini
    _precacheImage();
  }

  Future<void> _precacheImage() async {
    // Hanya jalankan sekali
    if (_isImagePrecached) return;

    await precacheImage(const AssetImage("assets/images/bg_app.png"), context);

    setState(() {
      _isImagePrecached = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImagePrecached) {
      return const MaterialApp(
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
