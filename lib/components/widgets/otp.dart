import 'dart:io';
import 'package:flutter/gestures.dart';
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
  final bool isPhotoExisting;

  const OtpDialog({
    super.key,
    required this.transNo,
    required this.shipTo,
    required this.email,
    required this.storeLat,
    required this.storeLong,
    required this.onVerified,
    required this.isPhotoExisting,
  });

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  bool _showLocationUI = false;
  bool _isLoading = false;
  bool _isErrorDialogShowing = false;

  @override
  void initState() {
    super.initState();

    print(widget.isPhotoExisting);

    context.read<OtpBloc>().add(CheckOtpStatus(widget.transNo,
        hasExistingPhoto: widget.isPhotoExisting));

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

    return BlocBuilder<LocationValidationBloc, LocationValidationState>(
      builder: (context, locationState) {
        bool hasPhoto = false;
        if (locationState is LocationPhotoLoaded &&
            locationState.photo != null) {
          hasPhoto = true;
        } else if (locationState is LocationValidationFailure &&
            locationState.photo != null) {
          hasPhoto = true;
        }

        final bool shouldShowLocation = _showLocationUI || hasPhoto;

        return MultiBlocListener(
          listeners: [
            BlocListener<LocationValidationBloc, LocationValidationState>(
              listener: (context, state) {
                if (state is LocationValidationSuccess) {
                  widget.onVerified();
                }
                if (state is LocationValidationFailure) {
                  showFailureDialog(context, state.message);
                }
                if (state is LocationPhotoLoaded && state.photo != null) {
                  if (_showLocationUI) setState(() => _showLocationUI = false);
                }
              },
            ),
          ],
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: shouldShowLocation
                ? _buildLocationValidationUI(locationState)
                : _buildOtpContainer(defaultPinTheme),
          ),
        );
      },
    );
  }

  Widget _buildOtpContainer(PinTheme defaultPinTheme) {
    return BlocListener<OtpBloc, OtpState>(
      listenWhen: (_, current) =>
          current is OtpVerified ||
          current is OtpError ||
          current is OtpLoading ||
          current is OtpSent,
      listener: (context, state) {
        if (state is OtpLoading) {
          setState(() => _isLoading = true);
        } else if (state is OtpSent) {
          setState(() => _isLoading = false);
        } else if (state is OtpVerified) {
          widget.onVerified();
        } else if (state is OtpError) {
          setState(() => _isLoading = false);
          if (!_isErrorDialogShowing) {
            _isErrorDialogShowing = true;
            if (_pinController.length >= 6) {
              _pinController.clear();
              _focusNode.requestFocus();
            }
            showFailureDialog(context, state.message).then((_) {
              if (mounted) setState(() => _isErrorDialogShowing = false);
            });
          }
        }
      },
      child: BlocBuilder<OtpBloc, OtpState>(
        builder: (context, state) {
          if (state is OtpInitial) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Verifikasi OTP',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Kode OTP akan dikirim ke email Toko.",
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<OtpBloc>().add(
                            RequestOtp(widget.transNo, widget.shipTo, '1'));
                      },
                      child: const Text("Minta Kode OTP"),
                    ),
                  )
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  const Text('Verifikasi OTP',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      'Masukkan kode OTP dari email: ${_maskEmail(widget.email)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Pinput(
                    length: 6,
                    controller: _pinController,
                    focusNode: _focusNode,
                    autofocus: true,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border:
                            Border.all(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: Colors.red),
                      ),
                    ),
                    onCompleted: (pin) {
                      context
                          .read<OtpBloc>()
                          .add(VerifyOtp(widget.transNo, widget.shipTo, pin));
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildResendArea(state),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResendArea(OtpState state) {
    if (state is OtpSent) {
      if (state.retryLeft == 0) {
        return Column(
          key: const ValueKey('limit_reached'),
          children: [
            const Text("Batas permintaan OTP habis.",
                style: TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text("Gunakan Validasi Lokasi",
                    style: TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() => _showLocationUI = true);
                },
              ),
            ),
          ],
        );
      }

      if (state.cooldown > 0) {
        return Text('Kirim ulang dalam ${state.cooldown} detik',
            key: const ValueKey('timer'),
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold));
      } else {
        return TextButton(
          key: const ValueKey('resend_btn'),
          onPressed: () {
            _pinController.clear();
            context
                .read<OtpBloc>()
                .add(ResendOtp(widget.transNo, widget.shipTo, '0'));
          },
          child: const Text('Tidak menerima kode? Kirim Ulang'),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildLocationValidationUI(LocationValidationState state) {
    CapturedImageDetail? photoToShow;
    double? distanceToShow;

    if (state is LocationPhotoLoaded) {
      photoToShow = state.photo;
      distanceToShow = state.distance;
    } else if (state is LocationValidationFailure) {
      photoToShow = state.photo;
      distanceToShow = state.distance;
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
            Image.file(
              File(photoToShow.imagePath),
              cacheWidth: 800,
              cacheHeight: 800,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (distanceToShow != null && distanceToShow > kDistance)
              _buildDistanceWarning(distanceToShow),

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

            // 🔥 Reset Button (Muncul jika expired)
            _buildResetButtonIfAvailable(),
          ] else ...[
            _buildPhotoInstructionCard(),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Ambil Foto"),
              onPressed: () {
                context.read<LocationValidationBloc>().add(TakeLocationPhoto(
                      widget.transNo,
                      widget.storeLat,
                      widget.storeLong,
                    ));
              },
            ),

            // 🔥 Reset Button (Muncul jika expired)
            _buildResetButtonIfAvailable(),
          ],
        ],
      ),
    );
  }

  Widget _buildResetButtonIfAvailable() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, otpState) {
        bool showReset = false;

        if (otpState is OtpInitial) {
          showReset = true;
        } else if (otpState is OtpSent && otpState.canReset) {
          showReset = true;
        }

        if (showReset) {
          return Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 12), // default text color
                children: [
                  const TextSpan(text: 'OTP dapat diajukan kembali. ', ),
                  TextSpan(
                    text: 'klik untuk reset.',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.read<OtpBloc>().add(ResetOtp(widget.transNo));
                        context.read<LocationValidationBloc>().add(RemoveLocationPhoto(widget.transNo));
                        setState(() => _showLocationUI = false);
                      },
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDistanceWarning(double distance) {
    return Padding(
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
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Jarak dari toko: ${NumberFormat("#,##0", "id_ID").format(distance)} meter. Lokasi terlalu jauh.",
                  style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
