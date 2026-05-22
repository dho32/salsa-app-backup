import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:salsa/components/widgets/remark_photo_picker.dart';

import '../../models/common/captured_image_detail.dart';

// Model Sederhana untuk Opsi Note
class MeasurementNoteOption {
  final String label;
  final bool requireRemark;
  final bool requirePhoto;

  const MeasurementNoteOption({
    required this.label,
    this.requireRemark = false,
    this.requirePhoto = false,
  });
}

class MeasurementNoteDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<MeasurementNoteOption> options;
  final ValueChanged<String?> onChanged;
  final TextEditingController remarkController;
  final ValueChanged<String>? onRemarkChanged;
  final List<CapturedImageDetail> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;
  final bool isTakingPhoto;

  const MeasurementNoteDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.remarkController,
    this.onRemarkChanged,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    this.isTakingPhoto = false,
  });

  @override
  State<MeasurementNoteDropdown> createState() =>
      _MeasurementNoteDropdownState();
}

class _MeasurementNoteDropdownState extends State<MeasurementNoteDropdown> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah opsi yang dipilih butuh remark tambahan
    final selectedOption = widget.options.firstWhere(
      (opt) => opt.label == widget.value,
      orElse: () => const MeasurementNoteOption(label: ''),
    );
    final bool requireRemark = selectedOption.requireRemark;
    final bool requirePhoto = selectedOption.requireRemark;

    return Column(
      children: [
        DropdownButtonFormField2<String>(
          value: widget.value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: '${widget.label} (*Wajib)',
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Pilih Alasan', style: TextStyle(fontSize: 14)),
          onChanged: (val) {
            widget.onChanged(val);
            // Clear remark jika ganti opsi
            if (val != null) {
              widget.remarkController.clear();
              widget.onRemarkChanged?.call('');
            }
          },
          items: widget.options
              .map((item) => DropdownMenuItem<String>(
                    value: item.label,
                    child:
                        Text(item.label, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 14),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _searchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'Cari catatan...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) => item.value
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase()),
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) _searchController.clear();
          },
        ),
        if (requireRemark)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextFormField(
              controller: widget.remarkController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Keterangan Tambahan (*Wajib)',
                hintText: 'Jelaskan detail masalah (Min. 20 huruf)...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(12),
                prefixIcon: Icon(Icons.edit_note),
              ),
              onChanged: widget.onRemarkChanged,
              validator: (value) {
                final text = value ?? '';
                if (text.trim().isEmpty) return 'Wajib diisi';
                if (text.replaceAll(' ', '').length < 20) {
                  return 'Minimal 20 huruf';
                }
                return null;
              },
              maxLines: 2,
            ),
          ),

        if (requirePhoto) ...[
          const SizedBox(height: 16),
          RemarkPhotoPicker(
            photos: widget.photos,
            isLoading: widget.isTakingPhoto,
            isReadOnly: false,
            onAddTap: widget.onAddPhoto,
            onRemoveTap: widget.onRemovePhoto,
          ),
        ]
      ],
    );
  }
}
