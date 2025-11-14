import 'dart:ui';

import 'package:salsa/components/shared_function.dart';

import '../models/common/measurement_limits.dart';

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
const kSCDetailCacheBox = 'sc_detail_cache_box';
const kPosValidationPartialHiveBox = 'pos_validation_partial_cache';
// const kPosUnserviceableVisitQueueBox = 'unserviceable_visit_queue_box';
const kPosUnserviceableDraftsBox = 'unserviceable_drafts_box';
const kScUnserviceableDraftsBox = 'sc_unserviceable_drafts';
const String kPosUnserviceablePartialBox = 'pos_unserviceable_partial_cache';
const String kScUnserviceablePartialBox = 'sc_unserviceable_partial_cache';
const kAppConfigBox = 'app_config_cache_box';

///string
const kStringDialogUnitProblem = """
Ditemukan unit AC bermasalah yang belum memiliki tiket Service Call aktif pada toko ini.

Mohon koordinasikan dengan PIC toko untuk melakukan input complaint terlebih dahulu. 
Setelah complaint dibuat, Pekerjaan Service/Cleaning ini baru dapat diselesaikan di aplikasi SALSA.""";

const kStringDialogUpdateLocation = """
Masukkan alamat email toko. 
Lokasi toko akan diambil secara otomatis dari lokasi anda saat ini.""";

const List<String> kJabatanOptions = ["COS", "ACOS", "CREW"];

///const
const kDistance = 500.0;

///Colors
final kColorBackgroundDefault = Color(0xFFD3E2ED);

///measurement
final Map<String, MeasurementLimits> kSCMeasurementLimitsBefore = {
  'temperature': MeasurementLimits(
    id: 'temperature',
    label: 'Suhu Pipa Indoor (°C)',
    min: 4,
    max: 25,
    unit: '°C',
    normalMin: 5,
    normalMax: 15,
  ),
  'volt': MeasurementLimits(
    id: 'volt',
    label: 'Volt',
    min: 150,
    max: 500,
    unit: 'V',
    normalMin: 200.0,
    normalMax: 240.0,
  ),
  'ampere': MeasurementLimits(
    id: 'ampere',
    label: 'Ampere',
    min: 1,
    max: 15,
    unit: 'A',
    normalMin: 6.0,
    normalMax: 8.0,
  ),
  'psi': MeasurementLimits(
    id: 'psi',
    label: 'Tekanan (PSI)',
    min: 10,
    max: 170,
    unit: 'PSI',
    normalMin: 100,
    normalMax: 150,
  ),
};

const Map<String, MeasurementLimits> kMeasurementLimits = {
  'temperature': MeasurementLimits(
    id: 'temperature',
    label: 'Suhu Indoor AC',
    min: 4,
    max: 25,
    unit: '°C',
    normalMin: 5,
    normalMax: 15,
  ),
  'volt': MeasurementLimits(
    id: 'volt',
    label: 'Tegangan',
    min: 150,
    max: 500,
    unit: 'V',
    normalMin: 200.0,
    normalMax: 240.0,
  ),
  'ampere': MeasurementLimits(
    id: 'ampere',
    label: 'Arus',
    min: 4,
    max: 15,
    unit: 'A',
    normalMin: 6.0,
    normalMax: 8.0,
  ),
  'psi': MeasurementLimits(
    id: 'psi',
    label: 'Tekanan',
    min: 50,
    max: 170,
    unit: 'PSI',
    normalMin: 100,
    normalMax: 150,
  ),
  'final_temp_in_sc': MeasurementLimits(
      id: 'final_temp_in_sc',
      label: 'Suhu Dalam Ruangan',
      // Label dasar
      min: 4,
      // Batas bawah default (akan ditimpa oleh BLoC)
      max: 30,
      // Batas atas
      unit: '°C',
      normalMin: 5,
      normalMax: 18),
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

final kIndoorLimits = MeasurementLimits(
    id: 'temp_in',
    label: 'Suhu Dalam',
    min: 20,
    max: 35,
    normalMax: 20,
    normalMin: 35,
    unit: '°C');

final kOutdoorLimits = MeasurementLimits(
    id: 'temp_out',
    label: 'Suhu Luar',
    min: 20,
    max: 50,
    normalMax: 20,
    normalMin: 50,
    unit: '°C');
