import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Ganti import ini dengan path yang sesuai di proyek Anda
import '../../blocs/auth/auth_storage.dart';
import '../../models/common/captured_image_detail.dart';
import '../../models/common/measurement_limits.dart';
import '../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
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
  });

  @override
  State<MeasurementInputWidget> createState() => _MeasurementInputWidgetState();
}

class _MeasurementInputWidgetState extends State<MeasurementInputWidget> {
  CapturedImageDetail? _currentImage;
  bool _isLoading = false;
  double _currentSliderValue = 0.0;
  String? _errorText;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
    // _updateSliderFromText(widget.controller.text); // Inisialisasi awal tanpa rebuild
    _updateSliderAndValidate(widget.controller.text, widget.limits);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Saat fokus hilang, lakukan SEMUA update dalam satu setState
      final text = widget.controller.text;
      print(
          '1. MeasurementInputWidget (_onFocusChange): Nilai akhir adalah "$text"');

      setState(() {
        // 1. Lakukan validasi dan tampilkan error
        _errorText = _getValidationError(widget.controller.text, widget.limits);
        // 2. Update posisi slider sesuai teks final
        _updateSliderFromText(text);
        widget.onEditingComplete?.call(text);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeasurementInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika batas (limits) berubah, kita harus mengevaluasi ulang semuanya.
    if (widget.limits != oldWidget.limits) {
      // Panggil helper method baru kita dengan batas yang BARU.
      _updateSliderAndValidate(widget.controller.text, widget.limits);
    }

    // Logika ini untuk sinkronisasi dari BLoC (jika ada)
    if (widget.controller.text != oldWidget.controller.text) {
      _updateSliderFromText(widget.controller.text);
    }

    if (widget.initialImage != oldWidget.initialImage) {
      setState(() {
        _currentImage = widget.initialImage;
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

    // Jika nilai saat ini di bawah batas minimum baru, paksa perbarui.
    if (value < limits.min) {
      value = limits.min;
      // Perbarui juga controller agar UI sinkron.
      // `addPostFrameCallback` memastikan ini berjalan setelah build selesai.
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

  void _onSliderChanged(double newValue) {
    final newText = _formatValue(newValue);
    setState(() {
      _currentSliderValue = newValue;
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      // Jika diubah via slider, pasti valid. Hapus error.
      _errorText = null;
      widget.onChanged?.call(newText);
      widget.onEditingComplete?.call(newText);
    });
  }

  Future<void> _takePhoto() async {
    if (_currentImage != null) return;
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create();
        }
        final targetPath = p.join(
            imagesDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
        final XFile? compressedImage =
            await FlutterImageCompress.compressAndGetFile(
          image.path,
          targetPath,
          quality: 70,
        );
        if (compressedImage == null) return;
        final userData = await AuthStorage.getUser();
        _currentImage = CapturedImageDetail(
          imagePath: compressedImage.path,
          timestamp: DateTime.now(),
          latitude: 0,
          longitude: 0,
          address: "",
          technicianName: userData['name'] ?? 'Unknown',
          deviceModel: userData['device_model'] ?? 'Unknown Device',
          transNo: widget.transNo,
        );
        widget.onImageChanged?.call(_currentImage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void removePhoto() {
    setState(() {
      _currentImage = null;
    });
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
              : _currentImage != null
                  ? _buildPhotoPreview()
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

  Widget _buildPhotoPreview() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    FullScreenImageViewer(imageDetail: _currentImage!)),
          ),
          child: Hero(
            tag: _currentImage!.imagePath,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FadeInImage(
                placeholder:
                    const AssetImage('assets/images/placeholder_image.jpeg'),
                image: FileImage(File(_currentImage!.imagePath)),
                width: double.maxFinite,
                height: 80,
                fit: BoxFit.cover,
                imageErrorBuilder: (c, e, st) => const Icon(Icons.broken_image,
                    size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: removePhoto,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(10)),
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
              onChanged: _onSliderChanged,
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
              onChanged: (text) {
                // HANYA meneruskan event, tidak ada setState di sini.
                widget.onChanged?.call(text);
              },
              decoration: InputDecoration(
                labelText: widget.limits.unit,
                isDense: true,
                errorText: _errorText,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
              ],
            ),
          ),
        ),
      ],
    );
  }
}
