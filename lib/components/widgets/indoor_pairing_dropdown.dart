import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/proof_of_service/pos_pairing/pos_pairing_cubit.dart';
import '../../blocs/proof_of_service/pos_pairing/pos_pairing_state.dart';

class IndoorPairingDropdown extends StatelessWidget {
  final String outdoorSerial; // serial OUT yang sedang divalidasi
  final String? label;        // optional label
  final EdgeInsetsGeometry? padding;

  const IndoorPairingDropdown({
    super.key,
    required this.outdoorSerial,
    this.label,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosPairingCubit, PosPairingState>(
      builder: (context, pairingState) {
        final options = pairingState.availableFor(outdoorSerial);
        final current = pairingState.pairings[outdoorSerial.trim().toUpperCase()];
        final hasError = (current == null || current.isEmpty);

        return Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButtonFormField<String>(
            value: (current != null && current.isNotEmpty) ? current : null,
            items: options
                .map((sn) => DropdownMenuItem(value: sn, child: Text(sn)))
                .toList(),
            onChanged: (value) {
              context
                  .read<PosPairingCubit>()
                  .selectIndoorForOutdoor(outdoorSerial, value);
            },
            decoration: InputDecoration(
              labelText: label ?? 'Pilih Serial INDOOR (1:1)',
              border: const OutlineInputBorder(),
              errorText: hasError ? null : null, // pakai validator jika perlu
            ),
            validator: (_) {
              if ((context.read<PosPairingCubit>().state
                  .pairings[outdoorSerial.trim().toUpperCase()] ??
                  '')
                  .isEmpty) {
                return 'Wajib pilih serial INDOOR';
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
