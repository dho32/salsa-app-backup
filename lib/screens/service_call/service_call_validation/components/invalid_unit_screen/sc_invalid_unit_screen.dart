import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/models/service_call/service_call_detail_model.dart';

import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';

class ScInvalidUnitScreen extends StatefulWidget {
  final String transNo;
  final String ticketSerialNo;
  final String currentSerialNo;

  // Data List Unit Pengganti dari API
  final List<String> swapOptions;

  const ScInvalidUnitScreen({
    super.key,
    required this.transNo,
    required this.ticketSerialNo,
    required this.currentSerialNo,
    required this.swapOptions,
  });

  @override
  State<ScInvalidUnitScreen> createState() => _ScInvalidUnitScreenState();
}

class _ScInvalidUnitScreenState extends State<ScInvalidUnitScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedNewSerial; // Menyimpan serial yang dipilih

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ValidationDropdownBloc, ValidationDropdownState>(
      listener: (context, state) {
        if (state is ValidationDropdownLoaded) {
          // Jika sukses disimpan (sebagai draft koreksi)
          if (state.saveStatus == ValidationSaveStatus.successDraft ||
              state.saveStatus == ValidationSaveStatus.successSilent) {
            Navigator.of(context).pop(true);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Unit berhasil ditukar. Silakan kerjakan unit yang baru."),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating),
            );
          } else if (state.saveStatus == ValidationSaveStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.saveMessage ?? "Gagal"),
                  backgroundColor: Colors.red),
            );
          }
        }
      },
      child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(
        builder: (context, state) {
          // Cek status loading
          bool isSaving = false;
          if (state is ValidationDropdownLoaded) {
            isSaving = state.saveStatus == ValidationSaveStatus.saving;
          }

          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text("Tukar / Koreksi Unit"),
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade900,
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. INFO UNIT LAMA
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Unit yang sedang dikerjakan saat ini:",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(widget.currentSerialNo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. DROPDOWN UNIT PENGGANTI
                        const Text("Ganti Menjadi Unit: (*Wajib)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),

                        if (widget.swapOptions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        "Tidak ada data unit lain yang tersedia di toko ini.",
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField2<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            hint: const Text('Pilih Serial No.',
                                style: TextStyle(fontSize: 14)),

                            // --- ITEM BUILDER ---
                            items: widget.swapOptions.map((serial) {
                              // Logic Tampilan Revert
                              final isOriginal = serial == widget.ticketSerialNo;

                              return DropdownMenuItem<String>(
                                value: serial,
                                child: Text(
                                    serial + (isOriginal ? " (Kembali ke Asal)" : ""),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isOriginal ? FontWeight.bold : FontWeight.normal,
                                        color: isOriginal ? Colors.blue : Colors.black
                                    )
                                ),
                              );
                            }).toList(),

                            validator: (value) {
                              if (value == null) {
                                return 'Harap pilih unit pengganti.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _selectedNewSerial = value;
                              });
                            },

                            // --- FITUR SEARCH ---
                            dropdownSearchData: DropdownSearchData(
                              searchController: _searchController,
                              searchInnerWidgetHeight: 50,
                              searchInnerWidget: Container(
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                child: TextFormField(
                                  expands: true,
                                  maxLines: null,
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    hintText: 'Cari serial number...',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              searchMatchFn: (item, searchValue) {
                                // Cari berdasarkan value (Serial No)
                                return item.value
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchValue.toLowerCase());
                              },
                            ),
                            onMenuStateChange: (isOpen) {
                              if (!isOpen) _searchController.clear();
                            },
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 400,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 3. ALASAN KOREKSI
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Alasan pergantian unit (*Wajib)',
                            hintText: 'Jelaskan kenapa unit ini diganti...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Wajib diisi";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // 4. INFO WARNING
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade800),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Pastikan serial number yang dipilih sudah sesuai dengan unit bermasalah sebelum melanjutkan proses.",
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isSaving
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              // KIRIM EVENT KOREKSI UNIT
                              context.read<ValidationDropdownBloc>().add(
                                    CorrectUnitSerial(
                                      transNo: widget.transNo,
                                      oldSerialNo: widget.ticketSerialNo,
                                      newSerialNo: _selectedNewSerial!,
                                      // Pasti ada krn validator
                                      reason: _reasonController.text.trim(),
                                    ),
                                  );
                            }
                          },
                    child: const Text("Simpan Perubahan",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              // LOADING OVERLAY
              if (isSaving)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }
}
