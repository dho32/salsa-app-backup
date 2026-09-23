import '../common/measurement_limits.dart';

/// Konstanta domain wizard **Service Call Freezer (SCF)**.
///
/// Modul ini = tiket service call / perbaikan untuk unit **freezer**. Pola dasar
/// mengikuti Service Call (repair: Permasalahan & Solusi + AHO/OTP), tetapi:
///   - kondisi awal freezer mengikuti Cuci Freezer (POSF),
///   - pengukuran = Suhu / Ampere / Volt (TANPA PSI),
///   - unit dicocokkan lewat barcode/QR scan (bukan Tukar Unit).
///
/// Wizard 2 step:
///   - **Sebelum** : kondisi awal (suhu tiba, kondisi umum + keluhan, ketebalan
///                   bunga es, foto slot awal, catatan) + pengukuran awal.
///   - **Sesudah** : pengukuran akhir + foto slot setelah + Permasalahan & Solusi.

// --- Step Sebelum: Kondisi Awal Freezer ---
const String kScfConditionComplaint = 'Ada Keluhan';
const String kScfConditionUnused = 'Tidak terpakai';

const List<String> kScfGeneralConditions = [
  'Normal',
  kScfConditionComplaint,
  kScfConditionUnused,
];

// Daftar keluhan — muncul saat kondisi = "Ada Keluhan".
const List<String> kScfComplaintOptions = [
  'Freezer tidak dingin',
  'Freezer mati',
  'Freezer bunyi berisik',
  'Kaca pecah',
];

// Daftar alasan — muncul saat kondisi = "Tidak terpakai".
const List<String> kScfUnusedOptions = [
  'Freezer tidak terpakai di gudang',
  'Freezer tidak terpakai di luar toko',
  'Freezer tidak terpakai karena produk kosong',
];

// Label dropdown ketebalan bunga es. Keterangan ukuran dalam kurung HANYA
// untuk UI (membantu teknisi menakar) — payload hanya menerima kata pertamanya,
// lihat [scfFrostThicknessValue].
const List<String> kScfFrostThickness = [
  'Tipis (<1cm)',
  'Sedang (1-3cm)',
  'Tebal (>3cm)',
];

/// Nilai `frost_thickness` yang dikirim ke backend: **Tipis | Sedang | Tebal**.
///
/// Kembaran `posfFrostThicknessValue` di modul Cuci Freezer (sengaja tidak
/// di-share: tiap modul memegang konstantanya sendiri). Draft menyimpan label
/// UI lengkap ("Tipis (<1cm)") supaya dropdown bisa menampilkannya kembali;
/// keterangan ukuran dibuang di sini saat merakit payload. Potongan diambil
/// sebelum '(' supaya perubahan angka pada label (mis. "Sedang (1-2cm)") tidak
/// diam-diam mengubah nilai yang dikirim.
String scfFrostThicknessValue(String? label) {
  if (label == null || label.isEmpty) return '';
  final i = label.indexOf('(');
  return (i == -1 ? label : label.substring(0, i)).trim();
}

// Slot foto berlabel — dipakai untuk foto kondisi awal (Sebelum) & foto setelah
// perbaikan (Sesudah).
//
// [hint] = keterangan singkat objek yang WAJIB terlihat di foto, ditampilkan di
// bawah label pada kartu slot. Null bila labelnya sudah cukup jelas.
class ScfPhotoSlot {
  final String id;
  final String label;
  final String? hint;
  const ScfPhotoSlot(this.id, this.label, {this.hint});
}

const _scfSlotFront = ScfPhotoSlot('front', 'Tampak Depan Freezer');
const _scfSlotInside = ScfPhotoSlot('inside', 'Tampak Dalam Freezer');
const _scfSlotCondenser =
    ScfPhotoSlot('condenser', 'Tampak Ruang Mesin', hint: 'Kipas & Kompressor');

