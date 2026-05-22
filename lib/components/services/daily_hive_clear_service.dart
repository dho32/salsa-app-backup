import 'package:hive/hive.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';

class DailyHiveClearService {
  /// Fungsi untuk membersihkan semua data Hive yang bukan dari bulan berjalan
  static Future<void> cleanUpOldMonthData() async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      print("🧹 [CLEANUP] Memulai pembersihan data Hive selain bulan $currentMonth/$currentYear...");

      // =================================================================
      // 1. BERSIHKAN KOTAK PARSIAL / FAILED UPLOADS (Tipe Data: Map)
      // =================================================================
      final partialBoxes = [
        kPosValidationPartialHiveBox,
        kServiceCallValidationPartialHiveBox,
        kFailedUploadsBox,
        kPosUnserviceablePartialBox,
        kScUnserviceablePartialBox
      ];

      for (String boxName in partialBoxes) {
        if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map<dynamic, dynamic>>(boxName);
        final box = Hive.box<Map<dynamic, dynamic>>(boxName);
        final keysToDelete = [];

        for (var key in box.keys) {
          final data = box.get(key);
          if (data != null && data['timestamp'] != null) {
            try {
              final timestamp = DateTime.parse(data['timestamp']);
              // Jika bulan atau tahunnya beda, tandai untuk dihapus
              if (timestamp.month != currentMonth || timestamp.year != currentYear) {
                keysToDelete.add(key);
              }
            } catch (e) {
              print("Error parsing date partial box: $e");
            }
          }
        }

        if (keysToDelete.isNotEmpty) {
          await box.deleteAll(keysToDelete);
          print("🧹 [CLEANUP] Menghapus ${keysToDelete.length} data usang dari box $boxName");
        }
      }

      // =================================================================
      // 2. BERSIHKAN DRAFT INSTALLATION (Tipe Data: InstallationEntryModel)
      // =================================================================
      if (!Hive.isBoxOpen(kInstallationDraftBox)) await Hive.openBox<InstallationEntryModel>(kInstallationDraftBox);
      final instBox = Hive.box<InstallationEntryModel>(kInstallationDraftBox);
      final instKeysToDelete = [];

      for (var key in instBox.keys) {
        final draft = instBox.get(key);
        // InstallationModel punya startDate, jadi enak ngeceknya
        if (draft != null && draft.startDate != null) {
          if (draft.startDate?.month != currentMonth || draft.startDate?.year != currentYear) {
            instKeysToDelete.add(key);
          }
        }
      }
      if (instKeysToDelete.isNotEmpty) {
        await instBox.deleteAll(instKeysToDelete);
        print("🧹 [CLEANUP] Menghapus ${instKeysToDelete.length} draft usang dari Installation");
      }

      // =================================================================
      // 3. BERSIHKAN DRAFT POS & SERVICE CALL
      // =================================================================
      // (Karena Draft SC & POS nggak punya startDate di root, kita cek dari foto pertamanya)

      // Bersihkan POS
      if (!Hive.isBoxOpen(kPosValidationHiveBox)) await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
      final posBox = Hive.box<PosValidationEntryModel>(kPosValidationHiveBox);
      final posKeysToDelete = [];
      for (var key in posBox.keys) {
        final draft = posBox.get(key);
        if (draft != null && draft.photosBefore.isNotEmpty) {
          final photoDate = draft.photosBefore.first.timestamp;
          if (photoDate.month != currentMonth || photoDate.year != currentYear) {
            posKeysToDelete.add(key);
          }
        }
      }
      if (posKeysToDelete.isNotEmpty) await posBox.deleteAll(posKeysToDelete);

      // Bersihkan SC
      if (!Hive.isBoxOpen(kServiceCallHiveBox)) await Hive.openBox<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final scBox = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final scKeysToDelete = [];
      for (var key in scBox.keys) {
        final draft = scBox.get(key);
        if (draft != null && draft.imagePathsBefore.isNotEmpty) {
          final photoDate = draft.imagePathsBefore.first.timestamp;
          if (photoDate.month != currentMonth || photoDate.year != currentYear) {
            scKeysToDelete.add(key);
          }
        }
      }
      if (scKeysToDelete.isNotEmpty) await scBox.deleteAll(scKeysToDelete);

      print("✅ [CLEANUP] Proses pembersihan selesai!");

    } catch (e) {
      print("❌ [CLEANUP] Gagal melakukan pembersihan: $e");
    }
  }
}