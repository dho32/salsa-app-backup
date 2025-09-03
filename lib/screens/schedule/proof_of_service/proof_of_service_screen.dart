// lib/screens/proof_of_service/proof_of_service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/schedule/proof_of_service/proof_of_service_repository.dart';
import '../../../blocs/schedule/proof_of_service/proof_of_service_bloc.dart';
import 'components/proof_of_service_body_mobile.dart';

class ProofOfServiceScreen extends StatelessWidget {
  final String transNo;

  const ProofOfServiceScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProofOfServiceBloc(repository: ProofOfServiceRepository())
            ..add(FetchPOSDetail(transNo)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Proof of Service'),
        ),
        body: const ProofOfServiceBodyMobile(),
      ),
    );
  }
}
