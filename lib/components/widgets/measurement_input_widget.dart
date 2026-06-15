import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_storage.dart';
import '../../models/common/captured_image_detail.dart';
import '../../models/common/measurement_limits.dart';
import '../services/watermark_service.dart';
import '../shared_function.dart';
import 'full_screen_image_viewer.dart';

class MeasurementInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String transNo;
  final String label;
  final TextInputType keyboardType;
  final MeasurementLimits limits;
  final ValueChanged<String>? onChanged;
  final CapturedImageDetail? initialImage;
  final ValueChanged<CapturedImageDetail?>? onImageChanged;
  final bool isSkipEnabled;
  final bool isSkipped;
  final ValueChanged<bool>? onSkipChanged;
  final ValueChanged<String>? onEditingComplete;

  /// Label jenis foto untuk watermark. Default: [label].
  final String? photoLabel;

  const MeasurementInputWidget({
    super.key,
    required this.controller,
    required this.transNo,
    required this.label,
    required this.keyboardType,
    required this.limits,
    this.onChanged,
    this.initialImage,
    this.onImageChanged,
    this.isSkipEnabled = false,
    this.isSkipped = false,
    this.onSkipChanged,
    this.onEditingComplete,
    this.photoLabel,
  });

  @override
  State<MeasurementInputWidget> createState() => _MeasurementInputWidgetState();
}

class _MeasurementInputWidgetState extends State<MeasurementInputWidget> {
  bool _isLoading = false;
  double _currentSliderValue = 0.0;
  String? _errorText;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _updateSliderAndValidate(widget.controller.text, widget.limits);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  // 🔥 TAMBAHAN PENTING: Update UI kalau data dari BLoC berubah (misal diclear/swap)
  @override
  void didUpdateWidget(covariant MeasurementInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.text != oldWidget.controller.text) {
      _updateSliderFromText(widget.controller.text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = widget.controller.text;
      setState(() {
        _errorText = _getValidationError(widget.controller.text, widget.limits);
        _updateSliderFromText(text);
        widget.onEditingComplete?.call(text); // 🔥 Tetap kirim saat un-focus
      });
    }
  }

