import 'package:equatable/equatable.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';

abstract class RROCutOffSubmitEvent extends Equatable {
  const RROCutOffSubmitEvent();

  @override
  List<Object> get props => [];
}

class SubmitRroData extends RROCutOffSubmitEvent {
  final Map<String, dynamic> payload;
  final UploadProgressCubit progressCubit;
  final String transNo;
  final String storeName;

  const SubmitRroData({
    required this.payload,
    required this.progressCubit,
    required this.transNo,
    required this.storeName,
  });

  @override
  List<Object> get props => [payload, progressCubit, transNo, storeName];
}