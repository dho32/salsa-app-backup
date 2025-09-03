import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? errorMessage;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Tampilan UI tidak banyak berubah
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.qr_code_scanner, size: 48),
          const SizedBox(height: 12),
          const Text('Scan QR code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Scan untuk memulai validasi'),
          const SizedBox(height: 16),
          Expanded(
            child: QRView(
              key: qrKey,
              onPermissionSet: (ctrl, permission) {
                if (!permission) _showError("Kamera tidak diizinkan");
              },
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
                overlayColor: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(errorMessage!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (_isProcessing || !mounted) return;

      final scanned = scanData.code;
      if (scanned == null) return;

      setState(() => _isProcessing = true);
      await controller!.pauseCamera(); // Langsung pause agar tidak scan berulang

      try {
        // final resolvedUrl = await _resolveFinalUrl(scanned);
        // if (resolvedUrl == null) {
        //   _showError("Gagal resolve URL dari QR");
        //   return;
        // }

        final uri = Uri.tryParse(scanned);
        final serialNo = uri?.queryParameters['serial_no'];
        final transNo = uri?.queryParameters['trans_no'];

        if (transNo != null && transNo.isNotEmpty) {
          Navigator.pop(context, transNo);
        } else if (serialNo != null && serialNo.isNotEmpty) {
          Navigator.pop(context, serialNo);
        } else {
          _showError("QR tidak valid");
        }
      } catch (e) {
        _showError("Gagal membaca QR: ${e.toString()}");
      }
    });
  }

  void _showError(String message) async {
    setState(() => errorMessage = message);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isProcessing = false);
    controller?.resumeCamera();
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  Future<String?> _resolveFinalUrl(String url) async {
    try {
      final cleanUrl = Uri.parse(url).replace(queryParameters: {}).toString();
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(cleanUrl))
        ..followRedirects = false;
      final response = await client.send(request);

      final redirectUrl = response.isRedirect
          ? response.headers['location']
          : response.request?.url.toString();

      return redirectUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}