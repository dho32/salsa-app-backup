import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import '../blocs/upload_progress/upload_progress_cubit.dart';
import '../components/constants.dart';
import 'package:hive/hive.dart';

import '../models/common/captured_image_detail.dart';
import '../models/proof_of_service/pos_transaction_info_model.dart';
import '../models/proof_of_service/pos_validation_entry_model.dart';
import '../models/service_call/transaction_info_model.dart';

class UploadResult {
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;

  UploadResult({
    required this.successCount,
    required this.failureCount,
    required this.failedFiles,
  });

  bool get allSuccess => failureCount == 0;
}

// Helper class (pastikan ini ada di atas fungsi Anda)
class _UploadTask {
  final String url;
  final String filePath;
  final String fileKey;

  _UploadTask(
      {required this.url, required this.filePath, required this.fileKey});
}

Future<UploadResult> uploadAllImagesToS3(
  String transNo,
  List<dynamic> presignedDetail, {
  UploadProgressCubit? progressCubit,
  List<String>? filter,
}) async {
  // ==================== MULAI AREA DEBUG ====================
  final validationBox = await Hive.openBox<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
  final infoBox = await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);

  final Map<String, String> localFileMap = {};

  final transactionInfo = infoBox.get(getHiveKeyForTransaction(transNo));
  if (transactionInfo?.picImageDetail != null) {
    final imageDetail = transactionInfo!.picImageDetail!;
    final filename = imageDetail.imagePath.split('/').last;
    localFileMap[filename] = imageDetail.imagePath;
  }

  final validationEntries = validationBox.values.where((e) => e.transNo == transNo);
  for (final entry in validationEntries) {
    List<CapturedImageDetail> allUnitImages = [
      ...entry.imagePathsBefore, ...entry.imagePathsAfter,
      ...entry.measurementsBefore.map((m) => m.capturedImage).whereType<CapturedImageDetail>(),
      ...entry.measurementsAfter.map((m) => m.capturedImage).whereType<CapturedImageDetail>(),
    ];
    for (final imageDetail in allUnitImages) {
      final filename = imageDetail.imagePath.split('/').last;
      localFileMap[filename] = imageDetail.imagePath;
    }
  }

  List<_UploadTask> allPossibleTasks = [];
  for (var detailItem in presignedDetail) {
    final serialNo = detailItem['serial_no'] ?? 'PIC_PHOTO'; // Beri ID default jika serial_no null
    final uploads = detailItem['uploads'] as List<dynamic>;

    for (var uploadInfo in uploads) {
      final filename = uploadInfo['filename'];
      if (localFileMap.containsKey(filename)) {
        final filePath = localFileMap[filename]!;
        final fileKey = '$serialNo - $filename';
        allPossibleTasks.add(_UploadTask(url: uploadInfo['url'], filePath: filePath, fileKey: fileKey));
      } else {
        print('Warning: No matching local image found for $filename. Skipping.');
      }
    }
  }

  final List<_UploadTask> tasksToExecute;
  if (filter != null && filter.isNotEmpty) {
    // MODIFIKASI START: Perbarui logika filter
    tasksToExecute = allPossibleTasks.where((task) {
      // Cek apakah ada salah satu item di filter yang persis sama dengan fileKey tugas ini
      // atau dimulai dengan fileKey (tergantung format failedFiles Anda)
      return filter.contains(task.fileKey);
      // Jika failedFiles formatnya "serialNo - filename (ErrorType)", maka gunakan startsWith:
      // return filter.any((filterItem) => filterItem.startsWith(task.fileKey));
    }).toList();
    // MODIFIKASI END
  } else {
    tasksToExecute = allPossibleTasks;
  }

  // Sisa kode tidak diubah
  int totalToUpload = tasksToExecute.length;
  int currentCount = 0;
  progressCubit?.reset();
  progressCubit?.updateProgress(currentCount, totalToUpload);

  if (tasksToExecute.isEmpty) {
    return UploadResult(successCount: 0, failureCount: 0, failedFiles: []);
  }

  int successCount = 0;
  int failureCount = 0;
  List<String> failedFiles = [];

  for (final task in tasksToExecute) {
    if (!File(task.filePath).existsSync()) {
      failureCount++;
      failedFiles.add("${task.fileKey} (file tidak ditemukan)");
    } else {
      final file = File(task.filePath);
      final mimeType =
          lookupMimeType(task.filePath) ?? 'application/octet-stream';
      try {
        final response = await http.put(
          Uri.parse(task.url),
          headers: {'Content-Type': mimeType, 'x-amz-acl': 'public-read'},
          body: file.readAsBytesSync(),
        );
        if (response.statusCode == 200) {
          successCount++;
        } else {
          failureCount++;
          failedFiles.add("${task.fileKey} (HTTP ${response.statusCode})");
        }
      } catch (e) {
        failureCount++;
        failedFiles.add("${task.fileKey} (Exception)");
      }
    }
    currentCount++;
    progressCubit?.updateProgress(currentCount, totalToUpload);
  }

  return UploadResult(
    successCount: successCount,
    failureCount: failureCount,
    failedFiles: failedFiles,
  );
}

