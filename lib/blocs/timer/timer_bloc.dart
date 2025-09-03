import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:salsa/blocs/timer/timer_event.dart';
import 'package:salsa/blocs/timer/timer_state.dart';

class TimeBloc extends Bloc<TimeEvent, TimeState> {
  late Timer _timer;

  TimeBloc() : super(TimeState(DateTime.now())) {
    on<UpdateTime>((event, emit) {
      emit(TimeState(DateTime.now()));
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      add(UpdateTime());
    });
  }

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}