import '../common/measurement_limits.dart';

/// Konstanta domain wizard Cuci Freezer.
///
/// Wizard 2 step: **Sebelum** (kondisi awal) & **Sesudah** (pengukuran + foto).

// --- Step Sebelum: Kondisi Awal ---
// Kondisi = 2 dimensi digabung jadi 1 string di generalCondition:
//   fungsi   : Normal | Ada Keluhan   (penanda: kPosfConditionComplaint)
//   pemakaian: Terpakai | Tidak Terpakai (penanda: kPosfConditionUnused)
// Deteksi dimensi via posfIsComplaint()/posfIsUnused() (substring), bukan
// perbandingan string penuh, agar tahan urutan kata.
const String kPosfConditionComplaint = 'Ada Keluhan';
const String kPosfConditionUnused = 'Tidak Terpakai';

// Lawan dari kedua penanda di atas. Tidak dipakai untuk deteksi (dimensi
// dideteksi lewat posfIsComplaint()/posfIsUnused()), melainkan saat memecah
// generalCondition jadi `general_condition` + `usage_condition` di payload
// submit — lihat posfGeneralCondition()/posfUsageCondition().
const String kPosfConditionNormal = 'Normal';
const String kPosfConditionUsed = 'Terpakai';

/// Penanda kondisi "Freezer Tidak Bisa Dicuci" — kondisi ke-5 yang BERDIRI
/// SENDIRI (bukan kombinasi 2 dimensi di atas): unit ada di toko tapi tidak
/// bisa dikerjakan sama sekali. Sengaja tidak mengandung 'Tidak Terpakai'
/// maupun 'Ada Keluhan' supaya posfIsUnused()/posfIsComplaint() tidak ikut
/// menyala.
const String kPosfConditionUnwashable = 'Tidak Bisa Dicuci';

const String kPosfCondNormalUsed = 'Normal Terpakai';
const String kPosfCondNormalUnused = 'Normal Tidak Terpakai';
const String kPosfCondComplaintUsed = 'Ada Keluhan Terpakai';
const String kPosfCondComplaintUnused = 'Ada Keluhan Tidak Terpakai';
const String kPosfCondUnwashable = 'Freezer Tidak Bisa Dicuci';

/// Seluruh nilai sah `generalCondition` (gabungan 2 dimensi + kondisi yang
/// berdiri sendiri) — bentuk data yang disimpan draft. UI tidak lagi
/// menampilkannya sebagai satu daftar pilihan: sejak wizard memakai dua
/// dropdown, teknisi memilih per dimensi lewat [kPosfFunctionConditions] &
/// [kPosfUsageConditions], lalu digabung oleh [posfComposeCondition].
const List<String> kPosfGeneralConditions = [
  kPosfCondNormalUsed,
  kPosfCondNormalUnused,
  kPosfCondComplaintUsed,
  kPosfCondComplaintUnused,
  kPosfCondUnwashable,
];

/// Isi dropdown 1 — dimensi FUNGSI. "Freezer Tidak Bisa Dicuci" ikut di sini
/// karena berdiri sendiri (tidak berpasangan dengan dimensi pemakaian).
const List<String> kPosfFunctionConditions = [
  kPosfConditionNormal,
  kPosfConditionComplaint,
  kPosfCondUnwashable,
];

/// Isi dropdown 2 — dimensi PEMAKAIAN. Tidak berlaku (disembunyikan) saat
/// dropdown 1 = "Freezer Tidak Bisa Dicuci".
const List<String> kPosfUsageConditions = [
  kPosfConditionUsed,
  kPosfConditionUnused,
];

/// True bila kondisi mengandung dimensi "Ada Keluhan" (Terpakai/Tidak Terpakai).
bool posfIsComplaint(String? c) =>
    c != null && c.contains(kPosfConditionComplaint);

/// True bila kondisi mengandung dimensi "Tidak Terpakai" (Normal/Ada Keluhan).
bool posfIsUnused(String? c) => c != null && c.contains(kPosfConditionUnused);

/// True bila unit ditandai "Freezer Tidak Bisa Dicuci".
bool posfIsUnwashable(String? c) =>
    c != null && c.contains(kPosfConditionUnwashable);

/// Dimensi FUNGSI untuk payload submit (`general_condition`).
///
/// Draft menyimpan kondisi sebagai satu string gabungan 2 dimensi (mis.
/// "Ada Keluhan Tidak Terpakai"), sedangkan backend memisahnya jadi
/// `general_condition` + `usage_condition`. "Freezer Tidak Bisa Dicuci"
/// berdiri sendiri: dikirim apa adanya dengan usage kosong.
String posfGeneralCondition(String? c) {
  if (c == null || c.isEmpty) return '';
  if (posfIsUnwashable(c)) return kPosfCondUnwashable;
  return posfIsComplaint(c) ? kPosfConditionComplaint : kPosfConditionNormal;
}

