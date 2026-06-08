import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_cubit.dart';
import 'components/proof_of_service_freezer_validation_body_mobile.dart';

class ProofOfServiceFreezerValidationScreen extends StatelessWidget {
  final String transNo;
  final String serialNo;
  final bool isGeneric;
  final int unitIndex;
  final String articleNo;
  final String articleDesc;

  const ProofOfServiceFreezerValidationScreen({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.isGeneric,
    required this.unitIndex,
    required this.articleNo,
    required this.articleDesc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PosfValidationCubit(
        transNo: transNo,
        serialNo: serialNo,
        isGeneric: isGeneric,
        unitIndex: unitIndex,
        articleNo: articleNo,
        articleDesc: articleDesc,
      ),
      child: ProofOfServiceFreezerValidationBodyMobile(
        serialNo: serialNo,
        articleDesc: articleDesc,
      ),
    );
  }
}
