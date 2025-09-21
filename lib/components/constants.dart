import 'dart:ui';

import '../models/schedule/proof_of_service/proof_of_service_detail_data.dart';

///path url
///Production
const kBaseUrl = 'dxazo32f1j.execute-api.ap-southeast-1.amazonaws.com';
const kPath = '/production/';
// ///sandbox
// const kBaseUrl = 'ujaxnyipj6.execute-api.ap-southeast-1.amazonaws.com';
// const kPath = '/sandbox/';

///Route
const kPathLanding = '/';
const kPathMain = '/main';
const kPathLogin = '/login';
const kPathServiceCallList = '/service_call/list';

///HIVE
const kServiceCallHiveBox = 'service_call_validations';
const kServiceCallValidationPartialHiveBox = 'validation_partial_cache';
const kProofOfServiceHiveBox = 'proof_of_service_detail';
const String kOutdoorUnitAssignmentsBox = 'outdoor_unit_assignments';
const kTransactionInfoHiveBox = 'transaction_info_box';
const kConfirmationQueueBox = 'confirmation_queue_box';
const kPosTransactionInfoHiveBox = 'pos_transaction_info_box';
const kPosValidationHiveBox = 'pos_validation_box';
const kPosDetailCacheBox = 'pos_detail_cache_box';
const kPosValidationPartialHiveBox = 'pos_validation_partial_cache';


//const
const kDistance = 500.0;

///Colors
final kColorBackgroundDefault = Color(0xFFD3E2ED);

///measurement
const Map<String, MeasurementLimits> kMeasurementLimits = {
  'temperature': MeasurementLimits(
      id: 'temperature',
      label: 'Suhu Indoor AC',
      min: 0,
      max: 25,
      unit: '°C',
      normalMin: 5,
      normalMax: 15),
  'volt': MeasurementLimits(
      id: 'volt',
      label: 'Tegangan',
      min: 0,
      max: 420,
      unit: 'V',
      normalMin: 200.0,
      normalMax: 240.0),
  'ampere': MeasurementLimits(
      id: 'ampere',
      label: 'Arus',
      min: 0,
      max: 15,
      unit: 'A',
      normalMin: 6.0,
      normalMax: 8.0),
  'psi': MeasurementLimits(
      id: 'psi',
      label: 'Tekanan',
      min: 0,
      max: 170,
      unit: 'PSI',
      normalMin: 100,
      normalMax: 150),
};

const Map<String, MeasurementLimits> kPOSMeasurementLimits = {
  'temperature': MeasurementLimits(
      id: 'temperature',
      label: 'Suhu Indoor AC',
      min: 4,
      max: 25,
      unit: '°C',
      normalMin: 5,
      normalMax: 15),
  'volt': MeasurementLimits(
      id: 'volt',
      label: 'Tegangan',
      min: 150,
      max: 500,
      unit: 'V',
      normalMin: 200.0,
      normalMax: 240.0),
  'ampere': MeasurementLimits(
      id: 'ampere',
      label: 'Arus',
      min: 4,
      max: 15,
      unit: 'A',
      normalMin: 6.0,
      normalMax: 8.0),
};
