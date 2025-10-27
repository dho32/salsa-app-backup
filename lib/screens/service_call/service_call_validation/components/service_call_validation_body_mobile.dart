// lib/screens/service_call/service_call_validation/components/service_call_validation_body_mobile.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import 'package:salsa/blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import 'package:salsa/blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import 'package:salsa/models/service_call/problem_source_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import 'package:salsa/screens/service_call/service_call_validation/components/widgets/measurement_input_section.dart';
import 'package:salsa/screens/service_call/service_call_validation/components/widgets/service_call_validation_widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../blocs/auth/auth_storage.dart';
import '../../../../components/constants.dart';
import '../../../../components/widgets/sc_measurement_input_section.dart';
import '../../../../models/common/captured_image_detail.dart';

const List<String> indoorMeasurementIds = ['Suhu'];
const List<String> outdoorMeasurementIds = ['Tegangan', 'Arus', 'Tekanan'];

class ServiceCallValidationBodyMobile extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String lineNo;
  final String assetAge;
  final String rentDate;
  final String leasesEndingDate;
  final String complaintDetails;
  final String imageFile;
  final ServiceCallValidationEntryModel? initialData;

  const ServiceCallValidationBodyMobile({
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
  });

  @override
  State<ServiceCallValidationBodyMobile> createState() =>
      _ServiceCallValidationBodyMobileState();
}

