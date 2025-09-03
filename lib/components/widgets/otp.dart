import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart'; // <-- 1. Import pinput
import 'package:salsa/blocs/otp/otp_bloc.dart';
import 'package:salsa/blocs/otp/otp_event.dart';
import 'package:salsa/blocs/otp/otp_state.dart';

class OtpDialog extends StatefulWidget {
  final String shipTo;
  final String email;
  final VoidCallback onVerified;

  const OtpDialog({
    super.key,
    required this.shipTo,
    required this.email,
    required this.onVerified,
  });

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Minta OTP saat dialog pertama kali muncul
    context.read<OtpBloc>().add(RequestOtp(widget.shipTo, '1'));
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _maskText(String n) {
    if (n.length <= 4) return n;
    final maskLen = (n.length ~/ 2) + 1;
    final pre = ((n.length - maskLen) / 2).floor();
    final suf = n.length - maskLen - pre;
    return '${n.substring(0, pre)}${'*' * maskLen}${n.substring(n.length - suf)}';
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email; // Kembalikan jika bukan email valid

    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];

    final maskLen = (name.length ~/ 2) + 1;
    final pre = ((name.length - maskLen) / 2).floor();
    final suf = name.length - maskLen - pre;
    return '${name.substring(0, pre)}${'*' * maskLen}${name.substring(name.length - suf)}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    // Tema untuk Pinput
    final defaultPinTheme = PinTheme(
      width: 48, // Perkecil sedikit lebar kotaknya
      height: 52, // Perkecil sedikit tinggi kotaknya
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Beri warna latar yang lembut
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300), // Beri border tipis
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: BlocConsumer<OtpBloc, OtpState>(
        listenWhen: (_, current) => current is OtpVerified,
        listener: (context, state) {
          widget.onVerified();
          Navigator.pop(context);
        },
        builder: (context, state) {
          final isLoading = state is OtpLoading;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Verifikasi OTP',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Masukkan 6 digit kode yang dikirim ke email ${_maskEmail(widget.email)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // --- 2. Gunakan Pinput Widget ---
                Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _focusNode,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: Colors.red),
                    ),
                  ),
                  onCompleted: (pin) {
                    context.read<OtpBloc>().add(VerifyOtp(widget.shipTo, pin));
                  },
                ),
                const SizedBox(height: 16),

                // Area untuk menampilkan status (error, cooldown, dll.)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildResendArea(state),
                ),
                const SizedBox(height: 24),

                // Tombol Verifikasi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading || _pinController.text.length != 6
                        ? null
                        : () {
                            context.read<OtpBloc>().add(
                                VerifyOtp(widget.shipTo, _pinController.text));
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3))
                        : const Text('Verifikasi'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 3. Fungsi _buildResendArea disederhanakan ---
  Widget _buildResendArea(OtpState state) {
    // Kondisi 1: Saat dialog pertama kali muncul (OTP belum pernah diminta)
    if (state is OtpInitial) {
      return TextButton(
        key: const ValueKey('resend'),
        onPressed: () {
          context.read<OtpBloc>().add(ResendOtp(widget.shipTo, '0'));
        },
        child: const Text('Minta OTP'),
      );
    }

    // Tambahan: Tampilkan loading indicator saat meminta atau mengirim ulang OTP
    if (state is OtpLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    // Kondisi 2: Jika terjadi error
    if (state is OtpError) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _pinController.clear());
      return Text(state.message,
          key: const ValueKey('err'),
          style: const TextStyle(color: Colors.red));
    }

    // --- TAMBAHKAN BLOK INI ---
    // KONDISI BARU: Jika OTP sudah kedaluwarsa
    if (state is OtpExpired) {
      return Column(
        key: const ValueKey('expired'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Kode OTP sudah kedaluwarsa',
              style: TextStyle(color: Colors.red)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              _pinController.clear(); // Bersihkan input sebelum kirim ulang
              context.read<OtpBloc>().add(ResendOtp(widget.shipTo, '0'));
            },
            child: const Text('Kirim Ulang Kode'),
          ),
        ],
      );
    }

    // Kondisi 3: Jika akun terkunci
    if (state is OtpLocked) {
      return Text(
          'Terlalu banyak mencoba. Coba lagi dalam ${state.lockedFor.inMinutes} menit',
          key: const ValueKey('lock'),
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center);
    }

    // Kondisi 4: Jika OTP sudah terkirim & masih dalam masa cooldown
    if (state is OtpSent && state.resendCooldown > 0) {
      return Text('Kirim ulang dalam ${state.resendCooldown} detik',
          key: const ValueKey('cd'),
          style: const TextStyle(color: Colors.grey));
    }

    // Kondisi 5 (Default): Tombol untuk kirim ulang jika cooldown sudah selesai
    return TextButton(
      key: const ValueKey('resend'),
      onPressed: () {
        context.read<OtpBloc>().add(ResendOtp(widget.shipTo, '0'));
      },
      child: const Text('Tidak menerima kode? Kirim Ulang'),
    );
  }
}
