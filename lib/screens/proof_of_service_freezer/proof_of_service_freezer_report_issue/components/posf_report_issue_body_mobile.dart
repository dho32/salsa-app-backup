import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/proof_of_service_freezer/posf_closed/posf_closed_bloc.dart';
import 'package:salsa/components/shared_function.dart'; // DashedRect

class PosfReportIssueBodyMobile extends StatefulWidget {
  final String transNo;
  final List<String> reasons;

  const PosfReportIssueBodyMobile({
    super.key,
    required this.transNo,
    required this.reasons,
  });

  @override
  State<PosfReportIssueBodyMobile> createState() =>
      _PosfReportIssueBodyMobileState();
}

class _PosfReportIssueBodyMobileState extends State<PosfReportIssueBodyMobile> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosfClosedBloc, PosfClosedState>(
      builder: (context, state) {
        final bloc = context.read<PosfClosedBloc>();
        final reasonValue =
            widget.reasons.contains(state.selectedReason) ? state.selectedReason : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildPhotoSection(context, state),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: reasonValue,
                isExpanded: true,
                hint: const Text('Pilih alasan (*Wajib)'),
                items: widget.reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => bloc.add(ClosedReasonSelected(v)),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Alasan Tidak Bisa Dicuci',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                onChanged: (v) => bloc.add(ClosedNotesChanged(v)),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Catatan Tambahan (Opsional)',
                  hintText:
                      'Contoh: Toko sudah tutup permanen, dikonfirmasi tetangga.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Laporkan bila kunjungan cuci freezer untuk tiket ${widget.transNo} '
                'tidak bisa diselesaikan. Sertakan alasan & foto bukti.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context, PosfClosedState state) {
    final proofImages = state.proofImages;
    final isLoading = state.status == PosfClosedStatus.loading;
    final bloc = context.read<PosfClosedBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Bukti (*Wajib, maks. 3 foto)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            ...proofImages.map(
              (photo) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photo.imagePath),
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      cacheHeight: 400,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => bloc.add(RemoveClosedProofPhoto(photo)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (proofImages.length < 3)
              DashedRect(
                color: Colors.grey.shade400,
                strokeWidth: 1,
                dashWidth: 6,
                gap: 4,
                radius: const Radius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap:
                      isLoading ? null : () => bloc.add(TakeClosedProofPhoto()),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('Tambah Foto',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
