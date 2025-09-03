import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/schedule_calendar/schedule_calendar_bloc.dart';
import '../../../components/salsa_scaffold.dart';
import '../../blocs/schedule_calendar/schedule_calendar_repository.dart';
import 'components/schedule_calendar_body_mobile.dart';

class ScheduleCalendarScreen extends StatelessWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleCalendarBloc(
        repository: ScheduleCalendarRepository(),
      )..add(FetchAllSchedules()),
      child: const SalsaScaffold(
        child: ScheduleCalendarBodyMobile(),
      ),
    );
  }
}