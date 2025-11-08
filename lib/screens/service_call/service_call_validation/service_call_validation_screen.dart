import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../components/constants.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../../../models/service_call/problem_source_model.dart';
import '../../../models/service_call/service_call_detail_model.dart';
import '../../../models/service_call/service_call_validation_entry_model.dart';
import 'components/service_call_validation_body_mobile.dart';

class ServiceCallValidationScreen extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String lineNo;
  final String assetAge;
  final String rentDate;
  final String leasesEndingDate;
  final String complaintDetails;
  final String imageFile;
  final ServiceCallValidationEntryModel? initialData;
  final List<String> allAvailableOutdoorSerials;
  final List<ProblemSourceModel> problemSources;
  final ServiceCallDetailModel detailData;

  const ServiceCallValidationScreen({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.lineNo,
    required this.assetAge,
    required this.rentDate,
    required this.leasesEndingDate,
    required this.complaintDetails,
    required this.imageFile,
    this.initialData,
    required this.allAvailableOutdoorSerials,
    required this.problemSources,
    required this.detailData,
  });

  @override
  State<ServiceCallValidationScreen> createState() =>
      _ServiceCallValidationScreenState();
}

class _ServiceCallValidationScreenState
    extends State<ServiceCallValidationScreen> {
  bool checkMeasurementDetails(List<MeasurementEntry> measurements) {
    // 1. Kita mulai dengan asumsi semuanya LOLOS
    bool allItemsPassed = true;

    for (int i = 0; i < measurements.length; i++) {
      var m = measurements[i];

      // Evaluasi logika
      bool isSkippedCheck = m.isSkipped ?? false;
      bool isFilledCheck = (m.capturedImage != null && m.value != 0);
      bool didPass = isSkippedCheck || isFilledCheck;

      if (didPass) {
        print('>>> Status: LOLOS');
      } else {
        print('>>> !!! STATUS: GAGAL !!! <<<');
        print(
            'Alasan Gagal: isSkipped bukan true DAN (gambar/nilai tidak lengkap)');

        // 2. Jika SATU SAJA gagal, tandai hasil akhirnya sebagai 'false'
        allItemsPassed = false;
      }
    }

    // 3. Kembalikan hasil akhir
    return allItemsPassed;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ValidationDropdownBloc()
        ..add(FetchValidationDropdownData(
          initialData: widget.initialData,
          transNo: widget.transNo,
          currentIndoorSerial: widget.serialNo,
          allAvailableOutdoorSerials: widget.allAvailableOutdoorSerials,
          problemSources: widget.problemSources,
          detailData: widget.detailData,
        )),
      child: BlocListener<ValidationDropdownBloc, ValidationDropdownState>(
        listenWhen: (prev, current) =>
            prev is ValidationDropdownLoaded &&
            current is ValidationDropdownLoaded &&
            prev.saveStatus != current.saveStatus,
        listener: (context, state) {
          if (state is ValidationDropdownLoaded) {
            if (state.saveStatus == ValidationSaveStatus.successFinal) {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.saveMessage ?? 'Berhasil!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.saveStatus == ValidationSaveStatus.successDraft) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.saveMessage ?? 'Draft disimpan!'),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.saveStatus == ValidationSaveStatus.error) {
              _showErrorSnackbar(state.saveMessage ?? 'Gagal menyimpan data');
            }
          }
        },
        child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Validasi Service Call"),
              ),
              body: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ServiceCallValidationBodyMobile(
                  transNo: widget.transNo,
                  serialNo: widget.serialNo,
                  lineNo: widget.lineNo,
                  assetAge: widget.assetAge,
                  rentDate: widget.rentDate,
                  leasesEndingDate: widget.leasesEndingDate,
                  initialData: widget.initialData,
                  complaintDetails: widget.complaintDetails,
                  imageFile: widget.imageFile,
                ),
              ),
              bottomNavigationBar: (state is ValidationDropdownLoaded)
                  ? _buildFloatingButtons(context, state)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(
      BuildContext context, ValidationDropdownLoaded state) {
    final bloc = context.read<ValidationDropdownBloc>();
    final Color primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Tampilan saat di Step 2 (Sesudah)
          if (state.currentStep == 1) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => bloc.add(ChangeValidationStep(0)),
                label: Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primary), // warna border
                  foregroundColor:
                      primary, // ini juga bisa bantu untuk label/icon
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  // --- Validasi "Sesudah" ---
                  final measurementError = _validateMeasurements(
                      state.capturedMeasurementsAfter, kMeasurementLimits);
                  if (measurementError != null) {
                    _showErrorSnackbar(measurementError);
                    return;
                  }

                  if (state.capturedPhotosAfter.isEmpty ||
                      !checkMeasurementDetails(
                          state.capturedMeasurementsAfter)) {
                    _showErrorSnackbar(
                        'Lengkapi semua foto & pengukuran (Sesudah).');
                    return;
                  }

                  // Validasi Note "Sesudah"
                  final noteError = _validateNotes(state, isBefore: false);
                  if (noteError != null) {
                    _showErrorSnackbar(noteError);
                    return;
                  }

                  if (state.selectedUnitType == null ||
                      state.selectedProblemCards.isEmpty) {
                    _showErrorSnackbar('Lengkapi data Permasalahan & Solusi.');
                    return;
                  }

                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    markAsCompleted: true,
                  ));
                },
                child: const Text('Simpan'),
              ),
            ),
          ]

          // Tampilan saat di Step 1 (Sebelum)
          else if (state.currentStep == 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  bool hasDataToSave = state.capturedPhotosBefore.isNotEmpty ||
                      state.capturedMeasurementsBefore
                          .any((m) => m.value != 0.0);

                  if (!hasDataToSave) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belum ada data untuk disimpan'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final measurementError = _validateMeasurements(
                      state.capturedMeasurementsBefore,
                      kSCMeasurementLimitsBefore);
                  if (measurementError != null) {
                    _showErrorSnackbar(measurementError);
                    return;
                  }

                  // Kirim event untuk menyimpan, tapi JANGAN pindah step
                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    showNotification: true,
                  ));
                },
                label: Text('Simpan Draft'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primary), // warna border
                  foregroundColor:
                      primary, // ini juga bisa bantu untuk label/icon
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (state.capturedPhotosBefore.isEmpty) {
                    _showErrorSnackbar('Lengkapi semua foto unit (Sebelum).');
                    return;
                  }
                  if (state.selectedOutdoorSerialNo == null) {
                    _showErrorSnackbar('Pilih Serial No Outdoor.');
                    return;
                  }
                  // Validasi Note "Sebelum"
                  final noteError = _validateNotes(state, isBefore: true);
                  if (noteError != null) {
                    _showErrorSnackbar(noteError);
                    return;
                  }

                  final measurementError = _validateMeasurements(
                      state.capturedMeasurementsBefore,
                      kSCMeasurementLimitsBefore);
                  if (measurementError != null) {
                    _showErrorSnackbar(measurementError);
                    return;
                  }

                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    showNotification: false,
                  ));
                  bloc.add(ChangeValidationStep(1));
                },
                child: const Text('Lanjut'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _validateNotes(ValidationDropdownLoaded state,
      {required bool isBefore}) {
    final measurements = isBefore
        ? state.capturedMeasurementsBefore
        : state.capturedMeasurementsAfter;

    const indoorIds = {'temperature'};
    const outdoorElecIds = {'volt', 'ampere'};
    const outdoorPsiIds = {'psi'};

    // Cek Indoor
    final bool isAnyIndoorSkipped = measurements.any(
        (m) => indoorIds.contains(m.measurementId) && (m.isSkipped ?? false));
    final String? indoorNote = isBefore
        ? state.selectedIndoorNoteBefore
        : state.selectedIndoorNoteAfter;
    if (isAnyIndoorSkipped && (indoorNote == null || indoorNote.isEmpty)) {
      return 'Catatan indoor wajib diisi jika ada pengukuran yang di-skip.';
    }

    // Cek Outdoor Elektrikal
    final bool isAnyOutdoorSkipped = measurements.any((m) =>
        outdoorElecIds.contains(m.measurementId) && (m.isSkipped ?? false));
    final String? outdoorNote = isBefore
        ? state.selectedOutdoorNoteBefore
        : state.selectedOutdoorNoteAfter;
    if (isAnyOutdoorSkipped && (outdoorNote == null || outdoorNote.isEmpty)) {
      return 'Catatan outdoor (Volt/Ampere) wajib diisi.';
    }

    // Cek Outdoor PSI
    final bool isAnyOutdoorPsiSkipped = measurements.any((m) =>
        outdoorPsiIds.contains(m.measurementId) && (m.isSkipped ?? false));
    final String? outdoorPsiNote = isBefore
        ? state.selectedOutdoorPSINoteBefore
        : state.selectedOutdoorPSINoteAfter;
    if (isAnyOutdoorPsiSkipped &&
        (outdoorPsiNote == null || outdoorPsiNote.isEmpty)) {
      return 'Catatan outdoor (PSI) wajib diisi.';
    }

    return null; // Semua valid
  }

  String? _validateMeasurements(
    List<MeasurementEntry> measurements,
    Map<String, MeasurementLimits> limitsMap,
  ) {
    for (final mEntry in measurements) {
      // 1. Jika di-skip, lewati ke pengukuran berikutnya (dianggap valid)
      if (mEntry.isSkipped ?? false) continue;

      // 2. Jika tidak di-skip, periksa kelengkapan
      if (mEntry.capturedImage == null) {
        final label =
            limitsMap[mEntry.measurementId]?.label ?? mEntry.measurementId;
        return 'Foto untuk "$label" wajib diisi.';
      }
      // Kita anggap 0.0 adalah default (kosong)
      if (mEntry.value == 0.0) {
        final label =
            limitsMap[mEntry.measurementId]?.label ?? mEntry.measurementId;
        return 'Nilai untuk "$label" wajib diisi.';
      }

      // 3. Jika lengkap, periksa rentang nilainya
      final limits = limitsMap[mEntry.measurementId];
      if (limits == null) continue;

      if (mEntry.value < limits.min || mEntry.value > limits.max) {
        return 'Nilai untuk "${limits.label}" (${mEntry.value}) di luar batas wajar.';
      }
    }
    return null; // Semua valid
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
