import 'package:equatable/equatable.dart';

abstract class FailedUploadsEvent extends Equatable {
  const FailedUploadsEvent();
  @override
  List<Object> get props => [];
}

// Event untuk memuat daftar dari Hive
class LoadFailedUploads extends FailedUploadsEvent {}

// Event untuk mencoba upload ulang satu transaksi
class RetrySingleFailedUpload extends FailedUploadsEvent {
  final Map<String, dynamic> transactionData;

  const RetrySingleFailedUpload(this.transactionData);

  @override
  List<Object> get props => [transactionData];
}