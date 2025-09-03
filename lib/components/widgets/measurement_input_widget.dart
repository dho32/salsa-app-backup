// lib/components/widgets/measurement_input_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // MODIFIKASI: Tambahkan ini jika belum
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_storage.dart';
import '../../models/common/captured_image_detail.dart';
import '../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
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
    _currentSliderValue = widget.limits.min;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _updateSliderFromText(widget.controller.text);
    _currentImage = widget.initialImage;
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final textValue = widget.controller.text;
      double value = double.tryParse(textValue) ?? widget.limits.min;

      final clampedValue = value.clamp(widget.limits.min, widget.limits.max);
      final newText = _formatValue(clampedValue);

      if (textValue != newText) {
        setState(() {
          widget.controller.text = newText;
          widget.onChanged?.call(newText);
          _currentSliderValue = clampedValue;
        });
      }

      _updateSliderFromText(widget.controller.text);
      _formatTextField();
    }
  }

  void _formatTextField() {
    final value = double.tryParse(widget.controller.text);
    if (value != null) {
      final newText = _formatValue(value);
      if (widget.controller.text != newText) {
        widget.controller.text = newText;
        widget.onChanged?.call(newText);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange); // Hapus listener
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MeasurementInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateSliderFromText(widget.controller.text);
    }
    if (widget.initialImage != oldWidget.initialImage) {
      setState(() {
        _currentImage = widget.initialImage;
      });
    }
  }

  String _formatValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.truncate().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }

  void _updateSliderFromText(String text) {
    final value = double.tryParse(text);
    if (value != null) {
      // Panggil setState HANYA untuk update nilai slider
      setState(() {
        _currentSliderValue = value.clamp(widget.limits.min, widget.limits.max);
      });
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

    // --- MULAI PROSES LOADING ---
    setState(() {
      _isLoading = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final targetPath = p.join(
            tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

        final XFile? compressedImage =
            await FlutterImageCompress.compressAndGetFile(
          image.path,
          targetPath,
          quality: 70,
        );

        if (compressedImage == null) {
          /* Handle error */ return;
        }

        // Proses ambil GPS dan data lainnya...
        final timestamp = DateTime.now();
        double latitude = 0.0;
        double longitude = 0.0;
        String address = '';

        // try {
        //   Position position = await Geolocator.getCurrentPosition(
        //       desiredAccuracy: LocationAccuracy.high,
        //       timeLimit: const Duration(seconds: 10));
        //   latitude = position.latitude;
        //   longitude = position.longitude;
        //   List<Placemark> placemarks =
        //       await placemarkFromCoordinates(latitude, longitude);
        //   Placemark place = placemarks.first;
        //   address =
        //       "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        // } catch (e) {
        //   // Handle error GPS
        //   if (mounted) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //         content: Text('Gagal mendapatkan koordinat GPS. Coba lagi.'),
        //         backgroundColor: Colors.orange,
        //       ),
        //     );
        //   }
        // }

        final userData = await AuthStorage.getUser();
        final technicianName = userData['name'] ?? 'Unknown';
        final deviceModel = userData['device_model'] ?? 'Unknown Device';

        // Update _currentImage
        _currentImage = CapturedImageDetail(
          imagePath: compressedImage.path,
          timestamp: timestamp,
          latitude: latitude,
          longitude: longitude,
          address: address,
          technicianName: technicianName,
          deviceModel: deviceModel,
          transNo: widget.transNo,
        );

        // Panggil callback ke BLoC
        widget.onImageChanged?.call(_currentImage);
      }
    } finally {
      // --- SELESAI PROSES LOADING, APAPUN HASILNYA ---
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _currentImage = null;
    });
    widget.onImageChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                widget.label,
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(height: 4),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _currentImage != null
                    ? Stack(
                        alignment: Alignment.topRight,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(
                                    imageDetail: _currentImage!),
                              ),
                            ),
                            child: Hero(
                              tag: _currentImage!.imagePath,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FadeInImage(
                                  placeholder: const AssetImage(
                                      'assets/images/placeholder_image.jpeg'),
                                  // Gambar placeholder
                                  image:
                                      FileImage(File(_currentImage!.imagePath)),
                                  // Gambar asli
                                  width: double.maxFinite,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  // Jika terjadi error saat load gambar asli
                                  imageErrorBuilder:
                                      (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image,
                                        size: 40, color: Colors.grey);
                                  },
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _removePhoto,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text('Ambil Foto ${widget.label}'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primary), // warna border
                            foregroundColor:
                                primary, // ini juga bisa bantu untuk label/icon
                          ),
                        ),
                      ),
            const SizedBox(height: 16),
            Row(
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
                      valueIndicatorColor:
                          Theme.of(context).colorScheme.primary,
                      showValueIndicator: ShowValueIndicator.always,
                    ),
                    child: Slider(
                        value: _currentSliderValue,
                        min: widget.limits.min,
                        max: widget.limits.max,
                        label: _currentSliderValue.toStringAsFixed(1),
                        onChanged: _onSliderChanged),
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
                      onFieldSubmitted: (text) {
                        _updateSliderFromText(text);
                        widget.onChanged?.call(text);
                      },
                      textAlign: TextAlign.right,
                      onTapOutside: (_) {
                        _updateSliderFromText(widget.controller.text);
                        widget.onChanged?.call(widget.controller.text);
                      },
                      onEditingComplete: _formatTextField,
                      decoration: InputDecoration(
                        labelText: widget.limits.unit,
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'))
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "**Pastikan angka yang diinput sesuai dengan yang di foto",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
