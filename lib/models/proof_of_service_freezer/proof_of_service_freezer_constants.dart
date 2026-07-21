import '../common/measurement_limits.dart';

/// Konstanta domain wizard Cuci Freezer.
///
/// Wizard 2 step: **Sebelum** (kondisi awal) & **Sesudah** (pengukuran + foto).

// --- Step Sebelum: Kondisi Awal ---
const String kPosfConditionComplaint = 'Ada Keluhan';
const String kPosfConditionUnused = 'Tidak terpakai';

const List<String> kPosfGeneralConditions = [
  'Normal',
  kPosfConditionComplaint,
  kPosfConditionUnused,
];

// Daftar keluhan — muncul saat kondisi = "Ada Keluhan".
const List<String> kPosfComplaintOptions = [
  'Freezer tidak dingin',
  'Freezer mati',
  'Freezer bunyi berisik',
  'Kaca pecah',
];

// Daftar alasan — muncul saat kondisi = "Tidak terpakai".
const List<String> kPosfUnusedOptions = [
  'Freezer tidak terpakai di gudang',
  'Freezer tidak terpakai di luar toko',
  'Freezer tidak terpakai karena produk kosong',
];

const List<String> kPosfFrostThickness = [
  'Tipis (<1cm)',
  'Sedang (1-3cm)',
  'Tebal (>3cm)',
];

// Slot foto berlabel (3 slot, semua wajib) — dipakai untuk foto kondisi awal
// (Sebelum) maupun foto setelah cuci (Sesudah).
class PosfPhotoSlot {
  final String id;
  final String label;
  const PosfPhotoSlot(this.id, this.label);
}

const _posfSlotFront = PosfPhotoSlot('front', 'Tampak Depan Freezer');
const _posfSlotInside = PosfPhotoSlot('inside', 'Tampak Dalam Freezer');
const _posfSlotCondenser = PosfPhotoSlot('condenser', 'Tampak Ruang Mesin');
const _posfSlotDisplay = PosfPhotoSlot('display', 'Display Produk');

// Kumpulan lengkap (dipakai validasi & lookup label — urutan tidak penting).
const List<PosfPhotoSlot> kPosfPhotoSlots = [
  _posfSlotFront,
  _posfSlotInside,
  _posfSlotCondenser,
  _posfSlotDisplay,
];

// Urutan tampil BEFORE: Display Produk difoto dulu (sebelum bongkar).
const List<PosfPhotoSlot> kPosfInitialPhotoSlots = [
  _posfSlotDisplay,
  _posfSlotFront,
  _posfSlotInside,
  _posfSlotCondenser,
];

// Urutan tampil AFTER: Display Produk terakhir (tata display dulu, baru foto).
const List<PosfPhotoSlot> kPosfAfterPhotoSlots = [
  _posfSlotFront,
  _posfSlotInside,
  _posfSlotCondenser,
  _posfSlotDisplay,
];

// Limit suhu sebelum pembersihan (dipakai MeasurementInputWidget di step Sebelum).
const MeasurementLimits kPosfArrivalTempLimit = MeasurementLimits(
  id: 'arrival_temp',
  label: 'Suhu sebelum pembersihan (°C)',
  min: -40,
  max: 40,
  unit: '°C',
  normalMin: -30,
  normalMax: -10,
);

// Alasan bila suatu pengukuran "tidak bisa diukur" (toggle skip aktif) —
// metode dropdown sama seperti POS. Disimpan di MeasurementEntry.remark
// (untuk pengukuran) / entry.arrivalTempReason (untuk suhu tiba).
const List<String> kPosfSkipReasons = [
  'Unit mati total',
  'Akses terbatas',
  'Alat ukur tidak tersedia',
  'Kondisi tidak aman',
  'Lainnya',
];

// Alasan yang mewajibkan keterangan tambahan (min. 20 huruf) + foto bukti
// kendala — pola require_remark di POS/SC.
// NOTE(backend): saat master catatan POSF tersedia dari server, ganti set
// hardcode ini dengan flag require_remark dari respons detail.
const Set<String> kPosfSkipReasonsRequireRemark = {
  'Alat ukur tidak tersedia',
  'Lainnya',
};

// --- Step Sesudah: Pengukuran Aktual (pakai MeasurementInputWidget yang sama
// dengan POS). Urutan: Suhu, Arus (Ampere), Tegangan (Voltage). ---
const List<MeasurementLimits> kPosfMeasurements = [
  MeasurementLimits(
    id: 'temperature',
    label: 'Suhu setelah pembersihan (°C)',
    min: -40,
    max: 30,
    unit: '°C',
    normalMin: -30,
    normalMax: 10,
  ),
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
];
