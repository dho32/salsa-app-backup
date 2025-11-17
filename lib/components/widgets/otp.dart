import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';

import 'package:salsa/blocs/otp/otp_bloc.dart';
import 'package:salsa/blocs/otp/otp_event.dart';
import 'package:salsa/blocs/otp/otp_state.dart';
import 'package:salsa/blocs/location_validation/location_validation_bloc.dart';
import 'package:salsa/blocs/location_validation/location_validation_event.dart';
import 'package:salsa/blocs/location_validation/location_validation_state.dart';

import 'package:salsa/components/shared_function.dart';

import '../../models/common/captured_image_detail.dart';
import '../constants.dart';
import '../shared_widgets.dart';

class OtpDialog extends StatefulWidget {
  final String transNo;
  final String shipTo;
  final String email;
  final double storeLat;
  final double storeLong;
  final VoidCallback onVerified;

  const OtpDialog({
    super.key,
    required this.transNo,
    required this.shipTo,
    required this.email,
    required this.storeLat,
    required this.storeLong,
    required this.onVerified,
  });

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLocationMode = false;
  bool _isErrorDialogShowing = false;

  @override
  void initState() {
    super.initState();
    context.read<OtpBloc>().add(RequestOtp(widget.transNo, widget.shipTo, '0'));
    context.read<LocationValidationBloc>().add(LoadLocationPhoto(
          widget.transNo,
          widget.storeLat,
          widget.storeLong,
        ));
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
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
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: !_isLocationMode
          ? BlocConsumer<OtpBloc, OtpState>(
              listenWhen: (_, current) =>
                  current is OtpVerified || current is OtpError,
              listener: (context, state) {
                if (state is OtpVerified) {
                  widget.onVerified();
                  Navigator.pop(context);
                }
                if (state is OtpError) {
                  if (!_isErrorDialogShowing) {
                    _isErrorDialogShowing = true; // Set flag sebelum tampilkan
                    if (_pinController.length >= 6) {
                      // Cek panjang >= 6 lebih aman
                      _pinController.clear();
                      // Minta fokus kembali setelah clear agar user bisa langsung ketik
                      _focusNode.requestFocus();
                    }
                    showFailureDialog(context, "OTP salah, coba lagi.")
                        .then((_) {
                      // ✅ RESET FLAG SETELAH DIALOG DITUTUP
                      if (mounted) {
                        // Pastikan widget masih ada
                        setState(() {
                          _isErrorDialogShowing = false;
                        });
                      }
                    });
                  } else {
                    print(
                        "ℹ️ OtpError received, but dialog already showing. Ignoring."); // Optional log
                  }
                }
              },
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Verifikasi OTP',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan 6 digit kode yang dikirim ke email ${_maskEmail(widget.email)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Pinput(
                        length: 6,
                        controller: _pinController,
                        focusNode: _focusNode,
                        autofocus: true,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        errorPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: Colors.red),
                          ),
                        ),
                        onCompleted: (pin) {
                          context.read<OtpBloc>().add(
                              VerifyOtp(widget.transNo, widget.shipTo, pin));
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildResendArea(state),
                      ),
                      if (state is OtpLocked ||
                          (state is OtpSent && state.retryLeft == 0))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.location_on),
                            label: const Text("Validasi Menggunakan Lokasi"),
                            onPressed: () {
                              setState(() => _isLocationMode = true);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          : _buildLocationValidationUI(),
    );
  }

  Widget _buildResendArea(OtpState state) {
    if (state is OtpInitial) {
      return TextButton(
        key: const ValueKey('request'),
        onPressed: () {
          context
              .read<OtpBloc>()
              .add(ResendOtp(widget.transNo, widget.shipTo, '1'));
        },
        child: const Text('Minta OTP'),
      );
    }

    if (state is OtpLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    if (state is OtpSent) {
      if (state.resendCooldown > 0) {
        return Text('Kirim ulang dalam ${state.resendCooldown} detik',
            style: const TextStyle(color: Colors.grey));
      } else {
        return TextButton(
          onPressed: () {
            _pinController.clear();
            context
                .read<OtpBloc>()
                .add(ResendOtp(widget.transNo, widget.shipTo, '1'));
          },
          child: const Text('Tidak menerima kode? Kirim Ulang'),
        );
      }
    }

    if (state is OtpLocked) {
      return Text(
        'Terlalu banyak mencoba. Coba validasi lokasi.',
        style: const TextStyle(color: Colors.orange),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPhotoInstructionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                "Panduan Foto PIC",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade800),
              ),
            ],
          ),
          const Divider(height: 12),
          _buildInstructionItem(
              "Wajah PIC terlihat jelas (Lepas Masker/Helm) dan menghadap kamera "),
          _buildInstructionItem("Wajib berlatar belakang TOKO"),
          _buildInstructionItem("Pencahayaan cukup & tidak buram"),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLocationValidationUI() {
    return BlocConsumer<LocationValidationBloc, LocationValidationState>(
      listener: (context, state) {
        if (state is LocationValidationSuccess) {
          widget.onVerified(); // ✅ langsung submit
          Navigator.pop(context); // ✅ close dialog
        }
        if (state is LocationValidationFailure) {
          showFailureDialog(context, state.message);
        }
      },
      builder: (context, state) {
        CapturedImageDetail? photoToShow;
        double? distanceToShow;
        if (state is LocationPhotoLoaded) {
          photoToShow = state.photo;
          distanceToShow = state.distance; // Ambil jarak dari state Loaded
        } else if (state is LocationValidationFailure) {
          photoToShow = state.photo;
          distanceToShow = state.distance; // Ambil jarak dari state Failure
        }
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Validasi Lokasi Pejabat Toko",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (state is LocationValidationLoading)
                const CircularProgressIndicator()
              else if (photoToShow != null) ...[
                Image.file(File(photoToShow.imagePath), height: 180),
                const SizedBox(height: 8),
                if (distanceToShow != null && distanceToShow > kDistance)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                    child: Card(
                      color: Colors.orange.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade800),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Jarak dari toko: ${NumberFormat("#,##0", "id_ID").format(distanceToShow)} meter. Lokasi terlalu jauh.",
                                style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    context
                        .read<LocationValidationBloc>()
                        .add(RemoveLocationPhoto(widget.transNo));
                  },
                  child: const Text("Hapus Foto & Ambil Ulang"),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<LocationValidationBloc>().add(
                          SubmitLocationValidation(
                            widget.transNo,
                            widget.storeLat,
                            widget.storeLong,
                          ),
                        );
                  },
                  child: const Text("Submit Validasi Lokasi"),
                ),
              ] else ...[
                _buildPhotoInstructionCard(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Ambil Foto"),
                  onPressed: () {
                    context
                        .read<LocationValidationBloc>()
                        .add(TakeLocationPhoto(
                          widget.transNo,
                          widget.storeLat,
                          widget.storeLong,
                        ));
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
