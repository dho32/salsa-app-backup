import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:salsa/models/history/pos_history_detail_model.dart';

import '../../../../../blocs/history_detail/proof_of_service/pos_history_detail_bloc.dart';
import '../../../../../blocs/history_detail/proof_of_service/pos_history_detail_state.dart';
import '../../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../../models/common/captured_image_detail.dart';

class PosHistoryDetailBodyMobile extends StatelessWidget {
  const PosHistoryDetailBodyMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosHistoryDetailBloc, PosHistoryDetailState>(
      builder: (context, state) {
        if (state is PosHistoryDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PosHistoryDetailError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        if (state is PosHistoryDetailLoaded) {
          final data = state.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Kita bisa gunakan ulang beberapa widget dari SC History Detail
                _buildCustomerPanel(data.customerInfo),
                const SizedBox(height: 16),
                _buildPicPanel(context, data.picInfo),
                const SizedBox(height: 16),
                _buildTicketPanel(data.ticketInfo),
                const SizedBox(height: 16),
                _buildUnitInfoSection(data.unitInfo),
              ],
            ),
          );
        }
        return const Center(child: Text("Memuat data..."));
      },
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildCustomerPanel(PosHistoryCustomerInfo data) {
    return _buildSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informasi Customer",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.store, data.storeName, 14),
            _buildInfoRow(null, data.storeAddress, 12),
            const SizedBox(height: 4),
            _buildInfoRow(null, data.branch, 12),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.phone_in_talk_outlined, data.contact, 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPicPanel(BuildContext context, PosHistoryPicInfo data) {
    return _buildSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PIC Toko",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitledInfo("Nama Lengkap", data.name),
                      _buildTitledInfo("Nomor Telepon", data.phone),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      // 2. Buat objek CapturedImageDetail "palsu"
                      final dummyDetail = CapturedImageDetail(
                        imagePath: data.imageUrl,
                        // Isi field lain dengan data kosong atau default
                        timestamp: DateTime.now(),
                        latitude: 0.0,
                        longitude: 0.0,
                        address: 'Alamat tidak tersedia',
                        technicianName: 'N/A',
                        deviceModel: 'N/A',
                        transNo: 'N/A',
                      );
                      // 3. Navigasi ke FullScreenImageViewer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageDetail: dummyDetail,
                            isNetworkImage:
                                true, // <-- PENTING: Beri tahu bahwa ini gambar dari internet
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTitledInfo("NIK", data.nik)),
                Expanded(child: _buildTitledInfo("Jabatan", data.position)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPanel(PosHistoryTicketInfo data) {
    // Fungsi helper untuk memformat tanggal
    String formatDate(String dateString) {
      if (dateString.isEmpty) return '-';
      try {
        return DateFormat('dd MMM yyyy', 'id_ID')
            .format(DateTime.parse(dateString));
      } catch (e) {
        return dateString;
      }
    }

    // Fungsi helper untuk memformat waktu
    String formatTime(String timeString) {
      if (timeString.isEmpty) return '-';
      try {
        return DateFormat('HH:mm').format(DateTime.parse(timeString));
      } catch (e) {
        return timeString;
      }
    }

    final validTechnicians =
        data.technicians.where((t) => t.isNotEmpty).toList();
    final technicianText = validTechnicians.join('\n');
    return _buildSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.transNo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTicketRow("Jadwal Cuci", formatDate(data.scheduleDate)),
            _buildTicketRow("Teknisi", validTechnicians.join(', ')),
            _buildTicketRow("Suhu Dalam", data.tempIn),
            _buildTicketRow("Suhu Luar", data.tempOut),
            _buildTicketRow("Jam Pengerjaan", formatTime(data.serviceTime)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitInfoSection(List<PosHistoryUnitInfo> units) {
    return _buildSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Informasi Unit",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...units.map((unit) => _UnitExpansionCard(
                unit: unit,
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData? icon, String text, double? size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: size))),
      ],
    );
  }

  Widget _buildTitledInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTicketRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: child,
    );
  }
}

class _UnitExpansionCard extends StatefulWidget {
  final PosHistoryUnitInfo unit;

  const _UnitExpansionCard({required this.unit});

  @override
  State<_UnitExpansionCard> createState() => _UnitExpansionCardState();
}

class _UnitExpansionCardState extends State<_UnitExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(widget.unit.articleDesc,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(widget.unit.unitName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(widget.unit.serialNo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),

              // --- BAGIAN YANG BISA DI-EXPAND ---
              AnimatedCrossFade(
                // Konten saat tertutup (kosong)
                firstChild: const SizedBox.shrink(),
                // Konten saat terbuka
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        "Foto Unit",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildDetailPhotosSection(
                        widget.unit.photosBefore, widget.unit.photosAfter),
                    SizedBox(
                      height: 24,
                    ),
                    _buildAllMeasurements(context, widget.unit.measurements,
                        widget.unit.serialNo),
                    SizedBox(
                      height: 24,
                    )
                  ],
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),

              // --- TOMBOL UNTUK EXPAND/COLLAPSE ---
              Divider(
                color: Colors.grey,
                thickness: 0.3,
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? "Lihat Lebih Sedikit"
                          : "Lihat Selengkapnya",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Colors.grey,
          thickness: 0.3,
        )
      ],
    );
  }
}

