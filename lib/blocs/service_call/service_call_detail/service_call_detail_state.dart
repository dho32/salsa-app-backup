import 'package:salsa/models/service_call/service_call_detail_model.dart';

abstract class ServiceCallDetailState {}

class ServiceCallDetailInitial extends ServiceCallDetailState {}

class ServiceCallDetailLoading extends ServiceCallDetailState {}

class ServiceCallDetailLoaded extends ServiceCallDetailState {
  final ServiceCallDetailModel data;

  ServiceCallDetailLoaded(this.data);
}

class ServiceCallDetailError extends ServiceCallDetailState {
  final String message;

  ServiceCallDetailError(this.message);
}
