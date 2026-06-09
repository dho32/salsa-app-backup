import '../common/measurement_limits.dart';

/// Konstanta domain wizard Cuci Freezer (opsi, checklist, item status, pengukuran).

// --- Step 1: Kondisi Awal ---
const List<String> kPosfGeneralConditions = [
  'Normal',
  'Ada Keluhan',
  'Tidak Beroperasi',
];

const List<String> kPosfFrostThickness = [
  'Tipis (<1cm)',
  'Sedang (1-3cm)',
  'Tebal (>3cm)',
];

// Slot foto berlabel (3 slot, semua wajib) — dipakai untuk foto kondisi awal
// (Step 1) maupun foto setelah cuci (Step 3).
class PosfPhotoSlot {
  final String id;
  final String label;
  const PosfPhotoSlot(this.id, this.label);
}

const List<PosfPhotoSlot> kPosfPhotoSlots = [
  PosfPhotoSlot('front', 'Tampak depan'),
  PosfPhotoSlot('inside', 'Dalam'),
  PosfPhotoSlot('condenser', 'Kondensor'),
];

// Limit suhu terbaca saat tiba (dipakai MeasurementInputWidget di Step 1).
const MeasurementLimits kPosfArrivalTempLimit = MeasurementLimits(
  id: 'arrival_temp',
  label: 'Suhu terbaca saat tiba (°C)',
  min: -40,
  max: 40,
  unit: '°C',
  normalMin: -30,
  normalMax: -10,
);

// --- Step 2: Proses Cuci (urutan = index pada cleaningChecklist) ---
const List<String> kPosfCleaningChecklist = [
  'Dinding dalam & rak dibersihkan',
  'Drip tray & saluran drain dibersihkan',
  'Kondensor divacuum & disikat',
  'Gasket pintu dibersihkan & dicek',
  'Eksterior bodi dilap',
  'Engsel & handle pintu dicek',
  'Pan defrost bawah unit dibersihkan',
];

// --- Step 3: Pemeriksaan Teknis ---
class PosfStatusItem {
  final String id;
  final String label;
  const PosfStatusItem(this.id, this.label);
}

const List<PosfStatusItem> kPosfRefrigerationItems = [
  PosfStatusItem('kondensor', 'Kondisi kondensor'),
  PosfStatusItem('kipas', 'Kipas kondensor / evaporator'),
  PosfStatusItem('kompresor', 'Suara kompresor'),
  PosfStatusItem('frosting', 'Pola frosting evaporator'),
  PosfStatusItem('pipa', 'Visual pipa refrigeran (oli/korosi)'),
];

const List<PosfStatusItem> kPosfElectricalItems = [
  PosfStatusItem('kabel', 'Kabel power & steker'),
  PosfStatusItem('heater', 'Kondisi heater defrost'),
  PosfStatusItem('timer', 'Timer defrost / control board'),
];

const List<PosfStatusItem> kPosfAllStatusItems = [
  ...kPosfRefrigerationItems,
  ...kPosfElectricalItems,
];

const List<String> kPosfStatusOptions = ['OK', 'Perhatian', 'Masalah'];

// Pengukuran aktual (pakai MeasurementInputWidget yang sama dengan POS).
const List<MeasurementLimits> kPosfMeasurements = [
  MeasurementLimits(
    id: 'ampere',
    label: 'Arus Kompresor (A)',
    min: 0,
    max: 30,
    unit: 'A',
    normalMin: 0,
    normalMax: 30,
  ),
  MeasurementLimits(
    id: 'volt',
    label: 'Tegangan (V)',
    min: 0,
    max: 300,
    unit: 'V',
    normalMin: 180,
    normalMax: 250,
  ),
  MeasurementLimits(
    id: 'temperature',
    label: 'Suhu Setelah Pull-down (°C)',
    min: -40,
    max: 30,
    unit: '°C',
    normalMin: -30,
    normalMax: 10,
  ),
];
