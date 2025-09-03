import '../../../models/service_call/service_call_list_model.dart';

abstract class ServiceCallListState {}

class ServiceCallListInitial extends ServiceCallListState {}

class ServiceCallListLoading extends ServiceCallListState {}

class ServiceCallListLoaded extends ServiceCallListState {
  final List<ServiceCallListModel> list;
  final bool hasMore;

  ServiceCallListLoaded({required this.list, required this.hasMore});
}

class ServiceCallListError extends ServiceCallListState {
  final String message;

  ServiceCallListError(this.message);
}
