import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// Bloc & Models
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_event.dart';
import 'package:salsa/blocs/installation/installation_state.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart'; // [WAJIB IMPORT INI]

// Widgets
import 'package:salsa/components/widgets/full_screen_image_viewer.dart';
import 'package:salsa/components/shared_widgets.dart'; // Pastikan UploadProgressDialog ada disini atau import manual

class InstallationSummaryBodyMobile extends StatefulWidget {
  final String transNo;

  const InstallationSummaryBodyMobile({super.key, required this.transNo});

  @override
  State<InstallationSummaryBodyMobile> createState() =>
      _InstallationSummaryBodyMobileState();
}

class _InstallationSummaryBodyMobileState
    extends State<InstallationSummaryBodyMobile> {
  final TextEditingController _remarkController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSubmitting = false;
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (_scrollController.position.maxScrollExtent <= 50) {
          setState(() => _hasReachedBottom = true);
        } else {
          _onScroll();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 100)) {
      if (!_hasReachedBottom) setState(() => _hasReachedBottom = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstallationBloc, InstallationState>(
      listener: (context, state) {
        // 1. HANDLE PROGRESS UPLOAD
        if (state.status == InstallationStatus.uploading) {
          final uploadCubit = context.read<UploadProgressCubit>();
          uploadCubit.reset();

          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                  value: uploadCubit, child: const UploadProgressDialog()));
        }

        // 2. HANDLE SUKSES SEMPURNA (MODIFIED)
        else if (state.status == InstallationStatus.success) {
          // A. Tutup Dialog Progress Dulu
          if (Navigator.canPop(context)) Navigator.pop(context);

          // B. Munculkan Dialog Sukses
          showDialog(
              context: context,
              barrierDismissible: false, // User tidak bisa tap luar untuk tutup
              builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 60),
                        SizedBox(height: 12),
                        Text("Berhasil!",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: const Text(
                      "Data Instalasi dan Foto berhasil terkirim ke server.",
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            // C. Tutup Dialog Sukses & Balik ke Menu Utama
                            Navigator.pop(ctx);
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: const Text("OK, Kembali ke Menu",
                              style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ],
                  ));
        }

        // 3. HANDLE PARTIAL (ADA YANG GAGAL)
        else if (state.status == InstallationStatus.uploadPartial) {
          if (Navigator.canPop(context)) Navigator.pop(context);

          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                    title: const Text("Upload Tidak Sempurna"),
                    content: Text(
                        "Berhasil: ${state.successCount}\nGagal: ${state.failureCount}\n\nData tersimpan, namun beberapa foto gagal terkirim.\nSilakan cek kartu 'Pending Upload' di Halaman Utama."),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.popUntil(
                              context, (route) => route.isFirst),
                          child: const Text("Ke Menu Utama"))
                    ],
                  ));
        }

        // 4. HANDLE FAILURE
        else if (state.status == InstallationStatus.failure) {
          setState(() => _isSubmitting = false);
          Navigator.of(context, rootNavigator: true).popUntil(
              (route) => route.settings.name != 'UploadProgressDialog');

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final draft = state.draftEntry;
        if (draft == null)
          return const Center(child: CircularProgressIndicator());

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderInfo(state),
                    const SizedBox(height: 20),
                    const Text("Review Per Unit",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    _buildUnifiedUnitList(draft),
                    const SizedBox(height: 12),
                    _buildTotalMaterialSummary(draft),
                    const SizedBox(height: 16),
                    _buildTransportSwitch(draft),
                    const Divider(height: 40, thickness: 1),
                    const Text("Catatan Akhir (Opsional)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Contoh: Pemasangan lancar...",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (!_hasReachedBottom)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text("Scroll sampai bawah untuk menyetujui",
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic)),
                      ),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_hasReachedBottom && !_isSubmitting)
                            ? _submitFinal
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text("Submit Pekerjaan",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeaderInfo(InstallationState state) {
    final draft = state.draftEntry!;
    final header = state.taskDetail?.header;
    final startDateStr = draft.startDate != null
        ? DateFormat('dd MMM yyyy').format(draft.startDate!)
        : '-';
    final finishDateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    List<String> technicians = [draft.technician1Name];
    if (draft.technician2Name.isNotEmpty)
      technicians.add(draft.technician2Name);
    if (draft.technician3Name.isNotEmpty)
      technicians.add(draft.technician3Name);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5)),
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                      child: Icon(FontAwesomeIcons.store,
                          color: Color(0xFF1565C0), size: 20))),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(header?.shipToName ?? "Nama Toko",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(header?.shipToAddress ?? "-",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey, height: 1.3))
                  ])),
            ]),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: _buildInfoItem("No. Transaksi",
                        header?.transNo ?? "-", Icons.receipt_long)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildInfoItem(
                        "Cust PO No", header?.poCustNo ?? "-", Icons.numbers))
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _buildInfoItem(
                        "Tgl Mulai", startDateStr, Icons.calendar_today)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildInfoItem(
                        "Tgl Selesai", finishDateStr, Icons.event_available,
                        isHighlight: true))
              ]),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Row(children: [
              const Icon(Icons.engineering, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Tim Teknisi:",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(technicians.join(", "),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis))
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalMaterialSummary(InstallationEntryModel draft) {
    final Map<String, double> pipeMap = {};
    final Map<String, double> cableMap = {};

    for (var unit in draft.units) {
      InstallationUnitModel? outdoor;
      try {
        outdoor = draft.units.firstWhere(
            (u) => u.unitIndex == unit.unitIndex && u.articleType == 'OUT');
      } catch (_) {}

      if (outdoor != null) {
        for (var p in outdoor.materials.pipes) {
          pipeMap[p.articleName] = (pipeMap[p.articleName] ?? 0) + p.length;
        }
        for (var c in outdoor.materials.cables) {
          cableMap[c.articleName] = (cableMap[c.articleName] ?? 0) + c.length;
        }
      }
    }
    if (pipeMap.isEmpty && cableMap.isEmpty) return const SizedBox.shrink();

    var sortedPipeKeys = pipeMap.keys.toList()..sort();
    var sortedCableKeys = cableMap.keys.toList()..sort();
    String formatQty(double val) =>
        val % 1 == 0 ? val.toInt().toString() : val.toString();

    Widget buildRow(String key, double val, Color color) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(key,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))
            ]),
            Text("${formatQty(val)} Meter",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87))
          ]));
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFECB3))),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Icon(Icons.calculate, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              const Text("Total Material Terpakai",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.brown))
            ])),
        const Divider(height: 1, color: Color(0xFFFFECB3)),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              ...sortedPipeKeys
                  .map((key) => buildRow(key, pipeMap[key]!, Colors.blue)),
              ...sortedCableKeys
                  .map((key) => buildRow(key, cableMap[key]!, Colors.orange))
            ])),
      ]),
    );
  }

  Widget _buildUnifiedUnitList(InstallationEntryModel draft) {
    final unitIndices = draft.units.map((u) => u.unitIndex).toSet().toList()
      ..sort();
    if (unitIndices.isEmpty)
      return const Center(
          child: Text("Belum ada data unit.",
              style: TextStyle(color: Colors.grey)));
    return Column(
        children:
            unitIndices.map((index) => _buildUnitCard(index, draft)).toList());
  }

  Widget _buildUnitCard(int unitIndex, InstallationEntryModel draft) {
    final indoor = draft.units.firstWhere(
        (u) => u.unitIndex == unitIndex && u.articleType == 'IN',
        orElse: () => InstallationUnitModel(
            unitIndex: unitIndex,
            articleType: 'IN',
            serialNo: '',
            articleNo: '',
            articleDesc: '',
            reffLineNo: '',
            materialStatus: 'DRAFT',
            materials: InstallationMaterialsModel(pipes: [], cables: [])));
    final outdoor = draft.units.firstWhere(
        (u) => u.unitIndex == unitIndex && u.articleType == 'OUT',
        orElse: () => InstallationUnitModel(
            unitIndex: unitIndex,
            articleType: 'OUT',
            serialNo: '',
            articleNo: '',
            articleDesc: '',
            reffLineNo: '',
            materialStatus: 'DRAFT',
            materials: InstallationMaterialsModel(pipes: [], cables: [])));

    List<Map<String, String>> materialRows = [];
    String formatQty(double val) =>
        val % 1 == 0 ? val.toInt().toString() : val.toString();

    for (var p in outdoor.materials.pipes) {
      materialRows.add({
        'type': 'Pipa',
        'name': p.articleName,
        'qty': p.length > 0 ? "${formatQty(p.length)}m" : "-",
        'brand': p.brandName
      });
    }
    for (var c in outdoor.materials.cables) {
      materialRows.add({
        'type': 'Kabel',
        'name': c.articleName,
        'qty': c.length > 0 ? "${formatQty(c.length)}m" : "-",
        'brand': c.brandName
      });
    }

    List<MaterialEvidenceModel> relatedEvidences = [];
    void findEvidence(String key) {
      try {
        final ev = draft.materialEvidences.firstWhere((e) => e.key == key);
        if (ev.photoPath.isNotEmpty) relatedEvidences.add(ev);
      } catch (_) {}
    }

    for (var p in outdoor.materials.pipes) {
      if (p.brandId.isNotEmpty) findEvidence("${p.articleId}_${p.brandId}");
    }
    for (var c in outdoor.materials.cables) {
      if (c.brandId.isNotEmpty) findEvidence("${c.articleId}_${c.brandId}");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(children: [
              Icon(Icons.ac_unit, size: 16, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Text("UNIT $unitIndex",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue.shade900))
            ])),
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: _buildSNColumn(
                        "Indoor SN", indoor.serialNo, FontAwesomeIcons.fan)),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSNColumn(
                        "Outdoor SN", outdoor.serialNo, FontAwesomeIcons.wind))
              ]),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1)),
              const Text("Material Terpakai:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (materialRows.isEmpty)
                const Text("- Belum input material -",
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey))
              else
                _buildMaterialTable(materialRows),
              const SizedBox(height: 16),
              const Text("Tambahan:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
                  if (outdoor.materials.mountingType == 'NONE')
                    const Text("- Tidak ada material tambahan -",
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey))
                  else
                    Text(" - ${outdoor.materials.mountingType}", style: TextStyle(
                        fontSize: 12,)),
                  if (outdoor.materials.hasJasaPerapihan)
                    Text(" - JASA PERAPIHAN", style: TextStyle(
                      fontSize: 12,)),
              const SizedBox(height: 16),
              if (relatedEvidences.isNotEmpty) ...[
                const Text("Foto Bukti Merk:",
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: relatedEvidences
                        .map((ev) => _buildThumbnail(ev))
                        .toList())
              ] else if (materialRows.isNotEmpty) ...[
                const Text("⚠️ Foto merk belum diambil",
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontStyle: FontStyle.italic))
              ]
            ]))
      ]),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {bool isHighlight = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: Colors.grey.shade400),
      const SizedBox(width: 8),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF1565C0) : Colors.black87))
      ]))
    ]);
  }

  Widget _buildMaterialTable(List<Map<String, String>> rows) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300)),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(2)
                },
                border: TableBorder(
                    horizontalInside:
                        BorderSide(color: Colors.grey.shade200, width: 1),
                    verticalInside:
                        BorderSide(color: Colors.grey.shade200, width: 1)),
                children: [
                  TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Item",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11))),
                        Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Qty",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11))),
                        Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Merk",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11)))
                      ]),
                  ...rows.map((row) {
                    return TableRow(children: [
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row['type']!,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: row['type'] == 'Pipa'
                                            ? Colors.blue
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold)),
                                Text(row['name']!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black87))
                              ])),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 4),
                          child: Text(row['qty']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          child: Text(row['brand']!,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black87)))
                    ]);
                  }).toList()
                ])));
  }

  Widget _buildSNColumn(String label, String sn, IconData icon) {
    bool isEmpty = sn.isEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))
      ]),
      const SizedBox(height: 4),
      Text(isEmpty ? "Kosong ⚠️" : sn,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isEmpty ? Colors.red : Colors.black87))
    ]);
  }

  Widget _buildThumbnail(MaterialEvidenceModel ev) {
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                      imageDetail: CapturedImageDetail(
                          imagePath: ev.photoPath,
                          timestamp: DateTime.now(),
                          technicianName: '',
                          deviceModel: '',
                          transNo: widget.transNo,
                          latitude: 0,
                          longitude: 0,
                          address: ''))));
        },
        child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                    image: FileImage(File(ev.photoPath)), fit: BoxFit.cover),
                border: Border.all(color: Colors.grey.shade300))));
  }

  Widget _buildTransportSwitch(InstallationEntryModel draft) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: SwitchListTile(
        title: const Text("Biaya Transport",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text("Centang jika ada biaya transport kunjungan",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        activeColor: const Color(0xFF1565C0),
        value: draft.hasTransport,
        onChanged: (val) {
          context.read<InstallationBloc>().add(UpdateTransportStatus(val));
        },
      ),
    );
  }

  Future<void> _submitFinal() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("Konfirmasi Submit"),
                content: const Text(
                    "Pastikan data sudah benar. Data akan dikirim ke server dan tidak dapat diubah lagi."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cek Lagi")),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0)),
                      child: const Text("Ya, Submit",
                          style: TextStyle(color: Colors.white)))
                ]));
    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    if (mounted) {
      context.read<InstallationBloc>().add(SubmitInstallationFinal(
            transNo: widget.transNo,
            remark: _remarkController.text,
            progressCubit: context.read<UploadProgressCubit>(),
          ));
    }
  }
}
