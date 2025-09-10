import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/components/widgets/full_screen_image_viewer.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/history/sc_history_detail_model.dart';

import '../../../../../blocs/history_detail/service_call/sc_history_detail_bloc.dart';
import '../../../../../blocs/history_detail/service_call/sc_history_detail_state.dart';

class ScHistoryDetailBodyMobile extends StatelessWidget {
  const ScHistoryDetailBodyMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScHistoryDetailBloc, ScHistoryDetailState>(
      builder: (context, state) {
        if (state is ScHistoryDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ScHistoryDetailError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        if (state is ScHistoryDetailLoaded) {
          final data = state.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCustomerPanel(data.customerInfo),
                const SizedBox(height: 8),
                _buildPicPanel(context, data.picInfo),
                const SizedBox(height: 8),
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

  // --- WIDGET HELPER UNTUK SETIAP PANEL ---

  Widget _buildCustomerPanel(ScHistoryCustomerInfo data) {
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

  Widget _buildPicPanel(BuildContext context, ScHistoryPicInfo data) {
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
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitledInfo("Nama Lengkap", data.name),
                    _buildTitledInfo("NIK", data.nik),
                  ],
                )),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitledInfo("Nomor Telepon", data.phone),
                    _buildTitledInfo("Jabatan", data.position),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPanel(ScHistoryTicketInfo data) {
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
            _buildTicketRow("Tanggal Komplain", data.complaintDate),
            _buildTicketRow("Kategori", data.category),
            _buildTicketRow("Keluhan", data.complaint),
            _buildTicketRow("Tanggal Servis", data.serviceDate),
            _buildTicketRow("Teknisi", technicianText),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitInfoSection(List<ScHistoryUnitInfo> units) {
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
  final ScHistoryUnitInfo unit;

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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        // 2. Buat objek CapturedImageDetail "palsu"
                        final dummyDetail = CapturedImageDetail(
                          imagePath: widget.unit.imgUrl,
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
                              isNetworkImage: true, // <-- PENTING: Beri tahu bahwa ini gambar dari internet
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.unit.imgUrl,
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _buildPlaceholderImage(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(widget.unit.unitName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(widget.unit.serialNo,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(widget.unit.complaint,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
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
                    _buildAllMeasurements(context,
                        widget.unit.measurementsBefore,
                        widget.unit.measurementsAfter,
                        widget.unit.outdoorSerialNo),
                    SizedBox(
                      height: 24,
                    ),
                    _buildDetailProblemSection(widget.unit.problems),
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

Widget _buildAllMeasurements(BuildContext context, List<ScHistoryMeasurement> before,
    List<ScHistoryMeasurement> after, String outdoorSerialNo) {
  // Kelompokkan data pengukuran
  final indoorMeasurements =
      before.where((m) => m.name.contains('suhu')).toList();
  final outdoorMeasurements =
      before.where((m) => !m.name.contains('suhu')).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (indoorMeasurements.isNotEmpty) ...[
        const Text("Pengukuran Unit Indoor",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildSingleMeasurementRow(context,
          before.firstWhere((m) => m.name.contains('suhu')),
          after.firstWhere((m) => m.name.contains('suhu')),
        ),
        const SizedBox(height: 16),
      ],
      if (outdoorMeasurements.isNotEmpty) ...[
        const Text("Pengukuran Unit Outdoor",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Text("Serial No. Outdoor: $outdoorSerialNo",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        _buildSingleMeasurementRow(context,
          before.firstWhere((m) => m.name.contains('tegangan')),
          after.firstWhere((m) => m.name.contains('tegangan')),
        ),
        const SizedBox(height: 8),
        _buildSingleMeasurementRow(context,
          before.firstWhere((m) => m.name.contains('arus')),
          after.firstWhere((m) => m.name.contains('arus')),
        ),
        const SizedBox(height: 8),
        _buildSingleMeasurementRow(context,
          before.firstWhere((m) => m.name.contains('tekanan')),
          after.firstWhere((m) => m.name.contains('tekanan')),
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

Widget _buildSingleMeasurementRow(BuildContext context,
    ScHistoryMeasurement before, ScHistoryMeasurement after) {
  return Row(
    children: [
      Expanded(
          child: _buildMeasurementItem(
              context, before.name, before.value, before.imageUrl)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
      ),
      Expanded(
          child: _buildMeasurementItem(
              context, after.name, after.value, after.imageUrl)),
    ],
  );
}

Widget _buildDetailProblemSection(List<ScHistoryProblem> problems) {
  if (problems.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Sumber Permasalahan",
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...problems.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ${p.problemName}",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(p.solutions.join('\n'),
                      style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          )),
    ],
  );
}
