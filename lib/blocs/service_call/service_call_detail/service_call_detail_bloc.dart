import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_event.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_state.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_repository.dart';

class ServiceCallDetailBloc
    extends Bloc<ServiceCallDetailEvent, ServiceCallDetailState> {
  final ServiceCallDetailRepository repository;

  ServiceCallDetailBloc(this.repository) : super(ServiceCallDetailInitial()) {
    on<FetchServiceCallDetail>((event, emit) async {
      emit(ServiceCallDetailLoading());
      try {
        final result = await repository.fetchServiceCallDetail(
            event.transNo, event.vendorId);
        emit(ServiceCallDetailLoaded(result));
      } catch (e) {
        emit(ServiceCallDetailError(e.toString()));
      }
    });
  }
}
