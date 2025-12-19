import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../../../../models/task_maintenance/task_maintenance_model.dart';

class FailedUploadsBodyMobile extends StatelessWidget {
  final List<TransactionSuggestion> apiPendingList;

  const FailedUploadsBodyMobile({
    super.key,
    required this.apiPendingList,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FailedUploadsBloc, FailedUploadsState>(
      builder: (context, state) {
        // --- LOGIC UTAMA: MATCHING ---
        final combinedList =
            _mergeDataWithMatching(state.failedTransactions, apiPendingList);

        if (state.status == FailedUploadsStatus.loading &&
            combinedList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (combinedList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_done_outlined, size: 80, color: Colors.green),
                SizedBox(height: 16),
                Text("Semua data berhasil di-upload!",
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FailedUploadsBloc>().add(LoadFailedUploads());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: combinedList.length,
            itemBuilder: (context, index) {
              return _buildItemCard(
                  context, combinedList[index], state.uploadingTransNo);
            },
          ),
        );
      },
    );
  }

  // --- LOGIC MATCHING: CEK HIVE VS API ---
  List<Map<String, dynamic>> _mergeDataWithMatching(
    List<Map<String, dynamic>> localList,
    List<TransactionSuggestion> apiList,
  ) {
    List<Map<String, dynamic>> result = [];
    Set<String> processedIDs = {};

    // 1. PROSES DATA LOKAL (HIVE) -> INI PASTI MATCH (KUNING)
    for (var l in localList) {
      String transNo = (l['transNo'] ?? '').toString().trim();
      if (transNo.isEmpty) continue;

      // Ambil nama toko (prioritas dari Hive, kalau kosong ambil placeholder)
      String displayName = l['storeName'] ?? l['customerName'] ?? 'Data Lokal';

      result.add({
        ...l,
        'transNo': transNo,
        'customerName': displayName,
        'isZombie': false, // MATCH = False (Artinya pakai Upload S3)
      });
      processedIDs.add(transNo.toUpperCase());
    }

    // 2. PROSES DATA API -> CEK APAKAH ADA DI LOKAL?
    for (var a in apiList) {
      String apiID = a.transNo.trim().toUpperCase();

      // Jika ID API ini TIDAK ADA di Hive (processedIDs), berarti NO MATCH -> ZOMBIE (MERAH)
      if (!processedIDs.contains(apiID)) {
        result.add({
          'transNo': a.transNo,
          'customerName': a.customerName,
          'isZombie': true, // NO MATCH = True (Artinya Reset Server)
          'failedFiles': [], // Gak ada file lokal
        });
      }
      // Jika MATCH (ada di Hive), sudah masuk di loop pertama, jadi skip.
    }

    return result;
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item,
      String? uploadingTransNo) {
    final String transNo = item['transNo'] ?? '-';
    final String customerName = item['customerName'] ?? '-';
    final bool isZombie =
        item['isZombie'] ?? false; // Match (False) vs No Match (True)

    final bool isUploadingThis = uploadingTransNo == transNo;

    // Styling Logic
    final Color cardColor = isZombie ? Colors.red.shade50 : Colors.white;
    final Color borderColor =
        isZombie ? Colors.orangeAccent.shade200 : Colors.grey.shade300;
    final IconData icon = isZombie ? Icons.broken_image_outlined : Icons.image;
    final Color iconColor = isZombie ? Colors.orangeAccent : Colors.green;

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(transNo,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: borderColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZombie
                            ? "Data Tidak Ditemukan di Perangkat"
                            : "Siap Upload Ulang",
                        style: TextStyle(
                            color: isZombie
                                ? Colors.yellow.shade900
                                : Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, right: 12.0),
                        child: isZombie
                            ? Text(
                                "Sebagian foto tidak tersedia di perangkat dan tidak dapat diunggah ke sistem.",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade600),
                              )
                            : Text(
                                "Pastikan koneksi internet dalam kondisi stabil sebelum melakukan proses unggah ulang foto.",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade600),
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (uploadingTransNo != null)
                        ? null
                        : () {
                            // 🔥 ACTION SESUAI STATUS ZOMBIE
                            context
                                .read<FailedUploadsBloc>()
                                .add(RetryTransaction(
                                  transNo: transNo,
                                  isZombie: isZombie,
                                ));
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isZombie ? Colors.orangeAccent : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(isZombie ? Icons.auto_fix_high : Icons.upload,
                        size: 16),
                    label: isUploadingThis
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isZombie ? "Proses" : "Upload"),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
