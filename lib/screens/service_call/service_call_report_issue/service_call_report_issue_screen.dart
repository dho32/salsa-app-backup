import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_unserviceable/sc_unserviceable_event.dart';

import '../../../blocs/service_call/service_call_unserviceable/sc_unserviceable_bloc.dart';
import '../../../blocs/service_call/service_call_unserviceable/sc_unserviceable_state.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../components/shared_widgets.dart';
import '../../common/services/confirmation_service.dart';
import 'components/service_call_report_issue_body_mobile.dart';

class SCReportIssueScreen extends StatelessWidget {
  final String transNo;
  final String pathAttachment;
  final List<String> reasons;

  const SCReportIssueScreen({
    super.key,
    required this.transNo,
    required this.pathAttachment,
    required this.reasons,
  });

  @override
  Widget build(BuildContext context) {
    // Gunakan ScUnserviceableBloc
    return BlocConsumer<SCUnserviceableBloc, SCUnserviceableState>(
      listener: (context, state) {
        final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;
        if (state.status == UnserviceableStatus.failure) {
          if (isDialogShowing) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          print(state.errorMessage);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Terjadi error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == UnserviceableStatus.success) {
          // Tutup dialog progress terlebih dahulu jika sedang tampil
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Tampilkan dialog sukses
          ConfirmationService().processQueue();
          showSuccessDialog(
            context,
            "Laporan berhasil dikirim.",
            onOk: () {
              // Saat "OK" ditekan, kembali ke halaman paling awal
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          );
        } else if (state.status == UnserviceableStatus.uploading) {
          final uploadCubit = context.read<UploadProgressCubit>();
          uploadCubit.reset();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => BlocProvider.value(
              value: uploadCubit,
              child: const UploadProgressDialog(),
            ),
          );
        } else if (state.status == UnserviceableStatus.partialFailure) {
          if (Navigator.canPop(context))
            Navigator.pop(context); // Tutup dialog progress
          final partialData = state.partialUploadData;
          if (partialData != null) {
            showPartialUploadDialog(
                context,
                partialData['successCount'],
                // Kita bisa perbaiki ini untuk menunjukkan jumlah sukses
                (partialData['failedFiles'] as List).length,
                List<String>.from(partialData['failedFiles']));
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text("Laporan Masalah Kunjungan")),
          // Gunakan Body SC
          body: SCReportIssueBodyMobile(
            transNo: transNo,
            reasons: reasons,
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.all(16.0)
                .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            child: _buildBottomButton(context, state, pathAttachment), // Method ini sama
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(
      BuildContext context, SCUnserviceableState state, String pathAttachment) {
    final isLoading = state.status == UnserviceableStatus.loading ||
        state.status == UnserviceableStatus.uploading;

    if (state.status == UnserviceableStatus.partialFailure &&
        state.partialUploadData != null) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text("Coba Ulang Upload"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          final progressCubit = context.read<UploadProgressCubit>();
          context.read<SCUnserviceableBloc>().add(RetryUnserviceableUpload(
                presignedDetail: state.partialUploadData!['presignedDetail'],
                failedFiles:
                    List<String>.from(state.partialUploadData!['failedFiles']),
                progressCubit: progressCubit,
              ));
        },
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.send),
      label: const Text("Kirim Laporan"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: (state.proofImages.isNotEmpty &&
              state.selectedReason != null &&
              !isLoading)
          ? () {
              final progressCubit = context.read<UploadProgressCubit>();
              context.read<SCUnserviceableBloc>().add(
                  SubmitUnserviceableReport(progressCubit, pathAttachment));
            }
          : null,
    );
  }
}
