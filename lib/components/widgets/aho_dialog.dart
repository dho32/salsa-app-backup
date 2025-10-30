import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salsa/blocs/service_call/sc_form/sc_form_state.dart'; // Sesuaikan path import ini

class AhoDialog extends StatefulWidget {
  final ScFormState formState;
  final Function(String ahoNumber) onSubmit;
  final String? initialAho;

  const AhoDialog({
    super.key,
    required this.formState,
    required this.onSubmit,
    this.initialAho,
  });

  @override
  State<AhoDialog> createState() => _AhoDialogState();
}

class _AhoDialogState extends State<AhoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _ahoController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ahoController = TextEditingController(text: widget.initialAho ?? '');
  }

  @override
  void dispose() {
    _ahoController.dispose();
    super.dispose();
  }

  void _submit() {
    // 1. Validasi form
    if (_formKey.currentState?.validate() ?? false) {
      final ahoNumber = _ahoController.text.trim();

      // 2. Panggil callback onSubmit (yang akan kirim event ke BLoC)
      widget.onSubmit(ahoNumber);

      // 3. Tutup dialog AHO
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Input Nomor AHO'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sistem mendeteksi adanya solusi AHO. Silakan masukkan nomor AHO untuk melanjutkan.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _ahoController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nomor AHO',
                border: OutlineInputBorder(),
                hintText: 'Contoh: AHO/2025/10/0001',
              ),
              // Validasi tidak boleh kosong
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor AHO tidak boleh kosong';
                }
                return null;
              },
              inputFormatters: [
                TextInputFormatter.withFunction(
                      (oldValue, newValue) =>
                      newValue.copyWith(text: newValue.text.toUpperCase()),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Lanjut ke OTP'),
        ),
      ],
    );
  }
}