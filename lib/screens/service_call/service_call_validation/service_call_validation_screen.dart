import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/service_call/problem_source_model.dart';
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
  });

  @override
  State<ServiceCallValidationScreen> createState() =>
      _ServiceCallValidationScreenState();
}

class _ServiceCallValidationScreenState
    extends State<ServiceCallValidationScreen> {
  bool _areAllMeasurementsFilled(List<MeasurementEntry> measurements) {
    return measurements.every((m) => m.capturedImage != null);
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
        )),
      child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text("Validasi Service Call")),
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
            // --- BAGIAN BARU: TOMBOL FLOATING ---
            bottomNavigationBar: (state is ValidationDropdownLoaded)
                ? _buildFloatingButtons(context, state)
                : null,
          );
        },
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
                  // Validasi dan Simpan Final
                  if (state.selectedUnitType == null ||
                      state.selectedProblemCards.isEmpty ||
                      state.capturedPhotosAfter.isEmpty ||
                      !_areAllMeasurementsFilled(
                          state.capturedMeasurementsAfter)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Lengkapi semua data & foto (Sesudah Servis)'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                    markAsCompleted: true,
                  ));
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Validasi berhasil disimpan!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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

                  // Kirim event untuk menyimpan, tapi JANGAN pindah step
                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Draft berhasil disimpan'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                  if (state.capturedPhotosBefore.isEmpty ||
                      !_areAllMeasurementsFilled(
                          state.capturedMeasurementsBefore)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Lengkapi semua data & foto untuk melanjutkan'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (state.selectedOutdoorSerialNo == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih Serial No Outdoor'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  bloc.add(SaveValidationData(
                    transNo: widget.transNo,
                    serialNo: widget.serialNo,
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
}
