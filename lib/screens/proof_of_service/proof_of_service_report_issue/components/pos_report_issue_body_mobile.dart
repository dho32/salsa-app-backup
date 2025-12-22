import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/proof_of_service/pos_unserviceable/pos_unserviceable_bloc.dart';
import 'package:salsa/blocs/proof_of_service/pos_unserviceable/pos_unserviceable_event.dart';
import 'package:salsa/blocs/proof_of_service/pos_unserviceable/pos_unserviceable_state.dart';

import '../../../../blocs/auth/auth_storage.dart';
import '../../../../components/shared_function.dart';

class PosReportIssueBodyMobile extends StatefulWidget {
  final String transNo;
  final List<String> reasons;

  const PosReportIssueBodyMobile({
    super.key,
    required this.transNo,
    required this.reasons,
  });

  @override
  State<PosReportIssueBodyMobile> createState() =>
      _PosReportIssueBodyMobileState();
}

class _PosReportIssueBodyMobileState extends State<PosReportIssueBodyMobile> {
  late final TextEditingController _notesController;
  late final TextEditingController _technicianController;
  String _userType = 'WH';

  @override
  void initState() {
    super.initState();
    final bloc = context.read<PosUnserviceableBloc>();
    _notesController = TextEditingController(text: bloc.state.notes);
    _technicianController =
        TextEditingController(text: bloc.state.technicianName);
    _loadUserType();

    _notesController.addListener(() {
      bloc.add(NotesChanged(_notesController.text));
    });

    _technicianController.addListener(() {
      // Hanya kirim event jika teksnya berubah
      if (bloc.state.technicianName != _technicianController.text) {
        bloc.add(TechnicianNameChanged(_technicianController.text));
      }
    });
  }

  Future<void> _loadUserType() async {
    final userData = await AuthStorage.getUser();
    if (mounted) {
      setState(() {
        _userType = userData['maintenance_type'] ?? 'WH';
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _technicianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosUnserviceableBloc, PosUnserviceableState>(
      listenWhen: (prev, current) =>
          prev.technicianName != current.technicianName,
      listener: (context, state) {
        if (_technicianController.text != state.technicianName) {
          _technicianController.text = state.technicianName;
        }
      },
      child: BlocBuilder<PosUnserviceableBloc, PosUnserviceableState>(
          builder: (context, state) {
        final bool isTechnicianReadOnly = (_userType == 'WH');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Laporan untuk Nomor DO:\n${widget.transNo}",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPhotoSection(context, state),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: state.selectedReason,
                hint: const Text('Pilih Alasan Gagal Kunjungan (*Wajib)'),
                isExpanded: true,
                items: widget.reasons.map((String reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  context
                      .read<PosUnserviceableBloc>()
                      .add(ReasonSelected(newValue));
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Alasan Gagal Kunjungan',
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _technicianController,
                readOnly: isTechnicianReadOnly, // <-- Set readOnly
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Nama Teknisi (*Wajib)',
                  prefixIcon: const Icon(Icons.engineering),
                  filled: true,
                  fillColor: isTechnicianReadOnly
                      ? Colors.grey.shade200
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Catatan Tambahan (Opsional)',
                  hintText: 'Contoh: Sudah ditunggu 30 menit, tidak ada orang.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 100), // Ruang untuk bottom button
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPhotoSection(BuildContext context, PosUnserviceableState state) {
    final isLoading = state.status == UnserviceableStatus.loading;
    final proofImages = state.proofImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text("Foto Bukti (*Wajib, maks. 3 foto)",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        if (proofImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: proofImages.length,
              itemBuilder: (context, index) {
                final photo = proofImages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(photo.imagePath),
                        fit: BoxFit.cover,
                        cacheWidth: 400, // Sesuaikan dengan ukuran grid kamu
                        cacheHeight: 400,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          context
                              .read<PosUnserviceableBloc>()
                              .add(RemoveProofPhoto(photo));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 6),
        if (proofImages.length < 3)
          DashedRect(
            color: Colors.grey.shade400,
            strokeWidth: 1,
            dashWidth: 6,
            gap: 4,
            radius: const Radius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isLoading
                  ? null
                  : () {
                      context
                          .read<PosUnserviceableBloc>()
                          .add(TakeProofPhoto());
                    },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator() // Tampilkan spinner
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text("Tambah Foto",
                                style: TextStyle(color: Colors.grey.shade800)),
                          ],
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
