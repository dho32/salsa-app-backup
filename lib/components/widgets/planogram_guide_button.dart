import 'package:flutter/material.dart';

import '../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';

/// Tombol "Lihat Panduan Planogram" + viewer full-screen-nya.
///
/// Sumber gambar **hybrid**:
///   1. [url] dari server (`PosfWizardConfig.planogramUrl`) bila tidak kosong,
///   2. bila URL kosong / gagal dimuat (offline, 404) → asset bawaan
///      [kPosfPlanogramAsset],
///   3. bila asset pun belum ada di bundle → placeholder informatif (bukan
///      crash), supaya build tetap jalan sebelum file gambarnya dipasang.
class PlanogramGuideButton extends StatelessWidget {
  /// URL gambar planogram dari server. Null/kosong → langsung pakai asset.
  final String? url;

  const PlanogramGuideButton({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.grid_view_rounded, size: 18),
        label: const Text('Lihat Panduan Display Product Sesuai Planogram'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PlanogramViewerScreen(url: url),
          ),
        ),
      ),
    );
  }
}

class _PlanogramViewerScreen extends StatelessWidget {
  final String? url;

  const _PlanogramViewerScreen({this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Panduan Planogram'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white10,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Susun display produk mengikuti panduan berikut sebelum '
              'mengambil foto Display Produk. Cubit layar untuk memperbesar.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: _buildImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final String remote = url?.trim() ?? '';
    if (remote.isEmpty) return _assetImage();
    return Image.network(
      remote,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
      // Offline / URL mati → jatuh ke asset bawaan.
      errorBuilder: (_, __, ___) => _assetImage(),
    );
  }

  Widget _assetImage() => Image.asset(
        kPosfPlanogramAsset,
        fit: BoxFit.contain,
        // Asset belum dipasang di bundle → jangan crash, tampilkan info.
        errorBuilder: (_, __, ___) => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  color: Colors.white54, size: 64),
              SizedBox(height: 12),
              Text(
                'Gambar panduan planogram belum tersedia.\n'
                'Hubungi admin untuk memperbarui aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}
