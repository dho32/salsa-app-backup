import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_bloc.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_event.dart';
import 'package:salsa/blocs/failed_uploads/failed_uploads_state.dart';

class FailedUploadsBodyMobile extends StatelessWidget {
  const FailedUploadsBodyMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FailedUploadsBloc, FailedUploadsState>(
      builder: (context, state) {
        if (state.status == FailedUploadsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.failedTransactions.isEmpty) {
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
            itemCount: state.failedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = state.failedTransactions[index];
              final transNo = transaction['transNo'] as String;
              final failedCount = (transaction['failedFiles'] as List).length;
              final isUploadingThis = state.uploadingTransNo == transNo;
              final storeName =
                  transaction['storeName'] as String? ?? 'Nama Toko Tidak Tersedia';

              // --- PERBAIKAN UTAMA: Gunakan layout manual, bukan ListTile ---
              return Card(
                elevation: 2,
                margin:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // --- BARIS ATAS: IDENTITAS TRANSAKSI ---
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(Icons.storefront,
                                color: Colors.orange.shade800),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  storeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  transNo,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.grey,),
                      // --- BARIS BAWAH: STATUS & AKSI ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Keterangan jumlah file gagal
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red.shade700, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "$failedCount foto gagal",
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // Tombol Aksi yang lebih compact
                          isUploadingThis
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : TextButton.icon(
                            onPressed: (state.uploadingTransNo != null)
                                ? null
                                : () {
                              context
                                  .read<FailedUploadsBloc>()
                                  .add(RetrySingleFailedUpload(
                                  transaction));
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Upload Ulang"),
                            style: TextButton.styleFrom(
                              foregroundColor:
                              Theme.of(context).primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              // --- AKHIR PERBAIKAN ---
            },
          ),
        );
      },
    );
  }
}