import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_bloc.dart';
import 'package:salsa/components/shared_widgets.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';

// 🔥 IMPORT REPO & MODEL
import '../../../../models/task_maintenance/task_maintenance_model.dart';
import '../../../blocs/failed_uploads/failed_uploads_repository.dart';
import '../services/confirmation_service.dart';
import 'components/failed_uploads_body_mobile.dart';

class FailedUploadsScreen extends StatefulWidget {
  final List<TransactionSuggestion> apiPendingList;

  const FailedUploadsScreen({
    super.key,
    this.apiPendingList = const [],
  });

  @override
  State<FailedUploadsScreen> createState() => _FailedUploadsScreenState();
}

class _FailedUploadsScreenState extends State<FailedUploadsScreen> {
  BuildContext? _progressDialogContext;
  String? _retryingTransNo;
  late List<TransactionSuggestion> _localApiList;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _localApiList = List.from(widget.apiPendingList);
  }

  void _onWillPop() {
    Navigator.of(context).pop(_hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => FailedUploadsRepository(),
      child: BlocProvider(
        create: (context) => FailedUploadsBloc(
          repository: context.read<FailedUploadsRepository>(),
          progressCubit: UploadProgressCubit(),
        )..add(LoadFailedUploads()),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _onWillPop(); // Panggil fungsi manual kita
          },
          child: Scaffold(
            appBar: AppBar(title: const Text("Daftar Upload Gagal")),
            body: _buildBodyListener(),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyListener() {
    return BlocListener<FailedUploadsBloc, FailedUploadsState>(
      listenWhen: (prev, curr) {
        return prev.status != curr.status ||
            prev.uploadingTransNo != curr.uploadingTransNo ||
            (prev.snackbarMessage == null && curr.snackbarMessage != null) ||
            (prev.successMessage == null && curr.successMessage != null);
      },
      listener: (context, state) {
        final bloc = context.read<FailedUploadsBloc>();

        // 1. Show Dialog
        if (state.status == FailedUploadsStatus.uploading &&
            state.uploadingTransNo != null &&
            _progressDialogContext == null) {
          _retryingTransNo = state.uploadingTransNo;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => BlocProvider.value(
                value: bloc.progressCubit, child: const UploadProgressDialog()),
          ).then((_) {
            _progressDialogContext = null;
            ConfirmationService().processQueue();
          });
        }
        // 2. Close Dialog
        else if (state.status != FailedUploadsStatus.uploading &&
            _retryingTransNo != null) {

          // Tutup Loading Dialog jika masih terbuka
          if (_progressDialogContext != null && Navigator.canPop(context)) {
            Navigator.pop(context);
            _progressDialogContext = null;
          } else {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // 3. SUKSES -> Hapus Item & Tandai Changes
          if (state.successMessage != null) {
            _handleSuccessRemove(_retryingTransNo!);

            ConfirmationService().processQueue();
            showSuccessDialog(context, state.successMessage!)
                .then((_) => bloc.add(ClearSuccessMessage()));
          }
          // GAGAL
          else if (state.snackbarMessage != null) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
            }
            bloc.add(ClearSnackbarMessage());
          }

          _retryingTransNo = null;
        }
      },
      // Pass data API ke Body
      child: FailedUploadsBodyMobile(
        apiPendingList: _localApiList,
      ),
    );
  }

  void _handleSuccessRemove(String transNo) {
    setState(() {
      // 1. Hapus dari list tampilan biar hilang
      _localApiList.removeWhere((item) =>
      item.transNo.trim().toUpperCase() == transNo.trim().toUpperCase()
      );
      // 2. Tandai ada perubahan agar halaman depan refresh
      _hasChanges = true;
    });
  }
}
