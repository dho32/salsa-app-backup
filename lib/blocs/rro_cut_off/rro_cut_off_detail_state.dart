
import '../../models/rro_cut_off/rro_cut_off_detail_model.dart';

abstract class RROCutOffDetailState {}

class RROCutOffDetailInitial extends RROCutOffDetailState {}

class RROCutOffDetailLoading extends RROCutOffDetailState {}

class RROCutOffDetailLoaded extends RROCutOffDetailState {
  final RROCutOffResult data;
  RROCutOffDetailLoaded(this.data);
}

class RROCutOffDetailError extends RROCutOffDetailState {
  final String message;
  RROCutOffDetailError(this.message);
}