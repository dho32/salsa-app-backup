import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../blocs/upload_progress/upload_progress_cubit.dart';

Widget buildSection(
    {required String title, String subTitle = '', required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [
          Color.fromRGBO(255, 255, 255, 0.4),
          Color.fromRGBO(255, 255, 255, 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text(
              subTitle,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget buildInfoCard({
  required String title,
  required String value,
  required IconData icon,
  required MaterialColor color,
  required VoidCallback onTap,
  required BuildContext context,
}) {
  double cardWidth = MediaQuery.of(context).size.width * 0.30;

  return SizedBox(
    width: cardWidth,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}

Widget buildGridCard(
    {required String title,
    required String value,
    required IconData icon,
    required MaterialColor color}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(icon, size: 28, color: color[700]),
        const SizedBox(height: 8),
        Text(title,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget buildHeaderMain({required String title, required String period}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.black87,
            ),
          ),
          Text(period, style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    ),
  );
}

class FadeInSection extends StatefulWidget {
  final Widget child;

  const FadeInSection({super.key, required this.child});

  @override
  State<FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<FadeInSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: widget.child);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ConfirmDialogTextWidget extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;

  const ConfirmDialogTextWidget({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = "Batal",
    this.confirmText = "Ya",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.only(bottom: 8, right: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 2,
            color: Colors.black12,
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText.toUpperCase()),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText.toUpperCase()),
        ),
      ],
    );
  }
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

Future<void> showSuccessDialog(BuildContext context, String message,
    {VoidCallback? onOk}) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Berhasil"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // close dialog
            if (onOk != null) onOk();
            // Navigator.pop(context); // back to menu
            // ConfirmationService().processQueue();
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

Future<void> showPartialUploadDialog(
  BuildContext context,
  int successCount,
  int failureCount,
  List<String> failedFiles,
) async {
  await showDialog(
    context: context,
    builder: (_) {
      // 1. Ganti AlertDialog dengan Dialog untuk kontrol penuh
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // 2. Gunakan Column untuk menyusun semua elemen dialog
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Penting agar Column tidak memenuhi layar
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Title
              const Text(
                "Upload Gagal Sebagian",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 3. Gunakan Flexible yang membungkus ListView untuk area konten
              // Ini adalah kunci utama solusi ini
              Flexible(
                child: ListView(
                  // Tidak perlu shrinkWrap lagi karena sudah dibatasi oleh Flexible
                  children: [
                    Text("Berhasil: $successCount"),
                    Text("Gagal: $failureCount"),
                    const SizedBox(height: 12),
                    const Text("File yang gagal:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    // Map daftar file Anda di sini
                    ...failedFiles.map((file) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• "),
                              Flexible(child: Text(file)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bagian Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text("OK"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showFailureDialog(BuildContext context, String error) async {
  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text("Gagal"),
      content: Text("Terjadi kesalahan: $error"),
      actions: [
        TextButton(
          // GUNAKAN 'dialogContext' yang baru untuk menutup dialog!
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Tutup"),
        ),
      ],
    ),
  );
}

class UploadProgressDialog extends StatelessWidget {
  const UploadProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<UploadProgressCubit, UploadProgressState>(
          builder: (context, state) {
            final percent =
                state.total == 0 ? 0.0 : state.current / state.total;
            final percentText = (percent * 100).toStringAsFixed(0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mengunggah Foto...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: percent),
                const SizedBox(height: 12),
                Text(
                    'Progress: ${state.current} dari ${state.total} ($percentText%)'),
              ],
            );
          },
        ),
      ),
    );
  }
}