  String? _getValidationError(String text, MeasurementLimits limits) {
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) {
      if (!text.endsWith('.')) return 'Angka tidak valid';
    } else {
      if (value > limits.max) return 'Maks: ${limits.max.toStringAsFixed(0)}';
      if (value < limits.min) return 'Min: ${limits.min.toStringAsFixed(1)}';
    }
    return null;
  }

  String _formatValue(double value) => value == value.truncateToDouble()
      ? value.truncate().toString()
      : value.toStringAsFixed(2);

  void _updateSliderAndValidate(String text, MeasurementLimits limits) {
    double value = double.tryParse(text) ?? limits.min;
    if (value < limits.min) {
      value = limits.min;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final newText = _formatValue(value);
          widget.controller.text = newText;
          widget.onChanged?.call(newText);
        }
      });
    }
    setState(() {
      _currentSliderValue = value.clamp(limits.min, limits.max);
    });
  }

  void _updateSliderFromText(String text) {
    final value = double.tryParse(text);
    _currentSliderValue = (value ?? widget.limits.min)
        .clamp(widget.limits.min, widget.limits.max);
  }

  Future<void> _takePhoto() async {
    if (widget.initialImage != null) return; // 🔥 Cegah double klik
    setState(() => _isLoading = true);

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image != null) {
        final userData = await AuthStorage.getUser();
        final technicianName = userData['name'] ?? 'Unknown';
        final deviceModel = userData['device_model'] ?? 'Unknown Device';
        final timestamp = DateTime.now();

        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create();
        }
        final targetPath = p.join(
            imagesDir.path, 'WM_${timestamp.millisecondsSinceEpoch}.jpg');

        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: technicianName,
          deviceModel: deviceModel,
          photoLabel: widget.photoLabel ?? widget.label,
        );

        final String? finalImagePath =
        await WatermarkService.processImage(request);

        if (finalImagePath != null) {
          final capturedImg = CapturedImageDetail(
            imagePath: finalImagePath,
            timestamp: timestamp,
            latitude: 0,
            longitude: 0,
            address: "",
            technicianName: technicianName,
            deviceModel: deviceModel,
            transNo: widget.transNo,
          );
          // 🔥 Langsung lempar foto ke BLoC (biar BLoC yg simpen)
          widget.onImageChanged?.call(capturedImg);
        }
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void removePhoto() {
    // 🔥 Minta BLoC buat hapus fotonya
    widget.onImageChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final bool isEnabled = !widget.isSkipped;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isEnabled ? Colors.white : Colors.grey.shade100,
      child: Column(
        children: [
          if (widget.isSkipEnabled)
            SwitchListTile(
              title: Text(widget.label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                isEnabled
                    ? 'Tekan tombol sebelah jika tidak bisa diukur'
                    : 'Tidak dapat melakukan pengukuran',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              value: widget.isSkipped,
              onChanged: widget.onSkipChanged,
              activeTrackColor: Colors.grey,
              contentPadding: const EdgeInsets.only(left: 16, right: 8),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Colors.grey),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AbsorbPointer(
              absorbing: !isEnabled,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.4,
                child: !isEnabled
                    ? const SizedBox(height: 16)
                    : _buildInputContent(primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputContent(Color primary) {
    // 🔥 PERHATIKAN: Sekarang kita pakai widget.initialImage sebagai sumber kebenaran (Source of Truth)
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          )
              : widget.initialImage != null // 🔥 Cek langsung dari Data BLoC
              ? _buildPhotoPreview(widget.initialImage!)
              : _buildPhotoButton(primary),
          const SizedBox(height: 16),
          _buildSliderAndTextfield(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "**Pastikan angka yang diinput sesuai dengan yang di foto",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoButton(Color primary) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _takePhoto,
        icon: const Icon(Icons.camera_alt),
        label: Text('Ambil Foto ${widget.label}'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary),
          foregroundColor: primary,
        ),
      ),
    );
  }

  // 🔥 Fungsi preview sekarang nerima data dari parameter
  Widget _buildPhotoPreview(CapturedImageDetail currentImage) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FullScreenImageViewer(imageDetail: currentImage),
            ),
          ),
          child: Hero(
            tag: currentImage.imagePath,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(currentImage.imagePath),
                cacheWidth: 800,
                cacheHeight: 800,
                width: 500,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => const Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: removePhoto, // 🔥 Lempar perintah hapus ke BLoC
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(2),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderAndTextfield() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 12,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: Colors.blueGrey,
              overlayColor: Colors.grey.shade100,
              valueIndicatorColor: Theme.of(context).colorScheme.primary,
              showValueIndicator: ShowValueIndicator.always,
            ),
            child: Slider(
              value: _currentSliderValue,
              min: widget.limits.min,
              max: widget.limits.max,
              label: _currentSliderValue.toStringAsFixed(2),
              onChanged: (newValue) {
                final newText = _formatValue(newValue);
                setState(() {
                  _currentSliderValue = newValue;
                  widget.controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                  _errorText = null;
                  widget.onChanged?.call(newText);
                  // 🔥 Jangan kirim update ke BLoC dari dalam sini pas di-slide (biar ga spam event).
                  // Biarin onEditingComplete (pas blur/keyboard tutup) yg ngirim!
                });
              },
              // 🔥 Kirim update ke BLoC saat user lepas jari dari slider
              onChangeEnd: (newValue) {
                final newText = _formatValue(newValue);
                widget.onEditingComplete?.call(newText);
              },
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextFormField(
              focusNode: _focusNode,
              controller: widget.controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                labelText: widget.limits.unit,
                isDense: true,
                errorText: _errorText,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}