Widget _buildPhotoItem(BuildContext context, String imageUrl) {
  return Padding(
    padding: const EdgeInsets.only(right: 8.0), // Beri jarak antar foto
    child: GestureDetector(
      onTap: () {
        // 2. Buat objek CapturedImageDetail "palsu"
        final dummyDetail = CapturedImageDetail(
          imagePath: imageUrl,
          // Isi field lain dengan data kosong atau default
          timestamp: DateTime.now(),
          latitude: 0.0,
          longitude: 0.0,
          address: 'Alamat tidak tersedia',
          technicianName: 'N/A',
          deviceModel: 'N/A',
          transNo: 'N/A',
        );
        // 3. Navigasi ke FullScreenImageViewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageDetail: dummyDetail,
              isNetworkImage:
                  true, // <-- PENTING: Beri tahu bahwa ini gambar dari internet
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 60,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _buildPlaceholderImage(),
        ),
      ),
    ),
  );
}

Widget _buildDetailPhotosSection(List<String> before, List<String> after) {
  return Row(
    children: [
      // --- SEKSI FOTO SEBELUM ---
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Foto Sebelum",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            before.isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    // Wajib agar tidak error di dalam Column
                    physics: const NeverScrollableScrollPhysics(),
                    // Wajib agar tidak ada double scroll
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Tampilkan 2 foto per baris
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 3 / 4),
                    itemCount: before.length,
                    itemBuilder: (context, index) {
                      return _buildPhotoItem(context, before[index]);
                    },
                  )
                : const Text("Tidak ada foto sebelum.",
                    style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),

      SizedBox(
        width: 25,
      ),

      // --- SEKSI FOTO SESUDAH ---
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Foto Sesudah",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            after.isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 3 / 4),
                    itemCount: after.length,
                    itemBuilder: (context, index) {
                      return _buildPhotoItem(context, after[index]);
                    },
                  )
                : const Text("Tidak ada foto sesudah.",
                    style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ],
  );
}

Widget _buildPlaceholderImage() {
  return Container(
    width: 60,
    height: 80,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported_outlined,
        color: Colors.grey, size: 40),
  );
}

Widget _buildAllMeasurements(
    BuildContext context,
    List<PosHistoryMeasurement> measurements,
    String outdoorSerialNo // `before` dan `after` tidak lagi diperlukan
    ) {
  // Cari data pengukuran dengan aman
  final suhu = measurements
      .firstWhereOrNull((m) => m.name.toLowerCase().contains('suhu'));
  final arus = measurements
      .firstWhereOrNull((m) => m.name.toLowerCase().contains('arus'));
  final tegangan = measurements
      .firstWhereOrNull((m) => m.name.toLowerCase().contains('tegangan'));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // --- Tampilkan Pengukuran Indoor ---
      if (suhu != null) ...[
        const Text("Pengukuran Unit Indoor",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildMeasurementItem(context, suhu.name, suhu.value, suhu.imageUrl),
        const SizedBox(height: 16),
      ],

      // --- Tampilkan Pengukuran Outdoor ---
      if (arus != null || tegangan != null) ...[
        const Text("Pengukuran Unit Outdoor",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            if (arus != null)
              Expanded(
                child: _buildMeasurementItem(
                    context, arus.name, arus.value, arus.imageUrl),
              ),
            if (tegangan != null)
              Expanded(
                child: _buildMeasurementItem(
                    context, tegangan.name, tegangan.value, tegangan.imageUrl),
              ),
          ],
        ),
      ],
    ],
  );
}

Widget _buildMeasurementItem(
    BuildContext context, String name, String value, String imageUrl) {
  return Row(
    children: [
      GestureDetector(
        onTap: () {
          final dummyDetail = CapturedImageDetail(
            imagePath: imageUrl,
            timestamp: DateTime.now(),
            latitude: 0.0,
            longitude: 0.0,
            address: 'Alamat tidak tersedia',
            technicianName: 'N/A',
            deviceModel: 'N/A',
            transNo: 'N/A',
          );
          // 3. Navigasi ke FullScreenImageViewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageViewer(
                imageDetail: dummyDetail,
                isNetworkImage: true,
              ),
            ),
          );
        },
        child: Image.network(
          imageUrl,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.image, size: 24, color: Colors.grey),
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      )
    ],
  );
}
