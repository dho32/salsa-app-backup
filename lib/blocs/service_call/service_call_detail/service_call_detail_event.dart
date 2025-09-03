abstract class ServiceCallDetailEvent {}

class FetchServiceCallDetail extends ServiceCallDetailEvent {
  final String transNo;
  final String vendorId;

  FetchServiceCallDetail(this.transNo, this.vendorId);
}
