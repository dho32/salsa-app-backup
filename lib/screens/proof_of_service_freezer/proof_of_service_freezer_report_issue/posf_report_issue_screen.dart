import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/proof_of_service_freezer/posf_closed/posf_closed_bloc.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/shared_widgets.dart';

import 'components/posf_report_issue_body_mobile.dart';

/// Layar "Freezer Tidak Bisa Diservis" (close / unserviceable POSF).
///
/// [PosfClosedBloc] & [UploadProgressCubit] di-provide oleh pemanggil (detail
/// screen) via `BlocProvider.value` — mirror pola POS report-issue.
class PosfReportIssueScreen extends StatelessWidget {
  final String transNo;
  final List<String> reasons;

  const PosfReportIssueScreen({
    super.key,
    required this.transNo,
    required this.reasons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Freezer Tidak Bisa Dicuci')),
      body: BlocListener<PosfClosedBloc, PosfClosedState>(
        listener: _onStateChanged,
        child: PosfReportIssueBodyMobile(transNo: transNo, reasons: reasons),
      ),
      bottomNavigationBar: BlocBuilder<PosfClosedBloc, PosfClosedState>(
        builder: (context, state) {
          final isBusy = state.status == PosfClosedStatus.loading ||
              state.status == PosfClosedStatus.uploading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (isBusy || !state.isReadyToSubmit)
                      ? null
                      : () {
                          final progressCubit =
                              context.read<UploadProgressCubit>();
                          context
                              .read<PosfClosedBloc>()
                              .add(SubmitClosedReport(progressCubit));
                        },
                  child: const Text('Kirim Laporan'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onStateChanged(BuildContext context, PosfClosedState state) {
    switch (state.status) {
      case PosfClosedStatus.uploading:
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
        break;
      case PosfClosedStatus.partialFailure:
        if (Navigator.canPop(context)) Navigator.pop(context);
        showPartialUploadDialog(
          context,
          state.successCount,
          state.failureCount,
          state.failedFiles,
        );
        break;
      case PosfClosedStatus.success:
        if (Navigator.canPop(context)) Navigator.pop(context);
        showSuccessDialog(
          context,
          'Laporan freezer tidak bisa diservis berhasil dikirim.',
          onOk: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
        break;
      case PosfClosedStatus.failure:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? 'Terjadi kesalahan.'),
            backgroundColor: Colors.red,
          ));
        break;
      case PosfClosedStatus.initial:
      case PosfClosedStatus.loading:
        break;
    }
  }
}
