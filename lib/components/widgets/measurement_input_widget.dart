import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_storage.dart';
import '../../models/common/captured_image_detail.dart';
import '../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../shared_function.dart';
import 'full_screen_image_viewer.dart';

class MeasurementInputWidget extends StatefulWidget {
  // Parameter yang sudah ada
  final TextEditingController controller;
  final String transNo;
  final String label;
  final TextInputType keyboardType;
  final MeasurementLimits limits;
  final ValueChanged<String>? onChanged;
  final CapturedImageDetail? initialImage;
  final ValueChanged<CapturedImageDetail?>? onImageChanged;

  // BARU: Parameter opsional untuk fitur "skip"
  final bool isSkipEnabled;
  final bool isSkipped;
  final ValueChanged<bool>? onSkipChanged;

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
    // BARU: Inisialisasi parameter opsional
    this.isSkipEnabled = false,
    this.isSkipped = false,
    this.onSkipChanged,
  });

  @override
  State<MeasurementInputWidget> createState() => _MeasurementInputWidgetState();
}

class _MeasurementInputWidgetState extends State<MeasurementInputWidget> {
  CapturedImageDetail? _currentImage;
  bool _isLoading = false;
  double _currentSliderValue = 0.0;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // _focusNode.addListener(_onFocusChange);
    _updateSliderFromText(widget.controller.text);
    _currentImage = widget.initialImage;
  }

  @override
  void didUpdateWidget(covariant MeasurementInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.text != oldWidget.controller.text) {
      _updateSliderFromText(widget.controller.text);
    }
    if (widget.initialImage != oldWidget.initialImage) {
      setState(() {
        _currentImage = widget.initialImage;
      });
    }
  }

  // void _onFocusChange() {
  //   if (!_focusNode.hasFocus) {
  //     final textValue = widget.controller.text;
  //     double value = double.tryParse(textValue) ?? widget.limits.min;
  //     final clampedValue = value.clamp(widget.limits.min, widget.limits.max);
  //     final newText = _formatValue(clampedValue);
  //     if (textValue != newText) {
  //       widget.controller.text = newText;
  //       widget.onChanged?.call(newText);
  //       _currentSliderValue = clampedValue;
  //       setState(() {});
  //     }
  //   }
  // }

  String _formatValue(double value) => value == value.truncateToDouble()
      ? value.truncate().toString()
      : value.toStringAsFixed(2);

  void _updateSliderFromText(String text) {
    final value = double.tryParse(text);
    if (value != null) {
      setState(() => _currentSliderValue =
          value.clamp(widget.limits.min, widget.limits.max));
    } else if (text == "") {
      setState(() => _currentSliderValue = widget.limits.min);
    }
  }

  void _onSliderChanged(double newValue) {
    setState(() {
      _currentSliderValue = newValue;
      final newText = _formatValue(newValue);
      widget.controller.text = newText;
      widget.onChanged?.call(newText);
    });
  }

  Future<void> _takePhoto() async {
    if (_currentImage != null) return;
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final targetPath = p.join(
            tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
        final XFile? compressedImage =
            await FlutterImageCompress.compressAndGetFile(
                image.path, targetPath,
                quality: 70);
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
    setState(() => _currentImage = null);
    widget.onImageChanged?.call(null);
  }

  @override
  void dispose() {
    // _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
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
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              value: widget.isSkipped,
              onChanged: widget.onSkipChanged,
              activeTrackColor: Colors.grey,
              contentPadding: const EdgeInsets.only(left: 16, right: 8),
            )
          else
            // Tampilan header default jika skip tidak diaktifkan
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey,
          ),

          // Konten input yang bisa dinonaktifkan
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AbsorbPointer(
              absorbing: !isEnabled,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.4,
                child: !isEnabled
                    ? const SizedBox(
                        height: 16) // Beri sedikit padding saat disembunyikan
                    : _buildInputContent(primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membangun konten input
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
                side: BorderSide(color: primary), foregroundColor: primary)));
  }

  Widget _buildPhotoPreview() {
    return Stack(alignment: Alignment.topRight, children: [
      GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FullScreenImageViewer(imageDetail: _currentImage!))),
          child: Hero(
              tag: _currentImage!.imagePath,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FadeInImage(
                      placeholder: const AssetImage(
                          'assets/images/placeholder_image.jpeg'),
                      image: FileImage(File(_currentImage!.imagePath)),
                      width: double.maxFinite,
                      height: 80,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              size: 40, color: Colors.grey))))),
      GestureDetector(
          onTap: removePhoto,
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 16)))
    ]);
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
                    showValueIndicator: ShowValueIndicator.always),
                child: Slider(
                    value: _currentSliderValue,
                    min: widget.limits.min,
                    max: widget.limits.max,
                    label: _currentSliderValue.toStringAsFixed(2),
                    onChanged: _onSliderChanged))),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextFormField(
              focusNode: _focusNode,
              controller: widget.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onFieldSubmitted: (text) {
                _updateSliderFromText(text);
                widget.onChanged?.call(text);
              },
              textAlign: TextAlign.right,
              onTapOutside: (_) {
                _updateSliderFromText(widget.controller.text);
                widget.onChanged?.call(widget.controller.text);
              },
              // onEditingComplete: _onFocusChange,
              decoration:
                  InputDecoration(labelText: widget.limits.unit, isDense: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                NumericRangeFormatter(max: widget.limits.max),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
