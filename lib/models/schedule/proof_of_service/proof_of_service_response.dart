
class POSHeaderData {
  final String transNo;
  final String poDate;
  final String shipToCode;
  final String shipToName;
  final String shipToAddress;
  final String branchCode;
  final String branchName;

  const POSHeaderData({
    required this.transNo,
    required this.poDate,
    required this.shipToCode,
    required this.shipToName,
    required this.shipToAddress,
    required this.branchCode,
    required this.branchName,
  });

  // Factory untuk membuat objek dari JSON
  factory POSHeaderData.fromJson(Map<String, dynamic> json) {
    return POSHeaderData(
      transNo: json['trans_no'] ?? '',
      poDate: json['po_date'] ?? '',
      shipToCode: json['ship_to_code'] ?? '',
      shipToName: json['ship_to_name'] ?? '',
      shipToAddress: json['ship_to_address'] ?? '',
      branchCode: json['branch_code'] ?? '',
      branchName: json['branch_name'] ?? '',
    );
  }
}

class PICInputData {
  final String nik;
  final String name;
  final String position;

  const PICInputData({ this.nik = '', this.name = '', this.position = '' });

  factory PICInputData.fromJson(Map<String, dynamic> json) {
    return PICInputData(
      nik: json['nik'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
    );
  }
}

class POSMeasurementData {
  final PICInputData picInput;
  final List<String> technician;
  final String temperatureIn;
  final String temperatureOut;
  final String serviceTime;

  const POSMeasurementData({
    required this.picInput,
    required this.technician,
    this.temperatureIn = '',
    this.temperatureOut = '',
    this.serviceTime = '',
  });

  factory POSMeasurementData.fromJson(Map<String, dynamic> json) {
    return POSMeasurementData(
      picInput: PICInputData.fromJson(json['pic_input']),
      technician: List<String>.from(json['technicians']),
      temperatureIn: json['temperature_in'] ?? '',
      temperatureOut: json['temperature_out'] ?? '',
      serviceTime: json['service_time'] ?? '',
    );
  }
}

class POSUnitItem {
  final String articleNo;
  final String description;
  final String serialNo;
  final String unitType;
  final String articleNameUnit;
  final bool isDetailFilled;

  const POSUnitItem({
    required this.articleNo,
    required this.description,
    required this.serialNo,
    required this.unitType,
    required this.articleNameUnit,
    this.isDetailFilled = false,
  });

  factory POSUnitItem.fromJson(Map<String, dynamic> json) {
    return POSUnitItem(
      articleNo: json['article_no'] ?? '',
      description: json['description'] ?? '',
      serialNo: json['serial_no'] ?? '',
      unitType: json['unit_type'] ?? '',
      articleNameUnit: json['article_name_unit'] ?? '',
      isDetailFilled: json['is_detail_filled'] ?? false,
    );
  }
}