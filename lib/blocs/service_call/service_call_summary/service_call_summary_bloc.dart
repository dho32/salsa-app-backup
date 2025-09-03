import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_summary/service_call_summary_repository.dart';
import 'service_call_summary_event.dart';
import 'service_call_summary_state.dart';

class ServiceCallSummaryBloc
    extends Bloc<ServiceCallSummaryEvent, ServiceCallSummaryState> {
  final ServiceCallSummaryRepository repository;
  final String maintenanceBy;

  ServiceCallSummaryBloc({required this.repository, required this.maintenanceBy})
      : super(SummaryInitial()) {
    on<FetchServiceCallSummary>((event, emit) async {
      emit(SummaryLoading());
      try {
        final data = await repository.fetchData(maintenanceBy: maintenanceBy);
        emit(SummaryLoaded(data));
      } catch (e) {
        emit(SummaryError(e.toString()));
      }
    });
  }
}
