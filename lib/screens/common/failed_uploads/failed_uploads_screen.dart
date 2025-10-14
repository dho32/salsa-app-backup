import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_state.dart';
import 'package:salsa/components/shared_widgets.dart';
import '../../../blocs/failed_uploads/failed_uploads_event.dart';
import '../services/confirmation_service.dart';
import 'components/failed_uploads_body_mobile.dart';

class FailedUploadsScreen extends StatelessWidget {
  const FailedUploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Upload Gagal"),
      ),
      // Gunakan BlocListener untuk menangani "side-effects" seperti dialog & snackbar
      body: BlocListener<FailedUploadsBloc, FailedUploadsState>(
        // Dengarkan hanya saat ada perubahan status upload atau ada pesan baru
        listenWhen: (previous, current) {
          return previous.uploadingTransNo != current.uploadingTransNo ||
              current.successMessage != null ||
              current.errorMessage != null;
        },
        listener: (context, state) {
          final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;

          // 1. Tampilkan dialog progress HANYA saat proses upload dimulai
          if (state.uploadingTransNo != null && !isDialogShowing) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                // Teruskan progressCubit agar dialog bisa menampilkan progress
                value: context.read<FailedUploadsBloc>().progressCubit,
                child: const UploadProgressDialog(),
              ),
            );
          }
          // 2. Tutup dialog progress HANYA saat proses upload selesai
          else if (state.uploadingTransNo == null && isDialogShowing) {
            Navigator.of(context).pop();
          }

          // 3. Tampilkan dialog sukses jika ada pesan sukses
          if (state.successMessage != null) {
            ConfirmationService().processQueue();
            showSuccessDialog(context, state.successMessage!).then((_) {
              // UI tidak lagi berpikir, hanya menjalankan perintah!
              if (state.successAction == SuccessAction.popToHome) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else { // Default-nya adalah stayAndRefresh
                context.read<FailedUploadsBloc>().add(LoadFailedUploads());
              }
            });
          }

          // 4. Tampilkan snackbar error jika ada pesan error
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: const FailedUploadsBodyMobile(),
      ),
    );
  }
}