/// Dimensi PEMAKAIAN untuk payload submit (`usage_condition`). Kosong untuk
/// "Freezer Tidak Bisa Dicuci" (lihat [posfGeneralCondition]).
String posfUsageCondition(String? c) {
  if (c == null || c.isEmpty || posfIsUnwashable(c)) return '';
  return posfIsUnused(c) ? kPosfConditionUnused : kPosfConditionUsed;
}

/// Kebalikan dari [posfGeneralCondition]/[posfUsageCondition]: gabungkan
/// pilihan dua dropdown jadi satu string `generalCondition` — bentuk yang
/// disimpan draft Hive, sehingga penambahan dropdown TIDAK butuh HiveField
/// baru.
///
/// - "Freezer Tidak Bisa Dicuci" berdiri sendiri: dimensi pemakaian diabaikan.
/// - [usage] null/kosong (dropdown 2 belum diisi) menghasilkan string PARSIAL
///   berisi dimensi fungsi saja. Ini sengaja: pembacanya dapat membedakan
///   "belum dipilih" dari "Terpakai" karena kedua nilai sah dimensi pemakaian
///   sama-sama memuat kata "Terpakai".
String? posfComposeCondition(String? function, String? usage) {
  if (function == null || function.isEmpty) return null;
  if (function == kPosfCondUnwashable) return kPosfCondUnwashable;
  if (usage == null || usage.isEmpty) return function;
  return '$function $usage';
}

/// Maksimal foto bukti untuk kondisi "Freezer Tidak Bisa Dicuci" — mengikuti
/// halaman laporan close (`posf_report_issue_body_mobile.dart`) yang membatasi
/// 3 foto. Kondisi lain (Ada Keluhan / Tidak Terpakai) tetap maks 5.
const int kPosfUnwashableMaxPhotos = 3;

// Daftar keluhan — muncul saat kondisi = "Ada Keluhan".
const List<String> kPosfComplaintOptions = [
  'Freezer tidak dingin',
  'Freezer mati',
  'Freezer bunyi berisik',
  'Kaca pecah',
];

// Daftar alasan — muncul saat dimensi = "Tidak Terpakai".
const List<String> kPosfUnusedOptions = [
  'Unit Freezer sudah tidak ada di toko',
  'Unit freezer sudah tidak di pakai ( ada di gudang )',
  'Unit freezer sudah tidak di pakai (Product Kosong )',
];

// Alasan kunjungan cuci freezer TIDAK BISA DISERVIS (flow close /
// proof_of_service_freezer/closed). Dipakai dropdown di layar "Freezer Tidak
// Bisa Diservis".
// NOTE(backend): berbeda dari POS, respons detail freezer belum mengirim master
// alasan close (unserviceable_reasons). Sementara hardcode di sini; ganti dengan
// data server bila master sudah tersedia.
const List<String> kPosfClosedReasons = [
  'Toko belum GO',
  'Toko tutup sementara karena banjir',
  'Toko tutup sementara karena gempa bumi',
  'Toko tutup sementara karena gunung meletus',
  'Toko tutup sementara karena kebakaran',
  'Toko tutup sementara karena perizinan',
  'Toko tutup sementara karena renovasi',
  'Unit Freezer sudah tidak ada di toko',
];

// Label dropdown ketebalan bunga es. Keterangan ukuran dalam kurung HANYA
// untuk UI (membantu teknisi menakar) — payload hanya menerima kata pertamanya,
// lihat [posfFrostThicknessValue].
const List<String> kPosfFrostThickness = [
  'Tipis (<1cm)',
  'Sedang (1-3cm)',
  'Tebal (>3cm)',
];

/// Nilai `frost_thickness` yang dikirim ke backend: **Tipis | Sedang | Tebal**.
///
/// Draft menyimpan label UI lengkap ("Tipis (<1cm)") supaya dropdown bisa
/// menampilkannya kembali; keterangan ukuran dibuang di sini saat merakit
/// payload. Potongan diambil sebelum '(' supaya perubahan angka pada label
/// (mis. "Sedang (1-2cm)") tidak diam-diam mengubah nilai yang dikirim.
String posfFrostThicknessValue(String? label) {
  if (label == null || label.isEmpty) return '';
  final i = label.indexOf('(');
  return (i == -1 ? label : label.substring(0, i)).trim();
}

// Slot foto berlabel (4 slot, semua wajib) — dipakai untuk foto kondisi awal
// (Sebelum) maupun foto setelah cuci (Sesudah).
//
// [hint] = keterangan singkat objek yang WAJIB terlihat di foto, ditampilkan di
// bawah label pada kartu slot supaya teknisi tidak salah sudut. Null bila
// labelnya sudah cukup jelas.
class PosfPhotoSlot {
  final String id;
  final String label;
  final String? hint;
  const PosfPhotoSlot(this.id, this.label, {this.hint});
}

