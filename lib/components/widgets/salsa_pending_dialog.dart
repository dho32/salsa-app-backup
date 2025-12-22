import 'package:flutter/material.dart';

class SalsaPendingDialog extends StatelessWidget {
  final String transNo;
  final String customerCode;
  final String customerName;
  final VoidCallback onUploadPressed;
  final VoidCallback onContinuePressed;

  const SalsaPendingDialog({
    super.key,
    required this.transNo,
    required this.customerCode,
    required this.customerName,
    required this.onUploadPressed,
    required this.onContinuePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 50), // Ruang buat kepala Salsa
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Tunggu Sebentar!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    children: [
                      const TextSpan(text: "Transaksi "),
                      TextSpan(
                        text: transNo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: " dari Toko $customerName ($customerCode) masih memiliki status "),
                      const TextSpan(
                        text: "Upload Gagal / Pending",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: " di sistem.\n\nSebaiknya selesaikan upload dulu sebelum lanjut agar data tidak tumpang tindih dan beresiko hilang."),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- TOMBOL AKSI ---
                Row(
                  children: [
                    // Tombol Lanjut (Secondary)
                    Expanded(
                      child: TextButton(
                        onPressed: onContinuePressed,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Tetap Lanjut",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Upload (Primary)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onUploadPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        child: const Text("Upload Ulang"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // --- GAMBAR SALSA DI ATAS (POP OUT) ---
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: CircleAvatar(
                radius: 45, // Ukuran lingkaran
                backgroundColor: Colors.blue.shade50,
                backgroundImage: const AssetImage('assets/images/salsa_character.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}