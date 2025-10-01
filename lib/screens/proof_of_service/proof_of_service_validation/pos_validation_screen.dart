import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';

import '../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_bloc.dart';
import '../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_event.dart';
import '../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_state.dart';
import '../../../components/constants.dart';
import 'components/pos_validation_body_mobile.dart';

class PosValidationScreen extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String unitType;
  final PosValidationEntryModel? initialData;
  final String articleNo;
  final String articleDesc;
  final String articleUnitDesc;
  final int capacity;
  final double? indoorTemp;
  final List<String> allIndoorSerials;
  final List<String> noteOptions;

  const PosValidationScreen({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.unitType,
    this.initialData,
    required this.articleNo,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.capacity,
    required this.indoorTemp,
    required this.allIndoorSerials,
    required this.noteOptions,
  });

  @override
  State<PosValidationScreen> createState() => _PosValidationScreenState();
}

class _PosValidationScreenState extends State<PosValidationScreen> {
  final _noteController = TextEditingController();

  bool _areAllMeasurementsFilled(List<MeasurementEntry> measurements) {
    if (measurements.isEmpty) return true;
    return measurements
        .every((m) => m.isSkipped || (m.capturedImage != null && m.value != 0));
  }

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialData?.note ?? '';


  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showValidationErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PosValidationBloc()
        ..add(FetchPosValidationData(
          initialData: widget.initialData,
          unitType: widget.unitType,
          allIndoorSerials: widget.allIndoorSerials, // <-- Kirim daftar
          serialNo: widget.serialNo, // <-- Kirim SN unit ini
          transNo: widget.transNo,
        )),
      child: BlocListener<PosValidationBloc, PosValidationState>(
        listener: (context, state) {
          if (state is PosValidationSaveFailure) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          else if (state is PosValidationSaveSuccess) {
            Navigator.of(context).pop(true); // Kembali ke halaman sebelumnya
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Data berhasil disimpan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        child: BlocBuilder<PosValidationBloc, PosValidationState>(
          builder: (context, state) {
            PosValidationLoaded? uiState;
            if (state is PosValidationLoaded) {
              uiState = state;
            } else if (state is PosValidationSaveFailure) {
              uiState = state.lastState;
            }
            return Scaffold(
              appBar: AppBar(title: const Text("Validasi Perawatan Unit AC")),
              body: PosValidationBodyMobile(
                transNo: widget.transNo,
                serialNo: widget.serialNo,
                unitType: widget.unitType,
                articleDesc: widget.articleDesc,
                articleUnitDesc: widget.articleUnitDesc,
                noteController: _noteController,
                indoorTemp: widget.indoorTemp,
                noteOptions: widget.noteOptions,
              ),
              bottomNavigationBar: (uiState != null)
                  ? _buildFloatingButtons(context, uiState)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(
      BuildContext context, PosValidationLoaded state) {
    final bloc = context.read<PosValidationBloc>();
    final Color primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          if (state.currentStep == 1) ...[
            // Tombol di Step 2 (Sesudah)
            Expanded(
              child: OutlinedButton.icon(
                label: const Text('Kembali'),
                onPressed: () => bloc.add(const ChangePosValidationStep(0)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary), foregroundColor: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Simpan'),
                onPressed: () {
                  final bool isAnyMeasurementSkipped =
                      state.measurementsAfter.any((m) => m.isSkipped);

                  if (state.photosAfter.isEmpty) {
                    _showValidationErrorSnackbar(
                        'Foto unit sesudah cuci wajib dilengkapi.');
                    return;
                  }
                  if (!_areAllMeasurementsFilled(state.measurementsAfter)) {
                    _showValidationErrorSnackbar(
                        'Harap isi semua nilai & foto hasil pengukuran.');
                    return;
                  }

                  if (isAnyMeasurementSkipped &&
                      _noteController.text.trim().isEmpty) {
                    _showValidationErrorSnackbar(
                        'Catatan wajib diisi, jika unit tidak bisa diukur.');
                    return;
                  }

                  for (final measurement in state.measurementsAfter) {
                    if (measurement.isSkipped) continue;

                    final limits = kPOSMeasurementLimits[measurement.measurementId];
                    if (limits != null) {
                      // Tentukan batas atas dinamis untuk suhu
                      double maxLimit = limits.max;
                      if (measurement.measurementId == 'temperature' && widget.indoorTemp != null) {
                        maxLimit = widget.indoorTemp!;
                      }

                      // Lakukan pengecekan
                      if (measurement.value > maxLimit) {
                        final errorMessage =
                            'Nilai "${limits.label}" yang anda input melebihi batas.';
                        _showValidationErrorSnackbar(errorMessage);
                        return; // Hentikan proses jika ada yang tidak valid
                      }
                    }
                  }

                  bloc.add(SavePosValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    markAsCompleted: true,
                    note: _noteController.text,
                    articleNo: widget.articleNo,
                    articleDesc: widget.articleDesc,
                    articleUnitDesc: widget.articleUnitDesc,
                    capacity: widget.capacity,
                    articleType: widget.unitType,
                    indoorTemp: widget.indoorTemp,
                  ));
                  // Navigator.of(context).pop(true);
                  // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  //   content: Text('Data berhasil disimpan'),
                  //   backgroundColor: Colors.green,
                  //   behavior: SnackBarBehavior.floating,
                  // ));
                },
              ),
            ),
          ] else if (state.currentStep == 0) ...[
            // Tombol di Step 1 (Sebelum)
            Expanded(
              child: OutlinedButton.icon(
                label: const Text('Simpan Draft'),
                onPressed: () {
                  bloc.add(SavePosValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    markAsCompleted: false,
                    note: _noteController.text,
                    articleNo: widget.articleNo,
                    articleDesc: widget.articleDesc,
                    articleUnitDesc: widget.articleUnitDesc,
                    capacity: widget.capacity,
                    articleType: widget.unitType,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Draft berhasil disimpan'),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary), foregroundColor: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                child: const Text('Lanjut'),
                onPressed: () {
                  if (state.photosBefore.isEmpty) {
                    _showValidationErrorSnackbar(
                        'Foto unit sebelum cuci wajib dilengkapi untuk melanjutkan.');
                    return;
                  }
                  if (state.unitType.toUpperCase() == 'OUT' &&
                      state.pairedIndoorSerial == null) {
                    _showValidationErrorSnackbar(
                        'Anda wajib memilih pasangan unit indoor untuk melanjutkan.');
                    return;
                  }
                  bloc.add(SavePosValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    note: _noteController.text,
                    articleNo: widget.articleNo,
                    articleDesc: widget.articleDesc,
                    articleUnitDesc: widget.articleUnitDesc,
                    capacity: widget.capacity,
                    articleType: widget.unitType,
                  ));
                  bloc.add(const ChangePosValidationStep(1));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
