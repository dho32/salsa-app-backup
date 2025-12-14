import 'dart:io';
import 'package:hive/hive.dart';

// --- Import Konstanta ---
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/shared_function.dart';

// --- Import Model POS ---
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/proof_of_service/pos_unserviceable_model.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';
import 'package:salsa/models/schedule/proof_of_service/proof_of_service_detail_data.dart';

// --- Import Model SC ---
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import 'package:salsa/models/service_call/transaction_info_model.dart';
import 'package:salsa/models/service_call/sc_unserviceable_model.dart';

Future<void> clearTransactionData(String transNo) async {
  final normalizedKey = getHiveKeyForTransaction(transNo);
  final List<String> pathsToDelete = [];

  try {
    // ==========================================================
    // BAGIAN 1: PROOF OF SERVICE (POS)
    // ==========================================================

    // Box: POS Validation Entries
    final posValidationBox =
        await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
    final List<String> posKeysToDelete = [];

    for (final key in posValidationBox.keys.cast<String>()) {
      final entry = posValidationBox.get(key);
      if (entry != null && entry.transNo == transNo) {
        posKeysToDelete.add(key);
        // Kumpulkan path
        for (var p in entry.photosBefore) {
          pathsToDelete.add(p.imagePath);
        }
        for (var p in entry.photosAfter) {
          pathsToDelete.add(p.imagePath);
        }
        for (var m in entry.measurementsAfter) {
          if (m.capturedImage?.imagePath != null) {
            pathsToDelete.add(m.capturedImage!.imagePath);
          }
        }
      }
    }
    await posValidationBox.deleteAll(posKeysToDelete); // Hapus data Hive

    // Box: POS Info (Draft Utama)
    final posInfoBox =
        await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    final posInfo = posInfoBox.get(normalizedKey); // Ambil data dulu
    if (posInfo != null) {
      if (posInfo.picImageDetail?.imagePath != null) {
        pathsToDelete.add(posInfo.picImageDetail!.imagePath);
      }
      if (posInfo.temperatureInImage?.imagePath != null) {
        pathsToDelete.add(posInfo.temperatureInImage!.imagePath);
      }
      if (posInfo.temperatureOutImage?.imagePath != null) {
        pathsToDelete.add(posInfo.temperatureOutImage!.imagePath);
      }
      if (posInfo.finalTemperatureInImage?.imagePath != null) {
        pathsToDelete.add(posInfo.finalTemperatureInImage!.imagePath);
      }
    }
    await posInfoBox.delete(normalizedKey); // Hapus data Hive

    // Box: POS Unserviceable
    final posUnserviceAble =
        await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
    final unserviceable = posUnserviceAble.get(transNo); // Ambil data dulu
    if (unserviceable != null) {
      // (Asumsi model POS juga 'photos' atau 'proofImages', sesuaikan jika perlu)
      for (var p in unserviceable.proofImages) {
        pathsToDelete.add(p.imagePath);
      }
    }
    await posUnserviceAble.delete(transNo); // Hapus data Hive

    // Box: POS Lainnya (Langsung Hapus)
    final posPartialBox =
        await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
    await posPartialBox.delete(transNo);
    final posDetailCacheBox =
        await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
    await posDetailCacheBox.delete(transNo);
    final posDetailBox =
        await Hive.openBox<ProofOfServiceDetailData>(kProofOfServiceHiveBox);
    await posDetailBox.delete(transNo);

    // ==========================================================
    // BAGIAN 2: SERVICE CALL (SC)
    // ==========================================================

    // Box: SC Validation Entries
    final scValidationBox = await Hive.openBox<ServiceCallValidationEntryModel>(
        kServiceCallHiveBox);
    final List<dynamic> scKeysToDelete = [];

    for (final key in scValidationBox.keys) {
      final entry = scValidationBox.get(key);
      if (entry != null && entry.transNo == transNo) {
        scKeysToDelete.add(key);
        // Logic dari File 22
        for (var p in entry.imagePathsBefore) {
          pathsToDelete.add(p.imagePath);
        }
        for (var p in entry.imagePathsAfter) {
          pathsToDelete.add(p.imagePath);
        }
        for (var m in entry.measurementsBefore) {
          if (m.capturedImage?.imagePath != null) {
            pathsToDelete.add(m.capturedImage!.imagePath);
          }
        }
        for (var m in entry.measurementsAfter) {
          if (m.capturedImage?.imagePath != null) {
            pathsToDelete.add(m.capturedImage!.imagePath);
          }
        }
      }
    }
    await scValidationBox.deleteAll(scKeysToDelete); // Hapus data Hive

    // Box: SC Info (Draft Utama)
    final scInfoBox =
        await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
    final scInfo = scInfoBox.get(normalizedKey); // Ambil data dulu
    if (scInfo != null) {
      if (scInfo.picImageDetail?.imagePath != null) {
        pathsToDelete.add(scInfo.picImageDetail!.imagePath);
      }
      if (scInfo.finalTemperatureInImage?.imagePath != null) {
        pathsToDelete.add(scInfo.finalTemperatureInImage!.imagePath);
      }
    }
    await scInfoBox.delete(normalizedKey); // Hapus data Hive

    // Box: SC Unserviceable
    final scUnserviceAble =
        await Hive.openBox<SCUnserviceableModel>(kScUnserviceableDraftsBox);
    final scUnserviceable = scUnserviceAble.get(transNo); // Ambil data dulu
    if (scUnserviceable != null) {
      for (var p in scUnserviceable.proofImages) {
        pathsToDelete.add(p.imagePath);
      }
    }
    await scUnserviceAble.delete(transNo); // Hapus data Hive

    // Box: SC Lainnya (Langsung Hapus)
    final scPartialBox = await Hive.openBox<Map<dynamic, dynamic>>(
        kServiceCallValidationPartialHiveBox);
    await scPartialBox.delete(transNo);
    final assignmentBox = await Hive.openBox(kOutdoorUnitAssignmentsBox);
    await assignmentBox.delete(transNo);

    print("✅ Hive cleanup complete for: $transNo");
  } catch (e) {
    print("🔴 Error during Hive cleanup for $transNo: $e");
  }

  // ==========================================================
  // BAGIAN 3: HAPUS FILE FISIK
  // ==========================================================

  print("🧹 Deleting physical draft files...");

  final uniquePaths = pathsToDelete.toSet();
  int deletedCount = 0;

  for (final path in uniquePaths) {
    try {
      if (path.isEmpty) continue; // Keamanan

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        deletedCount++;
      }
    } catch (e) {
      print("🟡 Warning: Failed to delete file $path: $e");
    }
  }
  print("✅ Physical file cleanup complete: $deletedCount files deleted.");
}
