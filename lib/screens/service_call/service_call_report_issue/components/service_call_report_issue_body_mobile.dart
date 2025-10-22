import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_unserviceable/sc_unserviceable_event.dart';

import '../../../../blocs/service_call/service_call_unserviceable/sc_unserviceable_bloc.dart';
import '../../../../blocs/service_call/service_call_unserviceable/sc_unserviceable_state.dart';
import '../../../../components/shared_function.dart';

class SCReportIssueBodyMobile extends StatefulWidget {
  final String transNo;
  final List<String> reasons;

  const SCReportIssueBodyMobile({
    super.key,
    required this.transNo,
    required this.reasons,
  });

  @override
  State<SCReportIssueBodyMobile> createState() =>
      _SCReportIssueBodyMobileState();
}

class _SCReportIssueBodyMobileState extends State<SCReportIssueBodyMobile> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<SCUnserviceableBloc>();
    _notesController = TextEditingController(text: bloc.state.notes);

    _notesController.addListener(() {
      bloc.add(NotesChanged(_notesController.text));
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SCUnserviceableBloc, SCUnserviceableState>(
      builder: (context, state) {

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
                hint:
                const Text('Pilih Alasan Gagal Kunjungan (*Wajib)'),
                isExpanded: true,
                items: widget.reasons.map((String reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  context
                      .read<SCUnserviceableBloc>()
                      .add(ReasonSelected(newValue));
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Alasan Gagal Kunjungan',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Catatan Tambahan (Opsional)',
                  hintText:
                  'Contoh: Sudah ditunggu 30 menit, tidak ada orang.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 100), // Ruang untuk bottom button
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection(
      BuildContext context, SCUnserviceableState state) {
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
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          context
                              .read<SCUnserviceableBloc>()
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
              onTap: isLoading ? null : () {
                context.read<SCUnserviceableBloc>().add(TakeProofPhoto());
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
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text("Tambah Foto", style: TextStyle(color: Colors.grey.shade800)),
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