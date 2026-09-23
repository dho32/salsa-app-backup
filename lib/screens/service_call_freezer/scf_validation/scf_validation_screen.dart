import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/service_call_freezer/scf_validation_dropdown/scf_validation_dropdown_cubit.dart';
import '../../../models/common/measurement_limits.dart';
import '../../../models/common/note_option.dart';
import '../../../models/service_call/problem_source_model.dart';
import 'components/scf_validation_body_mobile.dart';

/// Layar wizard validasi 1 freezer Service Call (2 step: Sebelum & Sesudah).
class ScfValidationScreen extends StatelessWidget {
  final String transNo;
  final String serialNo;
  final bool isGeneric;
  final int unitIndex;
  final String articleNo;
  final String articleDesc;

  /// Nama toko (untuk watermark foto). Boleh kosong.
  final String storeName;

  /// Master Permasalahan & Solusi (dari detail) untuk step Sesudah.
  final List<ProblemSourceModel> problems;

  /// Config skip-reason dari server (detail) — menentukan require_remark.
  final List<NoteOption> skipReasonOptions;

  /// Override batas pengukuran dari server per step (kosong → konstanta lokal).
  final Map<String, MeasurementLimits> customLimitsBefore;
  final Map<String, MeasurementLimits> customLimitsAfter;

  const ScfValidationScreen({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.isGeneric,
    required this.unitIndex,
    required this.articleNo,
    required this.articleDesc,
    this.storeName = '',
    this.problems = const [],
    this.skipReasonOptions = const [],
    this.customLimitsBefore = const {},
    this.customLimitsAfter = const {},
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScfValidationDropdownCubit(
        transNo: transNo,
        serialNo: serialNo,
        isGeneric: isGeneric,
        unitIndex: unitIndex,
        articleNo: articleNo,
        articleDesc: articleDesc,
        skipReasonOptions: skipReasonOptions,
      ),
      child: ScfValidationBodyMobile(
        serialNo: serialNo,
        articleDesc: articleDesc,
        storeName: storeName,
        problems: problems,
        skipReasonOptions: skipReasonOptions,
        customLimitsBefore: customLimitsBefore,
        customLimitsAfter: customLimitsAfter,
      ),
    );
  }
}
