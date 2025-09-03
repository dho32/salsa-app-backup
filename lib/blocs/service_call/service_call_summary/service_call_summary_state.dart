import 'package:salsa/models/service_call/service_call_summary_model.dart';

abstract class ServiceCallSummaryState {}

class SummaryInitial extends ServiceCallSummaryState {}

class SummaryLoading extends ServiceCallSummaryState {}

class SummaryLoaded extends ServiceCallSummaryState {
  final ServiceCallSummaryModel data;
  SummaryLoaded(this.data);
}

class SummaryError extends ServiceCallSummaryState {
  final String message;
  SummaryError(this.message);
}
