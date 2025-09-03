class DashboardDataModel {
  final Information information;
  final LastServiceCall lastServiceCall;
  final AmScheduleMonthly amScheduleMonthly;
  final PosWeekly posWeekly;

  DashboardDataModel({
    required this.information,
    required this.lastServiceCall,
    required this.amScheduleMonthly,
    required this.posWeekly,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      information: Information.fromJson(json['information']),
      lastServiceCall: LastServiceCall.fromJson(json['last_service_call']),
      amScheduleMonthly:
      AmScheduleMonthly.fromJson(json['am_schedule_monthly']),
      posWeekly: PosWeekly.fromJson(json['pos_weekly']),
    );
  }
}

class Information {
  final int serviceCall;
  final int amSchedule;

  Information({required this.serviceCall, required this.amSchedule});

  factory Information.fromJson(Map<String, dynamic> json) {
    return Information(
      serviceCall: json['service_call'],
      amSchedule: json['am_schedule'],
    );
  }
}

class LastServiceCall {
  final int done;
  final int notDone;
  final int total;

  LastServiceCall({
    required this.done,
    required this.notDone,
    required this.total,
  });

  factory LastServiceCall.fromJson(Map<String, dynamic> json) {
    return LastServiceCall(
      done: json['done'],
      notDone: json['not_done'],
      total: json['total'],
    );
  }
}

class AmScheduleMonthly {
  final int done;
  final int notDone;
  final int total;

  AmScheduleMonthly({
    required this.done,
    required this.notDone,
    required this.total,
  });

  factory AmScheduleMonthly.fromJson(Map<String, dynamic> json) {
    return AmScheduleMonthly(
      done: json['done'],
      notDone: json['not_done'],
      total: json['total'],
    );
  }
}

class PosWeekly {
  final int sen;
  final int sel;
  final int rab;
  final int kam;
  final int jum;
  final int sab;
  final int min;

  PosWeekly({
    required this.sen,
    required this.sel,
    required this.rab,
    required this.kam,
    required this.jum,
    required this.sab,
    required this.min,
  });

  factory PosWeekly.fromJson(Map<String, dynamic> json) {
    return PosWeekly(
      sen: json['sen'],
      sel: json['sel'],
      rab: json['rab'],
      kam: json['kam'],
      jum: json['jum'],
      sab: json['sab'],
      min: json['min'],
    );
  }
}