// CATATAN: slot 'display' (Display Produk) DIHAPUS dari SCF atas permintaan
// bisnis — tiket SCF adalah perbaikan unit, penataan display bukan lingkupnya.
// Kunci 'display' pada draft lama dibersihkan saat load di
// ScfValidationDropdownCubit agar tidak ikut terkirim di images_initial/after.

// Kumpulan lengkap (dipakai validasi & lookup label — urutan tidak penting).
const List<ScfPhotoSlot> kScfPhotoSlots = [
  _scfSlotFront,
  _scfSlotInside,
  _scfSlotCondenser,
];

// Urutan tampil BEFORE.
const List<ScfPhotoSlot> kScfInitialPhotoSlots = [
  _scfSlotFront,
  _scfSlotInside,
  _scfSlotCondenser,
];

// Urutan tampil AFTER.
const List<ScfPhotoSlot> kScfAfterPhotoSlots = [
  _scfSlotFront,
  _scfSlotInside,
  _scfSlotCondenser,
];

// Limit suhu saat tiba (kondisi awal) — dipakai MeasurementInputWidget step Sebelum.
const MeasurementLimits kScfArrivalTempLimit = MeasurementLimits(
  id: 'arrival_temp',
  label: 'Suhu saat tiba (°C)',
  min: -30,
  max: -1,
  unit: '°C',
  normalMin: -30,
  normalMax: -1,
);

// Alasan bila suatu pengukuran "tidak bisa diukur" (toggle skip aktif) — metode
// dropdown sama seperti SC/POS. Disimpan di MeasurementEntry.remark (pengukuran)
// / arrivalTempReason (suhu tiba).
const List<String> kScfSkipReasons = [
  'Kondisi Freezer mati',
  'Masalah listrik karena sedang mati listrik dari PLN',
  'Masalah listrik karena MCB terbakar',
  'Masalah listrik karena belum ada stopkontak',
  'Terkendala dengan alat kerja',
];

// Alasan yang mewajibkan keterangan tambahan (min. 20 huruf) + foto bukti kendala
// — pola require_remark di POS/SC.
// DUMMY: semua 5 alasan skip mewajibkan keterangan + foto bukti. Set ini HANYA
// fallback saat config server (skip_reason_options) tak ada (mis. task demo).
// PRODUCTION: require_remark diambil dari API per opsi (di-thread ke cubit/state).
const Set<String> kScfSkipReasonsRequireRemark = {
  'Kondisi Freezer mati',
  'Masalah listrik karena sedang mati listrik dari PLN',
  'Masalah listrik karena MCB terbakar',
  'Masalah listrik karena belum ada stopkontak',
  'Terkendala dengan alat kerja',
};

// --- Pengukuran (Suhu / Ampere / Volt, TANPA PSI) — dipakai step Sebelum &
// Sesudah lewat MeasurementInputWidget yang sama dengan modul lain. ---
const List<MeasurementLimits> kScfMeasurements = [
  MeasurementLimits(
    id: 'temperature',
    label: 'Suhu (°C)',
    min: -30,
    max: -1,
    unit: '°C',
    normalMin: -30,
    normalMax: -1,
  ),
  MeasurementLimits(
    id: 'ampere',
    label: 'Arus Kompresor (A)',
    min: 0.1,
    max: 8,
    unit: 'A',
    normalMin: 0.1,
    normalMax: 8,
  ),
  MeasurementLimits(
    id: 'volt',
    label: 'Tegangan (V)',
    min: 150,
    max: 300,
    unit: 'V',
    normalMin: 150,
    normalMax: 300,
  ),
];

// Id pengukuran listrik yang di-link (skip/alasan berlaku untuk keduanya) — pola
// POSF (kPosfLinkedElectricalIds). Grup: 'temperature' vs listrik (ampere+volt).
const Set<String> kScfLinkedElectricalIds = {'ampere', 'volt'};
const Set<String> kScfTempMeasurementIds = {'temperature'};
