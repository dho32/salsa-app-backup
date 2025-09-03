import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/history_detail/service_call/sc_history_detail_bloc.dart';
import '../../../../blocs/history_detail/service_call/sc_history_detail_event.dart';
import '../../../../blocs/history_detail/service_call/sc_history_detail_repository.dart';
import 'components/sc_history_detail_body_mobile.dart';

class ScHistoryDetailScreen extends StatelessWidget {
  final String transNo;

  const ScHistoryDetailScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScHistoryDetailBloc(ScHistoryDetailRepository())
        ..add(FetchScHistoryDetail(transNo)), // Langsung minta data
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detail Transaksi"),
        ),
        body: const ScHistoryDetailBodyMobile(),
      ),
    );
  }
}