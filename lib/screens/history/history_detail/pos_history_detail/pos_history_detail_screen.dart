import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/history_detail/proof_of_service/pos_history_detail_bloc.dart';
import '../../../../blocs/history_detail/proof_of_service/pos_history_detail_event.dart';
import '../../../../blocs/history_detail/proof_of_service/pos_history_detail_repository.dart';
import 'components/pos_history_detail_body_mobile.dart';

class PosHistoryDetailScreen extends StatelessWidget {
  final String transNo;

  const PosHistoryDetailScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PosHistoryDetailBloc(PosHistoryDetailRepository())
        ..add(FetchPosHistoryDetail(transNo)), // Langsung minta data
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detail Transaksi"),
        ),
        body: const PosHistoryDetailBodyMobile(),
      ),
    );
  }
}