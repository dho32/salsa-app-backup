import 'package:flutter_bloc/flutter_bloc.dart';
import 'rro_form_state.dart';

class RROFormCubit extends Cubit<RROFormState> {
  RROFormCubit() : super(const RROFormState());

  void picNameChanged(String value) => emit(state.copyWith(picName: value));
  void picPhoneChanged(String value) => emit(state.copyWith(picPhone: value));
  void picNikChanged(String value) => emit(state.copyWith(picNik: value));
  void picPositionChanged(String value) => emit(state.copyWith(picPosition: value));

  void technician1Changed(String value) => emit(state.copyWith(technician1: value));
  void technician2Changed(String value) => emit(state.copyWith(technician2: value));
  void technician3Changed(String value) => emit(state.copyWith(technician3: value));

  void toggleTechnician3(bool show) {
    emit(state.copyWith(
        showTechnician3: show,
        technician3: show ? state.technician3 : '' // Kosongkan jika di-hide
    ));
  }
}