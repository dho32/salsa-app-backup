import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import '../../blocs/proof_of_service/pos_form/pos_form_state.dart';
import '../../blocs/service_call/sc_form/sc_form_cubit.dart';
import '../../blocs/service_call/sc_form/sc_form_state.dart';
import '../constants.dart';

Widget scPositionDropdown(BuildContext context, ScFormState formState) {
  final formCubit = context.read<ScFormCubit>();

  // Ini penting: ubah "" (string kosong) dari state menjadi null
  // agar 'hintText' bisa muncul.
  final String? currentValue = formState.picPosition.isEmpty
      ? null
      : formState.picPosition;

  return DropdownButtonFormField<String>(
    value: currentValue,
    items: kJabatanOptions.map((String jabatan) {
      return DropdownMenuItem<String>(
        value: jabatan,
        child: Text(jabatan),
      );
    }).toList(),
    onChanged: (String? newValue) {
      if (newValue != null) {
        formCubit.picPositionChanged(newValue);
        formCubit.onFieldChanged();
      }
    },
    // ✅ Dekorasi ini meniru _buildCustomTextField agar UI konsisten
    decoration: InputDecoration(
      labelText: 'Jabatan',
      hintText: 'Pilih Jabatan',
      prefixIcon: Icon(Icons.work_outline, color: Colors.grey.shade600, size: 20),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    isExpanded: true,
  );
}

Widget posPositionDropdown(BuildContext context, PosFormState formState) {
  final formCubit = context.read<PosFormCubit>();

  // Ini penting: ubah "" (string kosong) dari state menjadi null
  // agar 'hintText' bisa muncul.
  final String? currentValue = formState.picPosition.isEmpty
      ? null
      : formState.picPosition;

  return DropdownButtonFormField<String>(
    value: currentValue,
    items: kJabatanOptions.map((String jabatan) {
      return DropdownMenuItem<String>(
        value: jabatan,
        child: Text(jabatan),
      );
    }).toList(),
    onChanged: (String? newValue) {
      if (newValue != null) {
        formCubit.picPositionChanged(newValue);
        formCubit.onFieldChanged();
      }
    },
    // ✅ Dekorasi ini meniru _buildCustomTextField agar UI konsisten
    decoration: InputDecoration(
      labelText: 'Jabatan',
      hintText: 'Pilih Jabatan',
      prefixIcon: Icon(Icons.work_outline, color: Colors.grey.shade600, size: 20),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    isExpanded: true,
  );
}