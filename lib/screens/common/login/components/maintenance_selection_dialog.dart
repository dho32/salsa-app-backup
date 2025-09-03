import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/auth/auth_bloc.dart';
import 'package:salsa/blocs/auth/auth_event.dart';
import 'package:salsa/models/auth/maintenance_info_model.dart';

class MaintenanceSelectionDialog extends StatefulWidget {
  final List<MaintenanceInfo> options;
  final String token;

  const MaintenanceSelectionDialog(
      {super.key, required this.options, required this.token});

  @override
  State<MaintenanceSelectionDialog> createState() =>
      _MaintenanceSelectionDialogState();
}

class _MaintenanceSelectionDialogState
    extends State<MaintenanceSelectionDialog> {
  MaintenanceInfo? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.options.isNotEmpty) _selected = widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Otorisasi'),
      content: DropdownButtonFormField<MaintenanceInfo>(
        value: _selected,
        items: widget.options.map((opt) {
          return DropdownMenuItem<MaintenanceInfo>(
            value: opt,
            child: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.5, // Contoh: ambil 50% lebar layar
              child: Text(
                opt.maintenanceByName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selected = value),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        FilledButton(
          onPressed: _selected == null
              ? null
              : () {
                  context
                      .read<AuthBloc>()
                      .add(MaintenanceSelected(_selected!, widget.token));
                  Navigator.pop(context);
                },
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }
}
