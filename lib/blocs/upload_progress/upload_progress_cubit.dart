import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'upload_progress_state.dart';

class UploadProgressCubit extends Cubit<UploadProgressState> {
  UploadProgressCubit() : super(const UploadProgressState(current: 0, total: 0));

  void reset() => emit(const UploadProgressState(current: 0, total: 0));

  void updateProgress(int current, int total, String s) =>
      emit(UploadProgressState(current: current, total: total));

  void setTotal(int totalToUpload) {}
}
