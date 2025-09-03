// lib/screens/proof_of_service_detail/proof_of_service_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/schedule/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_response.dart';
import 'components/proof_of_service_detail_body_mobile.dart';

class ProofOfServiceDetailScreen extends StatelessWidget {
  final String transNo;
  final POSUnitItem unit;

  const ProofOfServiceDetailScreen({
    super.key,
    required this.transNo,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProofOfServiceDetailBloc()
            ..add(FetchProofOfServiceDetail(transNo, unit)),
      child: Scaffold(
        appBar: AppBar(title: Text('Detail Unit')),
        body: ProofOfServiceDetailBodyMobile(unitType: unit.unitType),
      ),
    );
  }
}
