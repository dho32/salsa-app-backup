import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/constants.dart';
import '../../components/upload_s3_service.dart';
import '../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../models/task_maintenance/confirmation_task_queue.dart';
import 'failed_uploads_event.dart';
import 'failed_uploads_state.dart';

class FailedUploadsBloc extends Bloc<FailedUploadsEvent, FailedUploadsState> {
  final UploadProgressCubit progressCubit;
  StreamSubscription? _hiveSubscription;

  FailedUploadsBloc({
    required this.progressCubit,
  }) : super(const FailedUploadsState()) {
    on<LoadFailedUploads>(_onLoadFailedUploads);
    on<RetrySingleFailedUpload>(_onRetrySingleFailedUpload);
    _listenToHiveChanges();
  }

  void _listenToHiveChanges() async {
    final cacheBox = await Hive.openBox(kPosValidationPartialHiveBox);
    _hiveSubscription = cacheBox.watch().listen((event) {
      add(LoadFailedUploads());
    });
  }

  @override
  Future<void> close() {
    _hiveSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadFailedUploads(
      LoadFailedUploads event, Emitter<FailedUploadsState> emit) async {
    emit(state.copyWith(status: FailedUploadsStatus.loading));
    try {
      final cacheBox = await Hive.openBox(kPosValidationPartialHiveBox);
      final List<Map<String, dynamic>> failedList = [];
      for (var key in cacheBox.keys) {
        final data = Map<String, dynamic>.from(cacheBox.get(key) as Map);
        failedList.add(data);
      }
      emit(state.copyWith(
          status: FailedUploadsStatus.loaded, failedTransactions: failedList));
    } catch (e) {
      emit(state.copyWith(
          status: FailedUploadsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onRetrySingleFailedUpload(
      RetrySingleFailedUpload event, Emitter<FailedUploadsState> emit) async {
    final transNo = event.transactionData['transNo'] as String;
    final bool wasLastItem = state.failedTransactions.length == 1;
    emit(state.copyWith(uploadingTransNo: transNo));

    try {
      final type = event.transactionData['type'] as String?;
      UploadResult uploadResult;

      if (type == 'unserviceable') {
        // --- LOGIKA UNTUK LAPORAN MASALAH ---
        // Kita butuh 'report' object, jadi kita baca dari draft box
        final draftBox = await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
        final report = draftBox.get(transNo);

        if (report == null) {
          throw Exception("Draft laporan masalah untuk $transNo tidak ditemukan.");
        }

        uploadResult = await uploadPOSUnserviceableImagesToS3(
          report,
          event.transactionData['presignedDetail'] as List<dynamic>,
          progressCubit: progressCubit,
          filter: List<String>.from(event.transactionData['failedFiles']),
        );

      } else {
        uploadResult = await uploadPosImagesToS3(
          transNo,
          event.transactionData['presignedDetail'] as List<dynamic>,
          progressCubit: progressCubit,
          filter: List<String>.from(event.transactionData['failedFiles']),
        );
      }

      // Logika setelah upload (ini sudah benar)
      if (uploadResult.allSuccess) {
        // Hapus dari kotak retry jika berhasil
        final retryBox = await Hive.openBox(kPosValidationPartialHiveBox);
        await retryBox.delete(transNo);
        final action = wasLastItem ? SuccessAction.popToHome : SuccessAction.stayAndRefresh;
        emit(state.copyWith(
          successMessage: 'Upload untuk $transNo berhasil!',
          clearUploadingTransNo: true,
          successAction: action,
        ));

        final queueBox =
        await Hive.openBox<ConfirmationTaskModel>(kConfirmationQueueBox);
        final task =
        ConfirmationTaskModel(transNo: transNo.trim().toUpperCase());
        await queueBox.put(transNo.trim().toUpperCase(), task);
      } else {
        throw Exception("Masih ada ${uploadResult.failureCount} foto yang gagal di-upload.");
      }

    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        clearUploadingTransNo: true,
      ));
    }
  }
}
