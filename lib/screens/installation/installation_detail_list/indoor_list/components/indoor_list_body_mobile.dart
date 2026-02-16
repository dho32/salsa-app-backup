import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_state.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';

import '../../../installation_input_form/indoor_input_form/indoor_input_form_screen.dart';

class IndoorListBodyMobile extends StatelessWidget {
  final String transNo;

  const IndoorListBodyMobile({
    super.key,
    required this.transNo
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstallationBloc, InstallationState>(
      builder: (context, state) {
        final detail = state.taskDetail;
        final draft = state.draftEntry;

        if (detail == null) {
          return const Center(child: Text("Data tidak ditemukan", style: TextStyle(color: Colors.white)));
        }

        final indoorTargets = detail.targets.where((t) => t.unitType == 'IN').toList();

        if (indoorTargets.isEmpty) {
          return const Center(child: Text("Tidak ada unit Indoor pada tugas ini.", style: TextStyle(color: Colors.white)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: indoorTargets.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final target = indoorTargets[index];

            // 1. Cari Unit di Draft/Database
            // Menggunakan orElse yang mengembalikan object kosong jika tidak ketemu
            final doneUnit = draft?.units.firstWhere(
                    (u) => u.unitIndex == target.unitIndex && u.articleType == 'IN',
                orElse: () => InstallationUnitModel(
                    serialNo: '',
                    articleNo: '',
                    articleDesc: '',
                    articleType: '',
                    unitIndex: -1,
                    measurements: [],
                    materials: InstallationMaterialsModel(pipes: [], cables: [])
                )
            );

            // 2. [FIX LOGIC] Cek Keberadaan Data (Lebih Longgar)
            // Data dianggap ada jika SN terisi ATAU ada pengukuran (foto) ATAU ada note.
            bool isDataExists = false;
            if (doneUnit != null) {
              // Cek Unit Index != -1 untuk memastikan ini bukan object dummy dari orElse
              if (doneUnit.unitIndex != -1) {
                if (doneUnit.serialNo.isNotEmpty ||
                    doneUnit.measurements.isNotEmpty ||
                    (doneUnit.note != null && doneUnit.note!.isNotEmpty)) {
                  isDataExists = true;
                }
              }
            }

            // 3. Tentukan Status (Draft vs Completed)
            bool isCompleted = false;
            bool isDraft = false;

            if (isDataExists) {
              // Kirim data unit yang ditemukan (jangan null, supaya form bisa load foto tadi)
              if (doneUnit?.status == 'COMPLETED') {
                isCompleted = true;
              } else {
                isDraft = true; // Ada data tapi belum completed = DRAFT
              }
            }

            // Variabel ini yang dikirim ke Form Screen
            final realUnitData = isDataExists ? doneUnit : null;

            return _buildUnitCard(context, target, isCompleted, isDraft, realUnitData);
          },
        );
      },
    );
  }

  Widget _buildUnitCard(
      BuildContext context,
      InstallationTargetUnitModel target,
      bool isCompleted,
      bool isDraft,
      InstallationUnitModel? existingData) {

    // DEFINISI WARNA & ICON BERDASARKAN 3 STATUS
    Color statusColor;
    Color iconBgColor;
    Color borderColor;
    IconData statusIcon;
    String statusText;
    Color badgeColor;
    Color badgeTextColor;

    if (isCompleted) {
      // 1. SUDAH FINAL (HIJAU)
      statusColor = Colors.green;
      iconBgColor = Colors.green.shade50;
      borderColor = Colors.green.withOpacity(0.5);
      statusIcon = Icons.check_circle;
      statusText = "SN: ${existingData?.serialNo}";
      badgeColor = Colors.green.shade50;
      badgeTextColor = Colors.green[700]!;
    } else if (isDraft) {
      // 2. MASIH DRAFT/AUTO-SAVE (ORANGE)
      statusColor = Colors.orange[800]!;
      iconBgColor = Colors.orange.shade50;
      borderColor = Colors.orange.withOpacity(0.5);
      statusIcon = Icons.edit_note; // Icon edit/draft
      statusText = "Draft - Belum Final";
      badgeColor = Colors.orange.shade50;
      badgeTextColor = Colors.orange[900]!;
    } else {
      // 3. BELUM INPUT (BIRU DEFAUT)
      statusColor = const Color(0xFF1565C0);
      iconBgColor = const Color(0xFF1565C0).withOpacity(0.1);
      borderColor = Colors.transparent;
      statusIcon = FontAwesomeIcons.wind;
      statusText = "Menunggu Input";
      badgeColor = Colors.grey.shade100;
      badgeTextColor = Colors.grey[500]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
        border: Border.all(
            color: borderColor,
            width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<InstallationBloc>(),
                  child: IndoorInputFormScreen(
                      transNo: transNo,
                      target: target,
                      existingData: existingData // Kirim data draft ke form
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 22),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.description,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDraft ? Colors.orange[900] : (isCompleted ? Colors.green[800] : Colors.black87)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Article No: ${target.articleNo}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),
                      // Badge Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: isCompleted || isDraft
                                    ? statusColor.withOpacity(0.3)
                                    : Colors.transparent)),
                        child: Text(
                            statusText,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor)),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}