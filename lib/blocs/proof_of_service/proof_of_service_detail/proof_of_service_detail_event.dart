
abstract class ProofOfServiceDetailEvent {}

class FetchProofOfServiceDetail extends ProofOfServiceDetailEvent {
  final String transNo;

  FetchProofOfServiceDetail(this.transNo);
}