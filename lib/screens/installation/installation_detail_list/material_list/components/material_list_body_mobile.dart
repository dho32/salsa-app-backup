import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- BLOC & MODELS ---
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_state.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';

// --- SCREEN INPUT FORM ---
import '../../../installation_input_form/material_input_form/material_input_form_screen.dart';

class MaterialListBodyMobile extends StatelessWidget {
  final String transNo;
  const MaterialListBodyMobile({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstallationBloc, InstallationState>(
      builder: (context, state) {
        final detail = state.taskDetail;
        final draft = state.draftEntry;

        if (detail == null) {
          return const Center(child: Text("Data tidak ditemukan", style: TextStyle(color: Colors.white)));
        }

        // 1. Ambil Target (Basisnya Outdoor)
        final targets = detail.targets.where((t) => t.unitType == 'OUT').toList();

        if (targets.isEmpty) {
          return const Center(child: Text("Tidak ada target unit.", style: TextStyle(color: Colors.white)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: targets.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final target = targets[index];
            final idx = target.unitIndex;

            // 2. AMBIL DATA OUTDOOR & INDOOR SEKALIGUS
            final outUnit = draft?.units.firstWhere(
                    (u) => u.unitIndex == idx && u.articleType == 'OUT',
                orElse: () => InstallationUnitModel(serialNo: '', articleNo: '', articleDesc: '', articleType: '', unitIndex: -1, measurements: [], materials: InstallationMaterialsModel(pipes: [], cables: []))
            );

            final inUnit = draft?.units.firstWhere(
                    (u) => u.unitIndex == idx && u.articleType == 'IN',
                orElse: () => InstallationUnitModel(serialNo: '', articleNo: '', articleDesc: '', articleType: '', unitIndex: -1, measurements: [], materials: InstallationMaterialsModel(pipes: [], cables: []))
            );

            // 3. LOGIC GEMBOK (Syarat: Indoor & Outdoor harus ada SN)
            final String outSN = outUnit?.serialNo ?? '';
            final String inSN = inUnit?.serialNo ?? '';
            final bool isPairingComplete = outSN.isNotEmpty && inSN.isNotEmpty;

            // 4. [UPDATE PENTING] LOGIC STATUS BACA 'materialStatus'
            // Kita tidak lagi menebak dari isi pipes/cables, tapi baca langsung statusnya.
            String matStatus = 'NONE';
            if (outUnit != null) {
              matStatus = outUnit.materialStatus;
            }

            return _buildMaterialCard(
                context,
                target,
                isPairingComplete,
                matStatus, // Kirim Status ('NONE', 'DRAFT', 'COMPLETED')
                outSN,
                inSN,
                outUnit
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(
      BuildContext context,
      InstallationTargetUnitModel target,
      bool isUnlocked,
      String matStatus,
      String outSN,
      String inSN,
      InstallationUnitModel? outdoorData) {

    // DEFINISI WARNA & ICON
    Color bgColor = Colors.white;
    Color borderColor;
    Color iconColor;
    Color iconBgColor;
    IconData statusIcon;
    String statusText;
    Color badgeColor;
    Color badgeTextColor;

    if (!isUnlocked) {
      // STATE 1: LOCKED (Belum Pairing)
      bgColor = Colors.grey.shade200;
      borderColor = Colors.transparent;
      iconColor = Colors.grey;
      iconBgColor = Colors.grey.shade300;
      statusIcon = FontAwesomeIcons.lock;
      statusText = "Terkunci";
      badgeColor = Colors.grey.shade300;
      badgeTextColor = Colors.grey[700]!;
    } else if (matStatus == 'COMPLETED') {
      // STATE 2: FINAL (Hijau)
      borderColor = Colors.green.withOpacity(0.5);
      iconColor = Colors.green;
      iconBgColor = Colors.green.shade50;
      statusIcon = Icons.check_circle;
      statusText = "Material Selesai";
      badgeColor = Colors.green.shade50;
      badgeTextColor = Colors.green[700]!;
    } else if (matStatus == 'DRAFT') {
      // STATE 3: DRAFT (Orange) -> Ini yg di-trigger Auto-Save
      borderColor = Colors.orange.withOpacity(0.5);
      iconColor = const Color(0xFFE65100);
      iconBgColor = Colors.orange.shade50;
      statusIcon = Icons.edit_note;
      statusText = "Draft - Belum Final";
      badgeColor = Colors.orange.shade50;
      badgeTextColor = Colors.orange[900]!;
    } else {
      // STATE 4: NONE (Biru)
      borderColor = Colors.transparent;
      iconColor = const Color(0xFF1565C0);
      iconBgColor = const Color(0xFF1565C0).withOpacity(0.1);
      statusIcon = FontAwesomeIcons.rulerCombined;
      statusText = "Menunggu Input";
      badgeColor = Colors.grey.shade100;
      badgeTextColor = Colors.grey[500]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isUnlocked ? [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 2))
        ] : [],
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: (!isUnlocked || outdoorData == null) ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<InstallationBloc>(),
                  child: MaterialInputFormScreen(
                    transNo: transNo,
                    target: target,
                    existingData: outdoorData,
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
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(statusIcon, color: iconColor, size: 20),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Material Set Unit ${target.unitIndex}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: (matStatus == 'DRAFT') ? Colors.orange[900] : ((matStatus == 'COMPLETED') ? Colors.green[800] : Colors.black87)),
                      ),
                      const SizedBox(height: 12),

                      if (!isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Input data Indoor & Outdoor dulu!",
                            style: TextStyle(fontSize: 11, color: Colors.red[800], fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: (matStatus != 'NONE') ? iconColor.withOpacity(0.3) : Colors.transparent)
                              ),
                              child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeTextColor)),
                            ),
                            const SizedBox(height: 8),
                            _buildMiniBadge("SN INDOOR", inSN, Colors.indigo),
                            const SizedBox(height: 6),
                            _buildMiniBadge("SN OUTDOOR", outSN, Colors.blue),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(Icons.chevron_right, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, String sn, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w700)
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3))
          ),
          child: Text(
            sn,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}