class _ServiceCallValidationBodyMobileState
    extends State<ServiceCallValidationBodyMobile> {
  bool _isTakingUnitPhoto = false;
  final GlobalKey _step1Key = GlobalKey();
  final GlobalKey _step2Key = GlobalKey();

  // Handler untuk mengambil foto
  void _handlePhoto(BuildContext context, ValidationDropdownLoaded state,
      {required bool isBefore}) {
    // Anda bisa letakkan pengecekan awal di sini jika ada (misal cek jumlah foto maks)
    final List<CapturedImageDetail> currentPhotos =
        isBefore ? state.capturedPhotosBefore : state.capturedPhotosAfter;
    if (currentPhotos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal hanya bisa upload 2 foto.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1. Set state untuk menampilkan loading
    setState(() {
      _isTakingUnitPhoto = true;
    });

    _startImageCaptureProcess(context, state, isBefore);
  }

  Future<void> _startImageCaptureProcess(BuildContext context,
      ValidationDropdownLoaded state, bool isBefore) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        // Proses kompresi gambar
        final tempDir = await getTemporaryDirectory();
        final targetPath = p.join(
            tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
        final XFile? compressedImage =
            await FlutterImageCompress.compressAndGetFile(
          image.path, targetPath,
          quality: 70, minWidth: 1080, //ukuran full HD
          minHeight: 1920,
        );

        if (compressedImage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memproses gambar.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        // Proses ambil data GPS
        final timestamp = DateTime.now();
        double latitude = 0.0;
        double longitude = 0.0;
        String address = '';

        // try {
        //   Position position = await Geolocator.getCurrentPosition(
        //     locationSettings:
        //         const LocationSettings(accuracy: LocationAccuracy.high),
        //   );
        //   latitude = position.latitude;
        //   longitude = position.longitude;
        //   List<Placemark> placemarks =
        //       await placemarkFromCoordinates(latitude, longitude);
        //   Placemark place = placemarks.first;
        //   address =
        //       "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        // } catch (e) {
        //   // Handle error GPS
        // }

        final userData = await AuthStorage.getUser();
        final technicianName = userData['name'] ?? 'Unknown';
        final deviceModel = userData['device_model'] ?? 'Unknown Device';

        // Buat detail gambar
        final capturedImageDetail = CapturedImageDetail(
          imagePath: compressedImage.path,
          timestamp: timestamp,
          latitude: latitude,
          longitude: longitude,
          address: address,
          technicianName: technicianName,
          deviceModel: deviceModel,
          transNo: widget.transNo,
        );

        // Kirim event ke BLoC
        if (mounted) {
          final bloc = context.read<ValidationDropdownBloc>();
          if (isBefore) {
            bloc.add(AddCapturedPhotoBefore(capturedImageDetail));
          } else {
            bloc.add(AddCapturedPhotoAfter(capturedImageDetail));
          }
        }
      }
    } finally {
      // Pastikan loading selalu berhenti, apapun yang terjadi
      if (mounted) {
        setState(() {
          _isTakingUnitPhoto = false;
        });
      }
    }
  }

  void _handleAddProblem(BuildContext context) {
    // (Isi fungsi _handleAddProblem Anda yang sudah ada bisa disalin ke sini)
    final bloc = context.read<ValidationDropdownBloc>();
    final state = bloc.state;
    if (state is! ValidationDropdownLoaded) return;

    final problems = state.data
        .firstWhere(
          (e) => e.unitType == state.selectedUnitType,
          orElse: () => ProblemSourceModel(unitType: '', problems: []),
        )
        .problems;

    List<String> existingProblemIds = state.selectedProblemCards
        .map((e) => e.selectedProblemId)
        .whereType<String>()
        .toList();

    showDialogAddProblem(
      context: context,
      problems: problems,
      existingProblemIds: existingProblemIds,
      onAdd: (problemId, solutionIds) {
        bloc.add(
            AddProblemCard(problemId: problemId, solutionIds: solutionIds));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ValidationDropdownBloc, ValidationDropdownState>(
      listenWhen: (previous, current) {
        if (previous is ValidationDropdownLoaded &&
            current is ValidationDropdownLoaded) {
          return previous.currentStep != current.currentStep;
        }
        return false;
      },
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final keyToUse = (state as ValidationDropdownLoaded).currentStep == 0
              ? _step1Key
              : _step2Key;

          final keyContext = keyToUse.currentContext;
          if (keyContext != null) {
            Scrollable.ensureVisible(keyContext,
                duration: const Duration(milliseconds: 300), alignment: 0);
          }
        });
      },
      child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(
        builder: (context, state) {
          if (state is ValidationDropdownLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ValidationDropdownError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          if (state is ValidationDropdownLoaded) {
            return Stepper(
              type: StepperType.horizontal,
              currentStep: state.currentStep,
              onStepTapped: null,
              controlsBuilder: (context, details) {
                return const SizedBox.shrink();
              },
              steps: [
                _buildStep1(context, state),
                _buildStep2(context, state),
              ],
            );
          }
          return const Center(child: Text("Memuat..."));
        },
      ),
    );
  }

  // --- Step 1: SEBELUM SERVIS ---
  Step _buildStep1(BuildContext context, ValidationDropdownLoaded state) {
    return Step(
      title: const Text('Sebelum'),
      isActive: state.currentStep >= 0,
      state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget-widget untuk step 1
              HeaderInfo(
                key: _step1Key,
                transNo: widget.transNo,
                serialNo: widget.serialNo,
                lineNo: widget.lineNo,
                complaintDetails: widget.complaintDetails,
                imageFile: widget.imageFile,
              ),
              buildPhotoSection(context, state,
                  isBefore: true, isLoading: _isTakingUnitPhoto),
              _handleButtonPhotoWidget(context, state, isBefore: true),
              // Tombol ambil foto
              const SizedBox(height: 8),
              ScMeasurementInputSection(
                key: const ValueKey('measurements_before'), // Key tetap penting
                transNo: widget.transNo,
                measurements: state.capturedMeasurementsBefore,
                isBefore: true,
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 2: SESUDAH SERVIS ---
  Step _buildStep2(BuildContext context, ValidationDropdownLoaded state) {
    return Step(
      title: const Text('Sesudah'),
      isActive: state.currentStep >= 1,
      state: StepState.indexed,
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget-widget untuk step 2
              HeaderInfo(
                key: _step2Key,
                transNo: widget.transNo,
                serialNo: widget.serialNo,
                lineNo: widget.lineNo,
                complaintDetails: widget.complaintDetails,
                imageFile: widget.imageFile,
              ),
              buildPhotoSection(context, state,
                  isBefore: false, isLoading: _isTakingUnitPhoto),
              _handleButtonPhotoWidget(context, state, isBefore: false),
              const SizedBox(height: 8),
              ScMeasurementInputSection(
                key: const ValueKey('measurements_after'), // Key tetap penting
                transNo: widget.transNo,
                measurements: state.capturedMeasurementsAfter,
                isBefore: false,
              ),
              const SizedBox(height: 16),
              buildUnitTypeSelector(
                context: context,
                groupValue: state.selectedUnitType,
                onChanged: (value) {
                  if (value != null) {
                    // Kirim event ke BLoC saat ada perubahan
                    context
                        .read<ValidationDropdownBloc>()
                        .add(SelectUnitType(value));
                  }
                },
              ),
              Builder(builder: (context) {
                final problemsForType = state.data
                    .firstWhere((e) => e.unitType == state.selectedUnitType,
                    orElse: () =>
                        ProblemSourceModel(unitType: '', problems: []))
                    .problems;
                return buildProblemCards(
                    context: context,
                    state: state,
                    problemsForType: problemsForType,
                    buttonAdd: _buildButtonAddProblem(state));
              }),
              SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk tombol foto agar tidak duplikat kode
  Widget _handleButtonPhotoWidget(
      BuildContext context, ValidationDropdownLoaded state,
      {required bool isBefore}) {
    final Color primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.camera_alt),
        label: Text('Ambil Foto Unit (${isBefore ? 'Sebelum' : 'Sesudah'})'),
        onPressed: () => _handlePhoto(context, state, isBefore: isBefore),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
          side: BorderSide(color: primary),
          foregroundColor: primary,
        ),
      ),
    );
  }

  // Helper untuk tombol tambah masalah
  Widget _buildButtonAddProblem(ValidationDropdownLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Permasalahan & Solusi'),
        onPressed: () => _handleAddProblem(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }
}
