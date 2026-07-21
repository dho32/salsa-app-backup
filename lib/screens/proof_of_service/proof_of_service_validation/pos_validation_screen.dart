import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/common/note_option.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';

import '../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_bloc.dart';
import '../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_event.dart';
import '../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_state.dart';
import '../../../components/constants.dart';
import 'components/pos_validation_body_mobile.dart';
import 'package:hive/hive.dart';

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
  final List<NoteOption> noteOptions;
  final bool isGeneric;
  final int unitIndex;
  final String reffLineNo;

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
    this.isGeneric = false, // Default false
    this.unitIndex = 0,
    required this.reffLineNo,
  });

  @override
  State<PosValidationScreen> createState() => _PosValidationScreenState();
}

class _PosValidationScreenState extends State<PosValidationScreen> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  // ID pengukuran yang sudah dikonfirmasi "angka sesuai foto". Tombol Simpan
  // baru aktif setelah semua pengukuran non-skip terkonfirmasi. Mengedit ulang
  // nilai membatalkan konfirmasi (lihat MeasurementInputWidget).
  final Set<String> _confirmedIds = {};

  /// Fungsi debug yang mencetak status setiap elemen
  bool checkMeasurementDetails(List<MeasurementEntry> measurements) {
    bool allItemsPassed = true;

    for (int i = 0; i < measurements.length; i++) {
      var m = measurements[i];
      bool isSkippedCheck = m.isSkipped ?? false;
      bool isFilledCheck = (m.capturedImage != null && m.value != 0);
      bool didPass = isSkippedCheck || isFilledCheck;

      if (!didPass) {
        print('>>> Status: GAGAL pada ${m.measurementId}');
        allItemsPassed = false;
      }
    }
    return allItemsPassed;
  }

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialData?.note ?? '';
    // Pengukuran dari draft yang sudah punya nilai + foto dianggap sudah
    // terkonfirmasi saat unit dibuka kembali (edit).
    for (final m in widget.initialData?.measurementsAfter ?? const []) {
      if (!(m.isSkipped ?? false) &&
          m.value != 0 &&
          m.capturedImage != null) {
        _confirmedIds.add(m.measurementId);
      }
    }
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
          articleNo: widget.articleNo,
          articleDesc: widget.articleDesc,
          articleUnitDesc: widget.articleUnitDesc,
          allIndoorSerials: widget.allIndoorSerials,
          serialNo: widget.serialNo,
          transNo: widget.transNo,

          // 🔥 TERUSKAN KE BLOC
          isGeneric: widget.isGeneric,
          unitIndex: widget.unitIndex,
          reffLineNo: widget.reffLineNo,
        )),
      child: BlocListener<PosValidationBloc, PosValidationState>(
        listener: (context, state) {
          if (state is PosValidationSaveFailure) {
            _showValidationErrorSnackbar(state.message);
            setState(() { _isSaving = false; });
          } else if (state is PosValidationSaveSuccess) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Data berhasil disimpan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        child: BlocBuilder<PosValidationBloc, PosValidationState>(
          buildWhen: (previous, current) => current is! PosValidationSaveSuccess,
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
                onMeasurementConfirmedChanged: (id, confirmed) {
                  setState(() {
                    if (confirmed) {
                      _confirmedIds.add(id);
                    } else {
                      _confirmedIds.remove(id);
                    }
                  });
                },
              ), // Body ambil data dari Bloc langsung
              bottomNavigationBar: (uiState != null)
                  ? _buildFloatingButtons(context, uiState)
                  : null,
            );
          },
        ),
      ),
    );
  }

  /// Syarat tombol Simpan aktif (step Sesudah): foto sesudah ada, dan setiap
  /// pengukuran non-skip sudah punya nilai (!= 0) + foto DAN sudah dikonfirmasi
  /// "sesuai foto". Detail lain (limit, remark skip) tetap divalidasi saat
  /// tombol ditekan.
  bool _isStep1Complete(PosValidationLoaded s) {
    if (s.photosAfter.isEmpty) return false;
    for (final m in s.measurementsAfter) {
      final skipped = m.isSkipped ?? false;
      if (!skipped) {
        if (m.capturedImage == null || m.value == 0) return false;
        if (!_confirmedIds.contains(m.measurementId)) return false;
      }
    }
    return true;
  }

  Widget _buildFloatingButtons(
      BuildContext context, PosValidationLoaded state) {
    final bloc = context.read<PosValidationBloc>();
    final Color primary = Theme.of(context).primaryColor;
    final bool step1Complete = _isStep1Complete(state);

    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Petunjuk kenapa tombol Simpan belum bisa ditekan.
          if (state.currentStep == 1 && !step1Complete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Lengkapi & konfirmasi (Sesuai Foto) semua hasil pengukuran untuk menyimpan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500),
              ),
            ),
          Row(
        children: [
          if (state.currentStep == 1) ...[
            Expanded(
              child: OutlinedButton.icon(
                label: const Text('Kembali'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () => bloc.add(const ChangePosValidationStep(0)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary), foregroundColor: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                // Tombol baru aktif setelah semua nilai + foto pengukuran
                // lengkap (tidak bisa Simpan di tengah input).
                onPressed: (_isSaving || !step1Complete) ? null : () async {
                  setState(() { _isSaving = true; });
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 200));

                  final latestState = context.read<PosValidationBloc>().state;
                  if (latestState is! PosValidationLoaded) return;

                  final bool isAnyMeasurementSkipped = latestState
                      .measurementsAfter
                      .any((m) => m.isSkipped ?? false);

                  if (latestState.photosAfter.isEmpty) {
                    setState(() { _isSaving = false; });
                    _showValidationErrorSnackbar(
                        'Foto unit sesudah cuci wajib dilengkapi.');
                    return;
                  }

                  if (!checkMeasurementDetails(latestState.measurementsAfter)) {
                    setState(() { _isSaving = false; });
                    _showValidationErrorSnackbar(
                        'Harap isi semua nilai & foto hasil pengukuran.');
                    return;
                  }

                  if (isAnyMeasurementSkipped) {
                    if (_noteController.text.trim().isEmpty) {
                      setState(() { _isSaving = false; });
                      _showValidationErrorSnackbar(
                          'Catatan wajib diisi, jika unit tidak bisa diukur.');
                      return;
                    }

                    // Logic Validasi Remark
                    final selectedOption = widget.noteOptions.firstWhereOrNull(
                        (o) => o.label == _noteController.text);

                    if (selectedOption?.requireRemark == true) {
                      final remark = latestState.noteRemark ?? '';
                      if (remark.trim().isEmpty) {
                        setState(() { _isSaving = false; });
                        _showValidationErrorSnackbar(
                            'Keterangan Tambahan wajib diisi.');
                        return;
                      }
                      if (remark.replaceAll(' ', '').length < 20) {
                        setState(() { _isSaving = false; });
                        _showValidationErrorSnackbar(
                            'Keterangan Tambahan minimal 20 huruf.');
                        return;
                      }
                      final photos = state.remarkPhotos ?? [];
                      if (photos.isEmpty) {
                        setState(() { _isSaving = false; });
                        _showValidationErrorSnackbar(
                            'Wajib melampirkan foto untuk Remark.');
                        return;
                      }
                    }
                  }

                  // Validasi Limit Suhu
                  for (final measurement in latestState.measurementsAfter) {
                    if (measurement.isSkipped ?? false) continue;

                    final limits =
                        kPOSMeasurementLimits[measurement.measurementId];
                    if (limits != null) {
                      double maxLimit = limits.max;
                      double minLimit = limits.min;
                      if (measurement.measurementId == 'temperature' &&
                          widget.indoorTemp != null) {
                        maxLimit = widget.indoorTemp!;
                      }

                      if (measurement.value > maxLimit) {
                        setState(() { _isSaving = false; });
                        _showValidationErrorSnackbar(
                            'Nilai "${limits.label}" melebihi batas.');
                        return;
                      } else if (measurement.value < minLimit) {
                        setState(() { _isSaving = false; });
                        _showValidationErrorSnackbar(
                            'Nilai "${limits.label}" dibawah batas.');
                        return;
                      }
                    }
                  }

                  bloc.add(SavePosValidationData(
                    transNo: widget.transNo,
                    serialNo: latestState.serialNo,
                    markAsCompleted: true,
                    note: _noteController.text,
                    articleNo: widget.articleNo,
                    articleDesc: widget.articleDesc,
                    articleUnitDesc: widget.articleUnitDesc,
                    capacity: widget.capacity,
                    articleType: widget.unitType,
                    indoorTemp: widget.indoorTemp,

                    // 🔥 TERUSKAN KE EVENT SIMPAN
                    isGeneric: widget.isGeneric,
                    unitIndex: widget.unitIndex,
                  ));
                },
                child: _isSaving
                    ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text('Simpan'),
              ),
            ),
          ] else if (state.currentStep == 0) ...[
            Expanded(
              child: ElevatedButton(
                child: const Text('Lanjut'),
                onPressed: () async {
                  final latestState = context.read<PosValidationBloc>().state;
                  if (latestState is! PosValidationLoaded) return;

                  if (latestState.photosBefore.isEmpty) {
                    _showValidationErrorSnackbar(
                        'Foto unit sebelum cuci wajib dilengkapi.');
                    return;
                  }

                  // 🔥 VALIDASI GENERIC SERIAL NUMBER
                  if (widget.isGeneric) {
                    final snUpperCase = latestState.serialNo.trim().toUpperCase();
                    if (snUpperCase.isEmpty || snUpperCase.startsWith('AC')) {
                      _showValidationErrorSnackbar('Serial Number Unit Wajib Diisi/Scan!');
                      return;
                    }

                    // 🔥 LOGIC BARU: CEK DUPLIKAT SN DI HIVE 🔥
                    final box = await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
                    final isDuplicate = box.values.any((entry) {
                      // Cari apakah ada data dengan No Tiket & SN yang sama...
                      return entry.transNo == widget.transNo &&
                          entry.serialNo.toUpperCase() == snUpperCase &&
                          // ...TAPI bukan unit yang sedang dibuka ini (berdasarkan index & tipe)
                          !(entry.unitIndex == widget.unitIndex && entry.articleType == widget.unitType);
                    });

                    if (isDuplicate) {
                      // Blokir jika duplikat!
                      _showValidationErrorSnackbar('Serial Number "$snUpperCase" sudah dipakai di unit lain!');
                      return;
                    }
                  }

                  if (latestState.unitType.toUpperCase() == 'OUT' &&
                      latestState.pairedIndoorSerial == null) {
                    _showValidationErrorSnackbar(
                        'Anda wajib memilih pasangan unit indoor.');
                    return;
                  }

                  // Auto Save Draft saat pindah step
                  bloc.add(SavePosValidationData(
                    transNo: widget.transNo,
                    serialNo: latestState.serialNo,
                    // Gunakan SN terbaru
                    note: _noteController.text,
                    articleNo: widget.articleNo,
                    articleDesc: widget.articleDesc,
                    articleUnitDesc: widget.articleUnitDesc,
                    capacity: widget.capacity,
                    articleType: widget.unitType,
                    isGeneric: widget.isGeneric,
                    // 🔥
                    unitIndex: widget.unitIndex, // 🔥
                  ));

                  bloc.add(const ChangePosValidationStep(1));
                },
              ),
            ),
          ],
        ],
      ),
          ],
        ),
    );
  }
}
