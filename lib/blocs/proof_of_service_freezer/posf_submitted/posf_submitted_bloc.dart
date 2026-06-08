import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../components/upload_s3_service.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_entry_model.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';
import '../../upload_progress/upload_progress_cubit.dart';
import 'posf_submitted_repository.dart';

part 'posf_submitted_event.dart';
part 'posf_submitted_state.dart';

class PosfSubmittedBloc extends Bloc<PosfSubmittedEvent, PosfSubmittedState> {
  final PosfSubmittedRepository repository;

  PosfSubmittedBloc({required this.repository}) : super(PosfSubmittedInitial()) {
    on<SubmitPosfValidation>(_onSubmit);
  }

  String _key(String t) =>
      t.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  Future<void> _onSubmit(
      SubmitPosfValidation event, Emitter<PosfSubmittedState> emit) async {
    emit(PosfSubmitting());
    try {
      final entryBox =
          await Hive.openBox<ProofOfServiceFreezerEntryModel>(kProofOfServiceFreezerEntryBox);
      final infoBox =
          await Hive.openBox<ProofOfServiceFreezerInfoModel>(kProofOfServiceFreezerInfoBox);

      final tx = event.transNo.trim().toUpperCase();
      final entries =
          entryBox.values.where((e) => e.transNo.trim().toUpperCase() == tx).toList();
      if (entries.isEmpty) {
        emit(const PosfSubmitFailure('Belum ada freezer yang divalidasi.'));
        return;
      }
      final info = infoBox.get(_key(event.transNo));

      final items = entries
          .map((e) => {
                'serial_no': e.serialNo,
                'article_no': e.articleNo,
                'article_desc': e.articleDesc,
                'arrival_temp': e.arrivalTemp,
                'arrival_temp_image':
                    e.arrivalTempImage?.imagePath.split('/').last,
                'general_condition': e.generalCondition,
                'frost_thickness': e.frostThickness,
                'initial_note': e.initialNote,
                'cleaning_checklist': e.cleaningChecklist,
                'cleaning_product': e.cleaningProduct,
                'status_flags': e.statusFlags,
                'measurements': e.measurements
                    .map((m) => {
                          'measurement_id': m.measurementId,
                          'value': m.value,
                          'unit': m.unit,
                          'is_skipped': m.isSkipped ?? false,
                          if (m.capturedImage != null)
                            'image_file_name':
                                m.capturedImage!.imagePath.split('/').last,
                        })
                    .toList(),
                'images_initial': e.initialPhotos
                    .map((k, v) => MapEntry(k, v.imagePath.split('/').last)),
                'images_after': e.afterPhotos
                    .map((k, v) => MapEntry(k, v.imagePath.split('/').last)),
              })
          .toList();

      final result = await repository.submit(
        transNo: tx,
        createdBy: event.createdBy,
        createdByName: event.createdByName,
        createdByIp: event.createdByIP,
        info: info,
        items: items,
      );

      if (result['status'] == 'OK') {
        emit(PosfUploadInProgress());
        final presignedDetail =
            (result['result']?['detail'] as List<dynamic>?) ?? <dynamic>[];

        final uploadResult = await uploadProofOfServiceFreezerImagesToS3(
          tx,
          presignedDetail,
          progressCubit: event.progressCubit,
        );

        if (uploadResult.allSuccess) {
          await _clearDrafts(event.transNo, entryBox, infoBox);
          emit(PosfSubmitSuccess());
        } else {
          final cleanFailed =
              uploadResult.failedFiles.map((f) => f.split(' (').first).toList();
          final cacheBox =
              await Hive.openBox<Map<dynamic, dynamic>>(kProofOfServiceFreezerPartialBox);
          await cacheBox.put(event.transNo, {
            'transNo': event.transNo,
            'failedFiles': cleanFailed,
            'presignedDetail': presignedDetail,
            'storeName': _storeName(event.transNo),
            'module': kProofOfServiceFreezerModuleType,
          });
          emit(PosfUploadPartial(
            successCount: uploadResult.successCount,
            failureCount: uploadResult.failureCount,
            failedFiles: cleanFailed,
            transNo: event.transNo,
          ));
        }
      } else {
        emit(PosfSubmitFailure(result['message']?.toString() ?? 'Submit gagal.'));
      }
    } catch (e) {
      emit(PosfSubmitFailure(e.toString()));
    }
  }

  String _storeName(String transNo) {
    try {
      if (Hive.isBoxOpen(kProofOfServiceFreezerDetailBox)) {
        return Hive.box<ProofOfServiceFreezerDetailModel>(kProofOfServiceFreezerDetailBox)
                .get(_key(transNo))
                ?.header
                ?.shipToName ??
            '';
      }
    } catch (_) {}
    return '';
  }

  Future<void> _clearDrafts(
    String transNo,
    Box<ProofOfServiceFreezerEntryModel> entryBox,
    Box<ProofOfServiceFreezerInfoModel> infoBox,
  ) async {
    final tx = transNo.trim().toUpperCase();
    final keys = entryBox.keys
        .where((k) => entryBox.get(k)?.transNo.trim().toUpperCase() == tx)
        .toList();
    await entryBox.deleteAll(keys);
    await infoBox.delete(_key(transNo));
  }
}
