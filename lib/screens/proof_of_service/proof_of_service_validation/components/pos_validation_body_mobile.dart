// pos_validation_body_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_state.dart';
import '../../../../components/widgets/generic_measurement_input_section.dart';
import '../../../../components/widgets/photo_grid.dart';
import '../../../../models/common/measurement_entry.dart';

class PosValidationBodyMobile extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String unitType;
  final String articleDesc;
  final String articleUnitDesc;
  final TextEditingController noteController;
  final double? indoorTemp;
  final List<String> noteOptions;

  const PosValidationBodyMobile({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.unitType,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.noteController,
    required this.indoorTemp,
    required this.noteOptions,
  });

  @override
  State<PosValidationBodyMobile> createState() =>
      _PosValidationBodyMobileState();
}

class _PosValidationBodyMobileState extends State<PosValidationBodyMobile> {
  bool _isTakingPhoto = false;
  final Map<String, TextEditingController> _controllers = {};
  String labelUnitIndoor = "Foto Unit Indoor & Evaporator";
  String labelUnitOutdoor = "Foto Unit Outdoor & Kondensor";
  String labelUnit = "";

  @override
  void initState() {
    super.initState();
    if (widget.unitType.toUpperCase() == 'IN') {
      labelUnit = labelUnitIndoor;
    } else if (widget.unitType.toUpperCase() == 'OUT') {
      labelUnit = labelUnitOutdoor;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers(List<MeasurementEntry> measurements) {
    // Hapus controller lama untuk mencegah memory leak
    _disposeControllers();

    for (var measurement in measurements) {
      final valueText =
      measurement.value == measurement.value.truncateToDouble()
          ? measurement.value.truncate().toString()
          : measurement.value.toStringAsFixed(1);

      _controllers[measurement.measurementId] =
          TextEditingController(text: valueText == "0" ? "" : valueText);
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _handlePhoto(BuildContext context,
      {required bool isBefore}) async {
    final currentState = context.read<PosValidationBloc>().state;
    if (currentState is PosValidationLoaded) {
      final photoList =
      isBefore ? currentState.photosBefore : currentState.photosAfter;
      if (photoList.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal hanya bisa upload 2 foto.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isTakingPhoto = true);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final tempDir = await getTemporaryDirectory();
      final targetPath =
      p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      final compressFuture = FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1920,
      );

      final results = await Future.wait([compressFuture]);
      final XFile? compressedImage = results[0];
      if (compressedImage == null) return;
      final userData = await AuthStorage.getUser();
      final capturedImageDetail = CapturedImageDetail(
        imagePath: compressedImage.path,
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
        address: "",
        technicianName: userData['name'] ?? 'Unknown',
        deviceModel: userData['device_model'] ?? 'Unknown Device',
        transNo: widget.transNo,
      );

      if (!mounted) return;
      final bloc = context.read<PosValidationBloc>();
      if (isBefore) {
        bloc.add(AddPhotoBefore(capturedImageDetail));
      } else {
        bloc.add(AddPhotoAfter(capturedImageDetail));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTakingPhoto = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<PosValidationBloc, PosValidationState>(
      listener: (context, state) {
        if (state is PosValidationLoaded) {
          // Setiap kali BLoC memuat data, kita buat ulang controllernya
          // setState dipanggil agar UI tahu ada controller baru
          setState(() {
            _initializeControllers(state.measurementsAfter);
          });
        }
      },
      child: BlocBuilder<PosValidationBloc, PosValidationState>(
        builder: (context, state) {
          if (state is PosValidationLoading || state is PosValidationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PosValidationError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          if (state is PosValidationLoaded) {
            // Safety check: Jangan tampilkan UI sebelum controller siap
            if (_controllers.length != state.measurementsAfter.length) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stepper(
              type: StepperType.horizontal,
              currentStep: state.currentStep,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: [
                _buildStep1(context, state),
                _buildStep2(context, state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Step _buildStep1(BuildContext context, PosValidationLoaded state) {
    return Step(
      title: const Text('Sebelum'),
      isActive: state.currentStep >= 0,
      content: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildValidationHeader(),
            if (state.unitType.toUpperCase() == 'OUT')
              _buildIndoorPairingDropdown(context, state),
            buildPhotoSection(
              context: context,
              title: '$labelUnit Sebelum Perawatan',
              photos: state.photosBefore,
              isLoading: _isTakingPhoto,
              isBefore: true,
              onAddPhoto: () => _handlePhoto(context, isBefore: true),
              onRemovePhoto: (path) => context
                  .read<PosValidationBloc>()
                  .add(RemovePhotoBefore(path)),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2(BuildContext context, PosValidationLoaded state) {
    final bool isAnyMeasurementSkipped = state.measurementsAfter.any((m) => m.isSkipped);
    return Step(
      title: const Text('Sesudah'),
      isActive: state.currentStep >= 1,
      content: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildValidationHeader(),
            if (state.unitType.toUpperCase() == 'OUT' &&
                state.pairedIndoorSerial != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Dipasangkan dengan Indoor: ',
                            style: TextStyle(color: Colors.grey.shade800),
                            children: [
                              TextSpan(
                                text: state.pairedIndoorSerial!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            buildPhotoSection(
              context: context,
              title: '$labelUnit Sesudah Perawatan',
              photos: state.photosAfter,
              isLoading: _isTakingPhoto,
              isBefore: false,
              onAddPhoto: () => _handlePhoto(context, isBefore: false),
              onRemovePhoto: (path) =>
                  context.read<PosValidationBloc>().add(RemovePhotoAfter(path)),
            ),
            const SizedBox(height: 8),
            GenericMeasurementInputSection(
              key: ValueKey(widget.unitType),
              controllers: _controllers,
              transNo: widget.transNo,
              measurements: state.measurementsAfter,
              indoorTemp: widget.indoorTemp,
              onUpdate: (measurement) {
                context
                    .read<PosValidationBloc>()
                    .add(UpdateMeasurementAfter(measurement));
              },
            ),
            if(isAnyMeasurementSkipped)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: DropdownButtonFormField<String>(
                  value: widget.noteController.text.isNotEmpty
                      ? widget.noteController.text
                      : null,
                  hint: const Text('Note wajib dipilih jika tidak dapat diukur'),
                  isExpanded: true,
                  items: widget.noteOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    widget.noteController.text = newValue ?? '';
                  },
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  validator: (value) {
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildPhotoSection({
    required BuildContext context,
    required String title,
    required List<CapturedImageDetail> photos,
    required bool isLoading,
    required bool isBefore,
    required VoidCallback onAddPhoto,
    required ValueChanged<String> onRemovePhoto,
  }) {
    final Color primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildPhotoGrid(context, photos,
                isLoading: isLoading, onRemovePhoto: onRemovePhoto),
          ),
        isLoading
            ? const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ))
            : Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(title),
            onPressed: onAddPhoto,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              side: BorderSide(color: primary),
              foregroundColor: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.articleDesc,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.ac_unit, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    widget.articleUnitDesc,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    widget.serialNo,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndoorPairingDropdown(
      BuildContext context, PosValidationLoaded state) {
    List<DropdownMenuItem<String>> items = state.availableIndoorSerials
        .map((serial) => DropdownMenuItem(
      value: serial,
      child: Text(serial),
    ))
        .toList();

    if (state.pairedIndoorSerial != null &&
        !state.availableIndoorSerials.contains(state.pairedIndoorSerial)) {
      items.insert(
          0,
          DropdownMenuItem(
            value: state.pairedIndoorSerial,
            child: Text(state.pairedIndoorSerial!),
          ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pasangkan dengan Unit Indoor (*Wajib diisi)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: state.pairedIndoorSerial,
            hint: const Text('Pilih Serial No. Indoor'),
            isExpanded: true,
            items: items,
            onChanged: (newValue) {
              context.read<PosValidationBloc>().add(
                PairOutdoorWithIndoor(
                  outdoorSerialNo: widget.serialNo,
                  indoorSerialNo: newValue,
                ),
              );
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}