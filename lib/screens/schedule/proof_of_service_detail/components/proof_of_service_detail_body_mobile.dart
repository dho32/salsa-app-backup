// lib/screens/proof_of_service_detail/components/proof_of_service_detail_body_mobile.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../blocs/schedule/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../../components/constants.dart';
import '../../../../components/widgets/measurement_input_widget.dart';

class ProofOfServiceDetailBodyMobile extends StatefulWidget {
  final String unitType;

  const ProofOfServiceDetailBodyMobile({super.key, required this.unitType});

  @override
  State<ProofOfServiceDetailBodyMobile> createState() =>
      _ProofOfServiceDetailBodyMobileState();
}

class _ProofOfServiceDetailBodyMobileState
    extends State<ProofOfServiceDetailBodyMobile> {
  // Controller untuk setiap field
  final _tempCtrl = TextEditingController();
  final _voltCtrl = TextEditingController();
  final _ampereCtrl = TextEditingController();
  final _psiCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _tempCtrl.dispose();
    _voltCtrl.dispose();
    _ampereCtrl.dispose();
    _psiCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _dispatchUpdateEvent() {
    final currentState = context.read<ProofOfServiceDetailBloc>().state;
    if (currentState is ProofOfServiceDetailLoaded) {
      // Buat objek data baru dari nilai controller
      final newData = currentState.inputData.copyWith(
        note: _noteCtrl.text,
        temperature: _tempCtrl.text,
        volt: _voltCtrl.text,
        ampere: _ampereCtrl.text,
        psi: _psiCtrl.text,
      );
      // Kirim event ke BLoC
      context
          .read<ProofOfServiceDetailBloc>()
          .add(UpdateProofOfServiceDetail(newData));
    }
  }

  // Helper untuk ambil foto
  Future<void> _pickImage() async {
    final currentState = context.read<ProofOfServiceDetailBloc>().state;
    if (currentState is ProofOfServiceDetailLoaded) {
      if (currentState.inputData.imagePaths.length >= 5) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Maksimal 5 foto.')));
        return;
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final updatedPaths =
            List<String>.from(currentState.inputData.imagePaths)
              ..add(pickedFile.path);
        final newData =
            currentState.inputData.copyWith(imagePaths: updatedPaths);
        context
            .read<ProofOfServiceDetailBloc>()
            .add(UpdateProofOfServiceDetail(newData));
      }
    }
  }

  //Method untuk menghapus foto
  void _removeImage(int index) {
    final currentState = context.read<ProofOfServiceDetailBloc>().state;
    if (currentState is ProofOfServiceDetailLoaded) {
      final updatedPaths = List<String>.from(currentState.inputData.imagePaths)
        ..removeAt(index);
      final newData = currentState.inputData.copyWith(imagePaths: updatedPaths);
      context
          .read<ProofOfServiceDetailBloc>()
          .add(UpdateProofOfServiceDetail(newData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProofOfServiceDetailBloc, ProofOfServiceDetailState>(
      listener: (context, state) {
        if (!mounted) return;
        if (state is ProofOfServiceDetailLoaded) {
          // Isi controller dengan data dari state
          _noteCtrl.text = state.inputData.note;
          _tempCtrl.text = state.inputData.temperature;
          _voltCtrl.text = state.inputData.volt;
          _ampereCtrl.text = state.inputData.ampere;
          _psiCtrl.text = state.inputData.psi;
        }
      },
      builder: (context, state) {
        if (state is ProofOfServiceDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProofOfServiceDetailLoaded) {
          final bool isIndoor = widget.unitType.contains('IN');

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildHeader(context, state),
                      const SizedBox(height: 8),
                      if (isIndoor)
                        _buildIndoorForm(context, state)
                      else
                        _buildOutdoorForm(context, state),
                      _buildNoteSection(context, state),
                      const SizedBox(height: 16),
                      _buildPhotoSection(context, state),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                  color: Colors.transparent,
                  child: ElevatedButton(
                    onPressed: _onSaveButtonPressed,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Simpan'),
                  ),
                ),
              ),
            ],
          );
        }
        return const Center(child: Text("Memuat data..."));
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProofOfServiceDetailLoaded state) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state.unitInfo.articleNameUnit,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(state.unitInfo.serialNo,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(state.unitInfo.description),
        ],
      ),
    );
  }

  Widget _buildIndoorForm(
      BuildContext context, ProofOfServiceDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            'Pengukuran Suhu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8, left: 16, right: 16),
          child: MeasurementInputWidget(
            controller: _tempCtrl,
            transNo: '',
            label: 'Suhu',
            keyboardType: TextInputType.number,
            limits: kMeasurementLimits['temperature']!,
            onChanged: (_) => _dispatchUpdateEvent(),
          ),
        ),
      ],
    );
  }

  Widget _buildOutdoorForm(
      BuildContext context, ProofOfServiceDetailLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            'Pengukuran Listrik & Tekanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(bottom: 16.0, top: 8, left: 16, right: 16),
          child: Column(
            children: [
              MeasurementInputWidget(
                controller: _voltCtrl,
                transNo: '',
                label: 'Volt',
                keyboardType: TextInputType.number,
                limits: kMeasurementLimits['volt']!,
                onChanged: (_) => _dispatchUpdateEvent(),
              ),
              const SizedBox(height: 16),
              MeasurementInputWidget(
                controller: _ampereCtrl,
                transNo: '',
                label: 'Ampere',
                keyboardType: TextInputType.number,
                limits: kMeasurementLimits['ampere']!,
                onChanged: (_) => _dispatchUpdateEvent(),
              ),
              const SizedBox(height: 16),
              MeasurementInputWidget(
                transNo: '',
                controller: _psiCtrl,
                label: 'PSI',
                keyboardType: TextInputType.number,
                limits: kMeasurementLimits['psi']!,
                onChanged: (_) => _dispatchUpdateEvent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(
      BuildContext context, ProofOfServiceDetailLoaded state) {
    final imagePaths = state.inputData.imagePaths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            'Bukti Foto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: imagePaths.length + (imagePaths.length < 5 ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              // Jika ini adalah item terakhir DAN belum mencapai maks, tampilkan tombol Add
              if (index == imagePaths.length && imagePaths.length < 5) {
                return InkWell(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                        child: Icon(Icons.add_a_photo_outlined,
                            size: 40, color: Colors.grey)),
                  ),
                );
              }
              // Tampilkan thumbnail gambar
              final path = imagePaths[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removeImage(index),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildNoteSection(
      BuildContext context, ProofOfServiceDetailLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _noteCtrl,
        decoration: const InputDecoration(
            labelText: 'Catatan (Opsional)', border: OutlineInputBorder()),
        maxLines: 3,
      ),
    );
  }

  void _onSaveButtonPressed() {
    final currentState = context.read<ProofOfServiceDetailBloc>().state;
    if (currentState is! ProofOfServiceDetailLoaded) return;

    // 1. Validasi semua TextFormField
    final isFormValid = _formKey.currentState?.validate() ?? false;

    // 2. Validasi foto (wajib ada minimal 1)
    final isPhotoValid = currentState.inputData.imagePaths.isNotEmpty;

    if (!isFormValid || !isPhotoValid) {
      // Tampilkan pesan error jika ada yang tidak valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Harap lengkapi semua field yang wajib diisi dan tambahkan foto.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Jika semua valid, tampilkan dialog konfirmasi
    _showConfirmationDialog();
  }

  Future<void> _showConfirmationDialog() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penyimpanan'),
        content: const Text('Apakah Anda yakin ingin menyimpan data ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan')),
        ],
      ),
    );

    // 4. Jika pengguna menekan "Simpan"
    if (shouldSave == true && mounted) {
      // Kirim event ke BLoC untuk menyimpan ke Hive
      context.read<ProofOfServiceDetailBloc>().add(SaveProofOfServiceDetail());

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data berhasil disimpan!'),
            backgroundColor: Colors.green),
      );

      // Kembali ke halaman sebelumnya & kirim sinyal 'true' untuk refresh
      Navigator.pop(context, true);
    }
  }
}
