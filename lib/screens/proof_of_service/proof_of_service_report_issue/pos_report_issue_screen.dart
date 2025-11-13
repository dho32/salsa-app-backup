import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/proof_of_service/pos_unserviceable/pos_unserviceable_bloc.dart';
import 'package:salsa/blocs/proof_of_service/pos_unserviceable/pos_unserviceable_event.dart';
import 'package:salsa/blocs/proof_of_service/pos_unserviceable/pos_unserviceable_state.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/shared_widgets.dart';
import '../../common/services/confirmation_service.dart';
import 'components/pos_report_issue_body_mobile.dart';

class PosReportIssueScreen extends StatelessWidget {
  final String transNo;
  final List<String> reasons;

  const PosReportIssueScreen({
    super.key,
    required this.transNo,
    required this.reasons,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PosUnserviceableBloc, PosUnserviceableState>(
      listener: (context, state) {
        if (state.status == UnserviceableStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Terjadi error'),
              backgroundColor: Colors.red,
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
          if (Navigator.canPop(context)) Navigator.pop(context); // Tutup dialog progress
          final partialData = state.partialUploadData;
          if (partialData != null) {
            showPartialUploadDialog(
                context,
                partialData['successCount'], // Kita bisa perbaiki ini untuk menunjukkan jumlah sukses
                (partialData['failedFiles'] as List).length,
                List<String>.from(partialData['failedFiles']));
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Laporan Masalah Kunjungan"),
          ),
          body: PosReportIssueBodyMobile(
            transNo: transNo,
            reasons: reasons,
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0)
                .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            child: _buildBottomButton(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(BuildContext context, PosUnserviceableState state) {
    final isLoading = state.status == UnserviceableStatus.loading ||
        state.status == UnserviceableStatus.uploading;

    if (state.status == UnserviceableStatus.partialFailure && state.partialUploadData != null) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text("Coba Ulang Upload"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          final progressCubit = context.read<UploadProgressCubit>();
          context.read<PosUnserviceableBloc>().add(RetryUnserviceableUpload(
            presignedDetail: state.partialUploadData!['presignedDetail'],
            failedFiles: List<String>.from(state.partialUploadData!['failedFiles']),
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
          state.technicianName.isNotEmpty &&
          !isLoading)
          ? () {
        final progressCubit = context.read<UploadProgressCubit>();
        context
            .read<PosUnserviceableBloc>()
            .add(SubmitUnserviceableReport(progressCubit));
      }
          : null,
    );
  }
}