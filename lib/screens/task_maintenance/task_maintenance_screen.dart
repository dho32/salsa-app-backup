import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salsa/screens/task_maintenance/components/task_maintenance_body_mobile.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_storage.dart';
import '../../blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import '../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_repository.dart';
import '../../blocs/task_maintenance/task_maintenance_bloc.dart';
import '../../blocs/task_maintenance/task_maintenance_repository.dart';
import '../../blocs/upload_progress/upload_progress_cubit.dart';
import 'components/widget/task_maintenance_widgets.dart';

class TaskMaintenanceScreen extends StatefulWidget {
  const TaskMaintenanceScreen({super.key});

  @override
  State<TaskMaintenanceScreen> createState() => _TaskMaintenanceScreenState();
}

class _TaskMaintenanceScreenState extends State<TaskMaintenanceScreen> {
  bool _isLoading = true;
  Map<String, String?> _userData = {};
  String _appVersion = '';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initAppVersion();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthStorage.getUser();
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _initAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _appVersion = 'Versi $_version';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // return buildTaskMaintenanceShimmerBody();
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[300]!,
        ),
        body: buildTaskMaintenanceShimmerBody(),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TaskMaintenanceBloc(
            repository: TaskMaintenanceRepository(),
          ),
        ),
        BlocProvider(
          create: (context) => UploadProgressCubit(),
        ),
        BlocProvider(
          create: (context) => PosSubmittedBloc(
            repository: PosSubmittedRepository(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => FailedUploadsBloc(
          progressCubit: context.read<UploadProgressCubit>(),
        )..add(LoadFailedUploads()),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/bg_app.png",
                fit: BoxFit.cover,
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: _appVersion.isNotEmpty
                    ? Text(_appVersion,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black54))
                    : null,
                backgroundColor: Colors.transparent,
                // Samakan dengan latar belakang
                elevation: 0,
                // Hilangkan bayangan
                automaticallyImplyLeading: false,
                // Hilangkan tombol kembali
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () async {
                        final bool? shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Konfirmasi Log Out'),
                            content: const Text(
                                'Apakah Anda yakin ingin keluar dari aplikasi?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Ya, Keluar'),
                              ),
                            ],
                          ),
                        );
        
                        // Jika pengguna menekan "Ya, Keluar"
                        if (shouldLogout == true && context.mounted) {
                          context.read<AuthBloc>().add(LoggedOut());
                        }
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedSuperellipseBorder(
                            borderRadius:
                                BorderRadiusGeometry.all(Radius.circular(50))),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text(
                                "Keluar",
                                style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: TaskMaintenanceBodyMobile(userData: _userData),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
