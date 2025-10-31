// lib/screens/common/failed_uploads/failed_uploads_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_bloc.dart';
import 'package:salsa/components/shared_widgets.dart';

import '../services/confirmation_service.dart';
import 'components/failed_uploads_body_mobile.dart';

class FailedUploadsScreen extends StatefulWidget {
  const FailedUploadsScreen({super.key});

  @override
  State<FailedUploadsScreen> createState() => _FailedUploadsScreenState();
}

class _FailedUploadsScreenState extends State<FailedUploadsScreen> {
  BuildContext? _progressDialogContext;
  String? _retryingTransNo;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Upload Gagal"),
      ),
      // ✅ GANTI BODY LAMA DENGAN BLOCLISTENER INI
      body: BlocListener<FailedUploadsBloc, FailedUploadsState>(
        // Dengarkan perubahan status ATAU saat pesan/hasil muncul
        listenWhen: (previous, current) {
          // Hanya trigger listener jika ada perubahan relevan
          bool statusChanged = previous.status != current.status;
          bool uploadingChanged = previous.uploadingTransNo != current.uploadingTransNo;
          bool messageAppeared = (previous.snackbarMessage == null && current.snackbarMessage != null) ||
              (previous.successMessage == null && current.successMessage != null);
          return statusChanged || uploadingChanged || messageAppeared;
        },
        listener: (context, state) {
          // Ambil BLoC untuk kirim event clear
          final bloc = context.read<FailedUploadsBloc>();

          // --- 1. Logika Menampilkan Dialog Progress ---
          // Tampilkan HANYA jika status berubah menjadi uploading DAN dialog belum ada
          if (state.status == FailedUploadsStatus.uploading && state.uploadingTransNo != null && _progressDialogContext == null) {
            _retryingTransNo = state.uploadingTransNo; // Simpan ID yg di-retry
// Simpan tipe modul

            print("▶️ Showing progress dialog for $_retryingTransNo");
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                _progressDialogContext = dialogContext; // Simpan context
                return BlocProvider.value(
                  value: bloc.progressCubit, // Ambil dari BLoC
                  child: const UploadProgressDialog(),
                );
              },
            ).then((_) {
              // Reset context saat dialog ditutup (oleh pop atau sistem)
              _progressDialogContext = null;
              _retryingTransNo = null;
              print("☑️ Progress dialog closed.");
              ConfirmationService().processQueue();
            });
          }

          // --- 2. Logika Menutup Dialog Progress & Menampilkan Hasil ---
          // Tutup dialog JIKA status TIDAK lagi uploading DAN sebelumnya ADA yg diupload
          // DAN dialognya memang sedang tampil
          else if (state.status != FailedUploadsStatus.uploading && _retryingTransNo != null) {
            print("⏹️ Closing progress dialog for $_retryingTransNo and showing result...");
            Navigator.of(context).pop();

            Future.delayed(const Duration(milliseconds: 200), () {
              // Ambil state TERKINI setelah dialog progress ditutup
              final currentState = context.read<FailedUploadsBloc>().state;

              if (mounted) {
                if (currentState.successMessage != null) {
                  ConfirmationService().processQueue();
                  print("🎉 Showing success dialog...");
                  showSuccessDialog(
                    context,
                    currentState.successMessage!,
                  ).then((_) {
                    print("👍 Success dialog closed. Clearing message.");
                    bloc.add(ClearSuccessMessage());
                  });
                } else if (currentState.snackbarMessage != null) {
                  if (currentState.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentState.errorMessage!),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  bloc.add(ClearSnackbarMessage());
                }
              }
            });
          }
        },
        // Child listener adalah body Anda
        child: const FailedUploadsBodyMobile(),
      ),
    );
  }
}