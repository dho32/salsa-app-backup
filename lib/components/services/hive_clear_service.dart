import 'package:hive/hive.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import 'package:salsa/models/service_call/transaction_info_model.dart';

import '../../models/proof_of_service/pos_unserviceable_model.dart';
import '../../models/proof_of_service/proof_of_service_detail_model.dart';
import '../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../../models/service_call/sc_unserviceable_model.dart';
import '../shared_function.dart';

Future<void> clearTransactionData(String transNo) async {
  print("🧹 Cleaning up Hive data for transaction: $transNo");
  final normalizedKey = getHiveKeyForTransaction(transNo);

  try {
    // Box POS
    final posValidationBox =
        await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
    final posKeysToDelete = posValidationBox.keys.cast<String>().where((key) {
      final entry = posValidationBox.get(key);
      return entry?.transNo == transNo;
    }).toList();
    await posValidationBox.deleteAll(posKeysToDelete);

    final posInfoBox =
        await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    await posInfoBox.delete(normalizedKey);

    final posPartialBox =
        await Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox);
    await posPartialBox.delete(transNo);

    final posDetailCacheBox =
        await Hive.openBox<ProofOfServiceDetailModel>(kPosDetailCacheBox);
    await posDetailCacheBox.delete(transNo);

    final posDetailBox =
        await Hive.openBox<ProofOfServiceDetailData>(kProofOfServiceHiveBox);
    await posDetailBox.delete(transNo);

    final posUnserviceAble =
        await Hive.openBox<PosUnserviceableModel>(kPosUnserviceableDraftsBox);
    await posUnserviceAble.delete(transNo);

    // Box SC
    final scValidationBox = await Hive.openBox<ServiceCallValidationEntryModel>(
        kServiceCallHiveBox);
    final scKeysToDelete = scValidationBox.keys
        .where((key) => scValidationBox.get(key)?.transNo == transNo)
        .toList();
    await scValidationBox.deleteAll(scKeysToDelete);

    final scInfoBox =
        await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
    await scInfoBox.delete(normalizedKey);

    final scPartialBox = await Hive.openBox<Map<dynamic, dynamic>>(
        kServiceCallValidationPartialHiveBox);
    await scPartialBox.delete(transNo);

    final assignmentBox =
        await Hive.openBox<Map<dynamic, dynamic>>(kOutdoorUnitAssignmentsBox);
    await assignmentBox.delete(transNo);

    final scUnserviceAble =
        await Hive.openBox<SCUnserviceableModel>(kScUnserviceableDraftsBox);
    await scUnserviceAble.delete(transNo);

    print("✅ Hive cleanup complete for: $transNo");
  } catch (e) {
    print("🔴 Error during Hive cleanup for $transNo: $e");
    // Pertimbangkan untuk melaporkan error ini (misalnya ke Crashlytics)
  }
}