Future<UploadResult> uploadPosImagesToS3(
    String transNo,
    List<dynamic> presignedDetail, {
      UploadProgressCubit? progressCubit,
      List<String>? filter,
    }) async {

  // Buka kedua box yang relevan
  final validationBox = await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
  final infoBox = await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);

  // --- LANGKAH 1: Kumpulkan SEMUA gambar lokal ke dalam satu peta ---
  final Map<String, String> localFileMap = {};

  // a. Ambil foto PIC dari info transaksi
  final transactionInfo = infoBox.get(getHiveKeyForTransaction(transNo));
  if (transactionInfo?.picImageDetail != null) {
    final imageDetail = transactionInfo!.picImageDetail!;
    final filename = imageDetail.imagePath.split('/').last;
    localFileMap[filename] = imageDetail.imagePath;
  }

  if (transactionInfo?.temperatureIn != null) {
    final imageDetail = transactionInfo!.temperatureInImage!;
    final filename = imageDetail.imagePath.split('/').last;
    localFileMap[filename] = imageDetail.imagePath;
  }

  if (transactionInfo?.temperatureOut != null) {
    final imageDetail = transactionInfo!.temperatureOutImage!;
    final filename = imageDetail.imagePath.split('/').last;
    localFileMap[filename] = imageDetail.imagePath;
  }

  // b. Ambil semua foto dari setiap validasi unit
  final validationEntries = validationBox.values.where((e) => e.transNo == transNo);
  for (final entry in validationEntries) {
    // Gabungkan semua list foto dari satu entre
    List<CapturedImageDetail> allUnitImages = [
      ...entry.photosBefore,
      ...entry.photosAfter,
      ...entry.measurementsAfter.map((m) => m.capturedImage).whereType<CapturedImageDetail>(),
    ];
    // Masukkan ke dalam peta
    for (final imageDetail in allUnitImages) {
      final filename = imageDetail.imagePath.split('/').last;
      localFileMap[filename] = imageDetail.imagePath;
    }
  }

  // --- LANGKAH 2: Bangun daftar tugas upload berdasarkan data dari server ---
  List<_UploadTask> allPossibleTasks = [];
  for (var serialData in presignedDetail) {
    final serialNo = serialData['serial_no'];
    final uploads = serialData['uploads'] as List<dynamic>;

    for (var uploadInfo in uploads) {
      final filename = uploadInfo['filename'];
      // Cari filename di dalam peta gambar lokal kita
      if (localFileMap.containsKey(filename)) {
        final filePath = localFileMap[filename]!;
        final fileKey = '$serialNo - $filename';
        allPossibleTasks.add(_UploadTask(url: uploadInfo['url'], filePath: filePath, fileKey: fileKey));
      } else {
        print('Warning: No matching local image found for $filename. Skipping upload for this file.');
      }
    }
  }

  final List<_UploadTask> tasksToExecute;
  if (filter != null && filter.isNotEmpty) {
    // MODIFIKASI START: Perbarui logika filter
    tasksToExecute = allPossibleTasks.where((task) {
      // Cek apakah ada salah satu item di filter yang persis sama dengan fileKey tugas ini
      // atau dimulai dengan fileKey (tergantung format failedFiles Anda)
      return filter.contains(task.fileKey);
      // Jika failedFiles formatnya "serialNo - filename (ErrorType)", maka gunakan startsWith:
      // return filter.any((filterItem) => filterItem.startsWith(task.fileKey));
    }).toList();
    // MODIFIKASI END
  } else {
    tasksToExecute = allPossibleTasks;
  }

  // Sisa kode tidak diubah
  int totalToUpload = tasksToExecute.length;
  int currentCount = 0;
  progressCubit?.reset();
  progressCubit?.updateProgress(currentCount, totalToUpload);

  if (tasksToExecute.isEmpty) {
    return UploadResult(successCount: 0, failureCount: 0, failedFiles: []);
  }

  int successCount = 0;
  int failureCount = 0;
  List<String> failedFiles = [];

  for (final task in tasksToExecute) {
    if (!File(task.filePath).existsSync()) {
      failureCount++;
      failedFiles.add("${task.fileKey} (file tidak ditemukan)");
    } else {
      final file = File(task.filePath);
      final mimeType =
          lookupMimeType(task.filePath) ?? 'application/octet-stream';
      try {
        final response = await http.put(
          Uri.parse(task.url),
          headers: {'Content-Type': mimeType, 'x-amz-acl': 'public-read'},
          body: file.readAsBytesSync(),
        );
        if (response.statusCode == 200) {
          successCount++;
        } else {
          failureCount++;
          failedFiles.add("${task.fileKey} (HTTP ${response.statusCode})");
        }
      } catch (e) {
        failureCount++;
        failedFiles.add("${task.fileKey} (Exception)");
      }
    }
    currentCount++;
    progressCubit?.updateProgress(currentCount, totalToUpload);
  }

  return UploadResult(
    successCount: successCount,
    failureCount: failureCount,
    failedFiles: failedFiles,
  );
}
