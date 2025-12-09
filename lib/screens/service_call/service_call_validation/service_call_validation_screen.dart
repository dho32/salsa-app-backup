import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/models/common/measurement_limits.dart';
import 'package:salsa/screens/service_call/service_call_validation/components/invalid_unit_screen/sc_invalid_unit_screen.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../components/constants.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/common/note_option.dart';
import '../../../models/service_call/problem_source_model.dart';
import '../../../models/service_call/service_call_detail_model.dart';
import '../../../models/service_call/service_call_validation_entry_model.dart';
import 'components/service_call_validation_body_mobile.dart';

class ServiceCallValidationScreen extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String? displaySerialNo;
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
    this.displaySerialNo,
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
  late final Map<String, MeasurementLimits> _limitsScBefore;
  late final Map<String, MeasurementLimits> _limitsScAfter;

  bool checkMeasurementDetails(List<MeasurementEntry> measurements) {
    bool allItemsPassed = true;
    for (int i = 0; i < measurements.length; i++) {
      var m = measurements[i];
      bool isSkippedCheck = m.isSkipped ?? false;
      bool isFilledCheck = (m.capturedImage != null && m.value != 0);
      bool didPass = isSkippedCheck || isFilledCheck;
      if (!didPass) {
        allItemsPassed = false;
      }
    }
    return allItemsPassed;
  }

  @override
  void initState() {
    super.initState();
    final configBox = Hive.box(kAppConfigBox);

    final rawBefore = configBox.get('limits_sc_before');
    final Map<String, MeasurementLimits> limitsBeforeMap = {};
    if (rawBefore is Map) {
      rawBefore.forEach((key, value) {
        if (key is String && value is MeasurementLimits) {
          limitsBeforeMap[key] = value;
        }
      });
    }
    _limitsScBefore = limitsBeforeMap.isNotEmpty
        ? limitsBeforeMap
        : kSCMeasurementLimitsBefore;

    final rawAfter = configBox.get('limits_sc_after');
    final Map<String, MeasurementLimits> limitsAfterMap = {};
    if (rawAfter is Map) {
      rawAfter.forEach((key, value) {
        if (key is String && value is MeasurementLimits) {
          limitsAfterMap[key] = value;
        }
      });
    }
    _limitsScAfter =
        limitsAfterMap.isNotEmpty ? limitsAfterMap : kMeasurementLimits;
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
          limitsScBefore: _limitsScBefore,
          limitsScAfter: _limitsScAfter,
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
            bool isSaving = false;
            if (state is ValidationDropdownLoaded) {
              isSaving = state.saveStatus == ValidationSaveStatus.saving;
            }

            final currentSerial = (state is ValidationDropdownLoaded &&
                    state.correctSerialNo != null)
                ? state.correctSerialNo!
                : (widget.displaySerialNo ?? widget.serialNo);

            return Stack(
              children: [
                Scaffold(
                  appBar: AppBar(
                    title: const Text(" "),
                    actions: [
                      if (state is ValidationDropdownLoaded)
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 12.0, top: 8, bottom: 8),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text(
                              "Tukar Unit",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red.shade900,
                              backgroundColor: Colors.white,
                              elevation: 2,
                              shape: const StadiumBorder(),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: const Size(0, 35),
                            ),
                            // Disable jika sedang saving
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final bloc =
                                        context.read<ValidationDropdownBloc>();
                                    List<String> swapOptions = widget
                                        .detailData.indoorAvailable
                                        .map((e) => e.serialNo)
                                        .toList();

                                    swapOptions.remove(currentSerial);

                                    // --- 3. FILTER SERIAL YANG DIPAKAI UNIT LAIN YANG SUDAH DIPAKAI ------
                                    final box = Hive.box<
                                            ServiceCallValidationEntryModel>(
                                        kServiceCallHiveBox);

                                    // Ambil semua serial number yang SUDAH diambil oleh unit lain sebagai 'correctSerialNo'
                                    final usedByOthers = box.values
                                        .where((e) =>
                                            e.transNo ==
                                                widget
                                                    .transNo && // Transaksi sama
                                            e.serialNo !=
                                                widget
                                                    .serialNo && // Unit lain (bukan unit ini)
                                            e.correctSerialNo !=
                                                null && // Ada data swap
                                            e.correctSerialNo!.isNotEmpty)
                                        .map((e) => e.correctSerialNo!)
                                        .toSet();

                                    // Hapus dari opsi jika sudah dipakai tetangga
                                    swapOptions.removeWhere((serial) =>
                                        usedByOthers.contains(serial));

                                    if (currentSerial != widget.serialNo) {
                                      if (!swapOptions
                                          .contains(widget.serialNo)) {
                                        swapOptions.add(widget.serialNo);
                                      }
                                    }

                                    swapOptions.sort();

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: bloc,
                                          child: ScInvalidUnitScreen(
                                            transNo: widget.transNo,
                                            ticketSerialNo: widget.serialNo,
                                            currentSerialNo: currentSerial,
                                            swapOptions: swapOptions,
                                          ),
                                        ),
                                      ),
                                    );

                                    // 3. Cek hasil kembalian
                                    // Jika result == true (berarti sukses swap), tutup halaman Validasi ini juga
                                    if (result == true && context.mounted) {
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                          ),
                        ),
                    ],
                  ),
                  body: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: AbsorbPointer(
                      absorbing: isSaving,
                      child: ServiceCallValidationBodyMobile(
                        transNo: widget.transNo,
                        serialNo: widget.serialNo,
                        displaySerialNo: currentSerial,
                        lineNo: widget.lineNo,
                        assetAge: widget.assetAge,
                        rentDate: widget.rentDate,
                        leasesEndingDate: widget.leasesEndingDate,
                        initialData: widget.initialData,
                        complaintDetails: widget.complaintDetails,
                        imageFile: widget.imageFile,
                      ),
                    ),
                  ),
                  bottomNavigationBar: (state is ValidationDropdownLoaded)
                      ? AbsorbPointer(
                          // Disable tombol bawah saat saving
                          absorbing: isSaving,
                          child: _buildFloatingButtons(context, state),
                        )
                      : null,
                ),
              ],
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
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          if (state.currentStep == 1) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => bloc.add(const ChangeValidationStep(0)),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primary),
                  foregroundColor: primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 200));

                  final measurementError = _validateMeasurements(
                    state.capturedMeasurementsAfter,
                    state.limitsScAfter,
                  );

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
          ] else if (state.currentStep == 0) ...[
            // Expanded(
            //   child: OutlinedButton.icon(
            //     onPressed: () async {
            //       FocusScope.of(context).unfocus();
            //       await Future.delayed(const Duration(milliseconds: 200));
            //
            //       bool hasDataToSave = state.capturedPhotosBefore.isNotEmpty ||
            //           state.capturedMeasurementsBefore
            //               .any((m) => m.value != 0.0);
            //
            //       if (!hasDataToSave) {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(
            //             content: Text('Belum ada data untuk disimpan'),
            //             backgroundColor: Colors.orange,
            //             behavior: SnackBarBehavior.floating,
            //           ),
            //         );
            //         return;
            //       }
            //
            //       final measurementError = _validateMeasurements(
            //         state.capturedMeasurementsBefore,
            //         state.limitsScBefore,
            //       );
            //       if (measurementError != null) {
            //         _showErrorSnackbar(measurementError);
            //         return;
            //       }
            //
            //       bloc.add(SaveValidationData(
            //         transNo: widget.transNo,
            //         serialNo: widget.serialNo,
            //         showNotification: true,
            //       ));
            //     },
            //     label: const Text('Simpan Draft'),
            //     style: OutlinedButton.styleFrom(
            //       side: BorderSide(color: primary),
            //       foregroundColor: primary,
            //     ),
            //   ),
            // ),
            // const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 200));

                  if (state.capturedPhotosBefore.isEmpty) {
                    _showErrorSnackbar('Lengkapi semua foto unit (Sebelum).');
                    return;
                  }
                  if (state.selectedOutdoorSerialNo == null) {
                    _showErrorSnackbar('Pilih Serial No Outdoor.');
                    return;
                  }

                  final noteError = _validateNotes(state, isBefore: true);
                  if (noteError != null) {
                    _showErrorSnackbar(noteError);
                    return;
                  }

                  final measurementError = _validateMeasurements(
                    state.capturedMeasurementsBefore,
                    state.limitsScBefore,
                  );

                  if (measurementError != null) {
                    _showErrorSnackbar(measurementError);
                    return;
                  }

                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    showNotification: false,
                  ));
                  bloc.add(const ChangeValidationStep(1));
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

    // Definisi Group ID
    const indoorIds = {'temperature'};
    const outdoorElecIds = {'volt', 'ampere'};
    const outdoorPsiIds = {'psi'};

    // Helper Validasi Per Grup
    String? checkGroup({
      required Set<String> ids,
      required List<NoteOption> options,
      required String? selectedNoteLabel,
      required String groupName,
      required NoteType noteType,
    }) {
      // 1. Cek apakah ada item di grup ini yang di-skip
      final skippedItems = measurements
          .where((m) => ids.contains(m.measurementId) && (m.isSkipped ?? false))
          .toList();

      if (skippedItems.isNotEmpty) {
        // 2. Cek apakah Note sudah dipilih
        if (selectedNoteLabel == null || selectedNoteLabel.isEmpty) {
          return 'Catatan $groupName wajib diisi jika ada pengukuran yang di-skip.';
        }

        // 3. Cek apakah Note ini butuh Remark (Keterangan Tambahan)
        if (!isBefore) {
          final selectedOptionObj = options.firstWhere(
              (o) => o.label == selectedNoteLabel,
              orElse: () => NoteOption(label: '', requireRemark: false));

          if (selectedOptionObj.requireRemark) {
            final firstSkipped = skippedItems.first;
            final remarkText = firstSkipped.remark ?? '';
            if (firstSkipped.remark == null ||
                firstSkipped.remark!.trim().isEmpty) {
              return 'Keterangan Tambahan untuk $groupName wajib diisi.';
            }
            final int charCount = remarkText.replaceAll(' ', '').length;
            if (charCount < 20) {
              return 'Keterangan $groupName minimal 20 huruf (tanpa spasi). Saat ini: $charCount.';
            }
            final photos = state.remarkPhotosAfter[noteType] ?? [];
            if (photos.isEmpty) {
              return 'Wajib melampirkan minimal 1 foto untuk Remark $groupName.';
            }
          }
        }
      }
      return null;
    }

    // Validasi Indoor
    final indoorError = checkGroup(
      ids: indoorIds,
      options: isBefore
          ? state.noteIndoorBeforeOptions
          : state.noteIndoorAfterOptions,
      selectedNoteLabel: isBefore
          ? state.selectedIndoorNoteBefore
          : state.selectedIndoorNoteAfter,
      groupName: 'Indoor',
      noteType: NoteType.indoor,
    );
    if (indoorError != null) return indoorError;

    // Validasi Outdoor
    final outdoorError = checkGroup(
      ids: outdoorElecIds,
      options: isBefore
          ? state.noteOutdoorBeforeOptions
          : state.noteOutdoorAfterOptions,
      selectedNoteLabel: isBefore
          ? state.selectedOutdoorNoteBefore
          : state.selectedOutdoorNoteAfter,
      groupName: 'Outdoor (Volt/Ampere)',
      noteType: NoteType.outdoor,
    );
    if (outdoorError != null) return outdoorError;

    // Validasi PSI
    final psiError = checkGroup(
      ids: outdoorPsiIds,
      options: isBefore
          ? state.noteOutdoorPsiBeforeOptions
          : state.noteOutdoorPsiAfterOptions,
      selectedNoteLabel: isBefore
          ? state.selectedOutdoorPSINoteBefore
          : state.selectedOutdoorPSINoteAfter,
      groupName: 'Outdoor (Tekanan)',
      noteType: NoteType.outdoorPsi,
    );
    if (psiError != null) return psiError;

    return null; // Lolos Semua
  }

  String? _validateMeasurements(
    List<MeasurementEntry> measurements,
    Map<String, MeasurementLimits> limitsMap,
  ) {
    for (final mEntry in measurements) {
      if (mEntry.isSkipped ?? false) continue;
      final label =
          limitsMap[mEntry.measurementId]?.label ?? mEntry.measurementId;
      if (mEntry.capturedImage == null) {
        return 'Foto untuk "$label" wajib diisi.';
      }
      if (mEntry.value == 0.0) {
        return 'Nilai untuk "$label" wajib diisi.';
      }
      final limits = limitsMap[mEntry.measurementId];
      if (limits == null) continue;
      if (mEntry.value < limits.min || mEntry.value > limits.max) {
        return 'Nilai untuk "${limits.label}" (${mEntry.value}) di luar batas wajar (Min: ${limits.min}, Maks: ${limits.max}).';
      }
    }
    return null;
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