const _posfSlotFront = PosfPhotoSlot('front', 'Tampak Depan Freezer');
const _posfSlotInside = PosfPhotoSlot('inside', 'Tampak Dalam Freezer');
const _posfSlotCondenser = PosfPhotoSlot('condenser', 'Tampak Ruang Mesin',
    hint: 'Kipas & Kompressor');
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
  min: -30,
  max: -1,
  unit: '°C',
  normalMin: -30,
  normalMax: -1,
);

// Alasan bila suatu pengukuran "tidak bisa diukur" (toggle skip aktif) —
// metode dropdown sama seperti POS. Disimpan di MeasurementEntry.remark
// (untuk pengukuran) / entry.arrivalTempReason (untuk suhu tiba).
const List<String> kPosfSkipReasons = [
  'Kondisi Freezer mati',
  'Masalah listrik karena sedang mati listrik dari PLN',
  'Masalah listrik karena MCB terbakar',
  'Masalah listrik karena belum ada stopkontak',
  'Terkendala dengan alat kerja',
];

// Alasan yang mewajibkan keterangan tambahan (min. 20 huruf) + foto bukti
// kendala — pola require_remark di POS/SC.
// DUMMY: semua 5 alasan skip mewajibkan keterangan + foto bukti. Set ini HANYA
// fallback saat config server tak ada (mis. task demo). PRODUCTION: require_remark
// diambil dari API per opsi (PosfWizardConfig.skipReasonOptions → dipakai
// _skipReasonRequiresRemark di validation body).
const Set<String> kPosfSkipReasonsRequireRemark = {
  'Kondisi Freezer mati',
  'Masalah listrik karena sedang mati listrik dari PLN',
  'Masalah listrik karena MCB terbakar',
  'Masalah listrik karena belum ada stopkontak',
  'Terkendala dengan alat kerja',
};

// --- Payload submit: penanda fase pengukuran ---
//
// Kontrak submit menggabungkan suhu sebelum & sesudah pembersihan ke dalam
// SATU list `measurements`; yang membedakan hanya `checked_status`. Keduanya
// memakai `measurement_id` yang sama ('temperature'), jadi id lokal
// 'arrival_temp' (dipakai MeasurementInputWidget di step Sebelum) TIDAK boleh
// bocor ke payload.
const String kPosfCheckedStatusBefore = 'BEFORE';
const String kPosfCheckedStatusAfter = 'AFTER';
const String kPosfTempMeasurementId = 'temperature';

// --- Step Sesudah: Pengukuran Aktual (pakai MeasurementInputWidget yang sama
// dengan POS). Hanya Suhu. ---
//
// Arus (ampere) & Tegangan (volt) DIHAPUS dari wizard cuci freezer atas
// permintaan bisnis. Field Hive-nya (`elecSkipRemark`, `elecSkipPhotos`)
// sengaja dipertahankan agar draft lama tetap terbaca, tapi sudah tidak punya
// pasangan di payload: bukti skip kini menempel per-entri measurement
// (`skip_remark` + `skip_photos`). Draft lama yang masih menyimpan entri
// 'ampere'/'volt' direkonsiliasi saat load di PosfValidationCubit.
const List<MeasurementLimits> kPosfMeasurements = [
  MeasurementLimits(
    id: 'temperature',
    label: 'Suhu setelah pembersihan (°C)',
    min: -30,
    max: -1,
    unit: '°C',
    normalMin: -30,
    normalMax: -1,
  ),
];

/// Id pengukuran yang masih dipakai wizard. Config `measurements` dari server
/// (yang masih bisa mengirim ampere/volt) disaring dengan ini lewat
/// [posfFilterMeasurements] agar pengukuran listrik tidak muncul lagi.
const Set<String> kPosfAllowedMeasurementIds = {'temperature'};

/// Saring daftar pengukuran (dari server atau konstanta) ke id yang diizinkan.
List<MeasurementLimits> posfFilterMeasurements(List<MeasurementLimits> src) =>
    src.where((m) => kPosfAllowedMeasurementIds.contains(m.id)).toList();

// --- Panduan planogram (susunan display produk) ---
//
// Hybrid: pakai URL dari server (`PosfWizardConfig.planogramUrl`) bila ada,
// jatuh ke asset bawaan bila URL kosong / gagal dimuat / config null (kondisi
// offline saat detail dibaca dari cache Hive). Ganti file asset ini bila
// planogram standar nasional berubah.
const String kPosfPlanogramAsset = 'assets/images/planogram_freezer.png';
