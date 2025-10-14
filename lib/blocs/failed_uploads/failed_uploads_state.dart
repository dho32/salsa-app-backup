import 'package:equatable/equatable.dart';

enum FailedUploadsStatus { initial, loading, loaded, error }

enum SuccessAction {
  stayAndRefresh, // Perintah: "Tetap di halaman ini dan refresh daftarnya"
  popToHome, // Perintah: "Kembali ke halaman paling awal"
}

class FailedUploadsState extends Equatable {
  final FailedUploadsStatus status;
  final List<Map<String, dynamic>> failedTransactions;
  final String? uploadingTransNo; // Melacak transaksi yg sedang diupload
  final String? successMessage;
  final String? errorMessage;
  final SuccessAction? successAction;

  const FailedUploadsState({
    this.status = FailedUploadsStatus.initial,
    this.failedTransactions = const [],
    this.uploadingTransNo,
    this.successMessage,
    this.errorMessage,
    this.successAction,
  });

  FailedUploadsState copyWith({
    FailedUploadsStatus? status,
    List<Map<String, dynamic>>? failedTransactions,
    String? uploadingTransNo,
    bool clearUploadingTransNo = false,
    String? successMessage,
    String? errorMessage,
    SuccessAction? successAction,
  }) {
    return FailedUploadsState(
      status: status ?? this.status,
      failedTransactions: failedTransactions ?? this.failedTransactions,
      uploadingTransNo: clearUploadingTransNo
          ? null
          : uploadingTransNo ?? this.uploadingTransNo,
      successMessage: successMessage,
      errorMessage: errorMessage,
      successAction: successAction,
    );
  }

  @override
  List<Object?> get props => [
        status,
        failedTransactions,
        uploadingTransNo,
        successMessage,
        errorMessage,
        successAction,
      ];
}
