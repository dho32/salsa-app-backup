abstract class RROCutOffDetailEvent {}

class FetchRROCutOffDetail extends RROCutOffDetailEvent {
  final String transNo;
  final String vendorId;
  FetchRROCutOffDetail(this.transNo, this.vendorId);
}