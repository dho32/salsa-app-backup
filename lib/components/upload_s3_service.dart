import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import '../blocs/installation/installation_repository.dart';
import '../blocs/upload_progress/upload_progress_cubit.dart';
import '../blocs/upload_progress/upload_progress_repository.dart';
import '../components/constants.dart';
import 'package:hive/hive.dart';
import 'dart:math';

import '../models/common/captured_image_detail.dart';
import '../models/installation/installation_model.dart';
import '../models/proof_of_service/pos_transaction_info_model.dart';
import '../models/proof_of_service/pos_unserviceable_model.dart';
import '../models/proof_of_service/pos_validation_entry_model.dart';
import '../models/service_call/sc_unserviceable_model.dart';
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
  final validationBox =
      await Hive.openBox<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
  final infoBox =
      await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
  final Map<String, String> localFileMap = {};
  final transactionInfo = infoBox.get(getHiveKeyForTransaction(transNo));

  if (transactionInfo?.picImageDetail != null) {
    localFileMap[transactionInfo!.picImageDetail!.imagePath.split('/').last] =
        transactionInfo.picImageDetail!.imagePath;
  }
  if (transactionInfo?.finalTemperatureInImage != null) {
    localFileMap[transactionInfo!.finalTemperatureInImage!.imagePath
        .split('/')
        .last] = transactionInfo.finalTemperatureInImage!.imagePath;
  }

  final validationEntries =
      validationBox.values.where((e) => e.transNo == transNo);
  for (final entry in validationEntries) {
    List<CapturedImageDetail> allUnitImages = [
      ...entry.imagePathsBefore,
      ...entry.imagePathsAfter,
      ...entry.measurementsBefore
          .map((m) => m.capturedImage)
          .whereType<CapturedImageDetail>(),
      ...entry.measurementsAfter
          .map((m) => m.capturedImage)
          .whereType<CapturedImageDetail>(),
      ...entry.remarkPhotosIndoorAfter ?? [],
      ...entry.remarkPhotosOutdoorAfter ?? [],
      ...entry.remarkPhotosOutdoorPsiAfter ?? [],
    ];
    for (final imageDetail in allUnitImages) {
      localFileMap[imageDetail.imagePath.split('/').last] =
          imageDetail.imagePath;
    }
  }

  List<_UploadTask> allPossibleTasks = [];
  for (var detailItem in presignedDetail) {
    final serialNo = detailItem['serial_no']?.toString() ?? 'HEADER';
    final uploads = detailItem['uploads'] as List<dynamic>? ?? [];
    for (var uploadInfo in uploads) {
      final filename = uploadInfo['filename']?.toString();
      if (filename != null &&
          filename.isNotEmpty &&
          localFileMap.containsKey(filename)) {
        final filePath = localFileMap[filename]!;
        final fileKey = '$serialNo - $filename';
        allPossibleTasks.add(_UploadTask(
            url: uploadInfo['url'], filePath: filePath, fileKey: fileKey));
      } else if (filename != null && filename.isNotEmpty) {
        print('⚠️ SC: No matching local image found for $filename. Skipping.');
      }
    }
  }

  final List<_UploadTask> tasksToExecute =
      _filterTasks(allPossibleTasks, filter);
  return _executeUploadTasks(tasksToExecute, progressCubit);
}

Future<UploadResult> uploadPosImagesToS3(
  String transNo,
  List<dynamic> presignedDetail, {
  UploadProgressCubit? progressCubit,
  List<String>? filter,
}) async {
  final validationBox =
      await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
  final infoBox =
      await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
  final Map<String, String> localFileMap = {};
  final transactionInfo = infoBox.get(getHiveKeyForTransaction(transNo));

  if (transactionInfo?.picImageDetail != null) {
    localFileMap[transactionInfo!.picImageDetail!.imagePath.split('/').last] =
        transactionInfo.picImageDetail!.imagePath;
  }
  if (transactionInfo?.temperatureInImage != null) {
    localFileMap[transactionInfo!.temperatureInImage!.imagePath
        .split('/')
        .last] = transactionInfo.temperatureInImage!.imagePath;
  }
  if (transactionInfo?.finalTemperatureInImage != null) {
    localFileMap[transactionInfo!.finalTemperatureInImage!.imagePath
        .split('/')
        .last] = transactionInfo.finalTemperatureInImage!.imagePath;
  }
  if (transactionInfo?.temperatureOutImage != null) {
    localFileMap[transactionInfo!.temperatureOutImage!.imagePath
        .split('/')
        .last] = transactionInfo.temperatureOutImage!.imagePath;
  }

  final validationEntries =
      validationBox.values.where((e) => e.transNo == transNo);
  for (final entry in validationEntries) {
    List<CapturedImageDetail> allUnitImages = [
      ...entry.photosBefore,
      ...entry.photosAfter,
      ...entry.measurementsAfter
          .map((m) => m.capturedImage)
          .whereType<CapturedImageDetail>(),
      ...entry.remarkPhotos ?? [],
    ];
    for (final imageDetail in allUnitImages) {
      localFileMap[imageDetail.imagePath.split('/').last] =
          imageDetail.imagePath;
    }
  }

  List<_UploadTask> allPossibleTasks = [];
  for (var serialData in presignedDetail) {
    final serialNo = serialData['serial_no']?.toString() ?? 'HEADER';
    final uploads = serialData['uploads'] as List<dynamic>? ?? [];
    for (var uploadInfo in uploads) {
      final filename = uploadInfo['filename']?.toString();
      if (filename != null &&
          filename.isNotEmpty &&
          localFileMap.containsKey(filename)) {
        final filePath = localFileMap[filename]!;
        final fileKey = '$serialNo - $filename';
        allPossibleTasks.add(_UploadTask(
            url: uploadInfo['url'], filePath: filePath, fileKey: fileKey));
      } else if (filename != null && filename.isNotEmpty) {
        print('⚠️ POS: No matching local image found for $filename. Skipping.');
      }
    }
  }

  final List<_UploadTask> tasksToExecute =
      _filterTasks(allPossibleTasks, filter);
  return _executeUploadTasks(tasksToExecute, progressCubit);
}

Future<UploadResult> uploadPOSUnserviceableImagesToS3(
  PosUnserviceableModel report,
  List<dynamic> presignedDetails, {
  required UploadProgressCubit progressCubit,
  List<String>? filter,
}) async {
  final Map<String, String> localFileMap = {
    for (var img in report.proofImages)
      img.imagePath.split('/').last: img.imagePath,
  };

  List<_UploadTask> allPossibleTasks = [];
  for (var uploadInfo in presignedDetails) {
    final filename = uploadInfo['filename']?.toString();
    final fileKey = filename;
    if (filename != null &&
        fileKey != null &&
        filename.isNotEmpty &&
        localFileMap.containsKey(filename)) {
      final filePath = localFileMap[filename]!;
      allPossibleTasks.add(_UploadTask(
          url: uploadInfo['url'], filePath: filePath, fileKey: fileKey));
    } else if (filename != null && filename.isNotEmpty) {
      print(
          '⚠️ POS Unserviceable: No matching local image for $filename. Skipping.');
    }
  }

  final List<_UploadTask> tasksToExecute =
      _filterTasks(allPossibleTasks, filter);
  return _executeUploadTasks(tasksToExecute, progressCubit);
}

Future<UploadResult> uploadSCUnserviceableImagesToS3(
  SCUnserviceableModel report,
  List<dynamic> presignedDetails, {
  required UploadProgressCubit progressCubit,
  List<String>? filter,
}) async {
  final Map<String, String> localFileMap = {
    for (var img in report.proofImages)
      img.imagePath.split('/').last: img.imagePath,
  };

  List<_UploadTask> allPossibleTasks = [];
  for (var uploadInfo in presignedDetails) {
    final filename = uploadInfo['filename']?.toString();
    final fileKey = filename;
    if (filename != null &&
        fileKey != null &&
        filename.isNotEmpty &&
        localFileMap.containsKey(filename)) {
      final filePath = localFileMap[filename]!;
      allPossibleTasks.add(_UploadTask(
          url: uploadInfo['url'], filePath: filePath, fileKey: fileKey));
    } else if (filename != null && filename.isNotEmpty) {
      print(
          '⚠️ SC Unserviceable: No matching local image for $filename. Skipping.');
    }
  }

  final List<_UploadTask> tasksToExecute =
      _filterTasks(allPossibleTasks, filter);
  return _executeUploadTasks(tasksToExecute, progressCubit);
}

List<_UploadTask> _filterTasks(
    List<_UploadTask> allTasks, List<String>? filter) {
  if (filter == null || filter.isEmpty) {
    return allTasks;
  }

  print("🚦 Menerapkan filter untuk retry: $filter");

  final Set<String> filterKeys = filter.map((failedFileString) {
    String keyPart = failedFileString.replaceFirst("[MISSING] ", "");
    if (keyPart.contains(" (")) {
      keyPart = keyPart.substring(0, keyPart.indexOf(" ("));
    }
    return keyPart.trim();
  }).toSet();

  print("🔑 Kunci filter yang diekstrak: $filterKeys");

  final tasksToExecute = allTasks.where((task) {
    final bool shouldUpload = filterKeys.contains(task.fileKey);
    print("  - Mengecek task key: ${task.fileKey} -> Upload? $shouldUpload");
    return shouldUpload;
  }).toList();

  print("📊 Jumlah task setelah filter: ${tasksToExecute.length}");
  return tasksToExecute;
}

Future<UploadResult> _executeUploadTasks(
  List<_UploadTask> tasksToExecute,
  UploadProgressCubit? progressCubit,
) async {
  int totalToUpload = tasksToExecute.length;
  // progressCubit?.reset();
  progressCubit?.setTotal(totalToUpload);

  if (tasksToExecute.isEmpty) {
    print("ℹ️ Tidak ada task yang perlu dieksekusi.");
    progressCubit?.updateProgress(0, 0, 'Selesai (tidak ada file)');
    return UploadResult(successCount: 0, failureCount: 0, failedFiles: []);
  }

  int successCount = 0;
  int failureCount = 0;
  List<String> failedFileDetails = [];
  List<String> missingKeys = [];
  List<String> successfulUrls = [];

  for (int i = 0; i < tasksToExecute.length; i++) {
    final task = tasksToExecute[i];
    final currentCount = i + 1;

    // Update progress SEBELUM mencoba upload file ini
    progressCubit?.updateProgress(
        currentCount, totalToUpload, 'Mengupload ${task.fileKey}...');

    try {
      final file = File(task.filePath);
      if (!await file.exists()) {
        print("🔴 File not found for task: ${task.fileKey}");
        throw Exception("file tidak ditemukan");
      }

      final bytes = await file.readAsBytes();
      final mimeType =
          lookupMimeType(task.filePath) ?? 'application/octet-stream';

      // Lakukan upload
      final response = await http
          .put(
            Uri.parse(task.url),
            headers: {'Content-Type': mimeType, 'x-amz-acl': 'public-read'},
            body: bytes,
          )
          .timeout(const Duration(minutes: 2)); // Timeout tetap bagus

      // Cek status code
      if (response.statusCode == 200) {
        successCount++;
        // await notifyBackendSuccess(task.url);
        successfulUrls.add(task.url);
        print("✅ Upload success: ${task.fileKey}");
      } else {
        // Gagal karena respons server non-200
        throw Exception("HTTP ${response.statusCode}");
      }
    } on TimeoutException {
      // Gagal karena timeout
      print("❌ Upload failed (Timeout): ${task.fileKey}");
      failureCount++;
      failedFileDetails.add("${task.fileKey} (Timeout)");
    } on SocketException catch (e) {
      // Gagal karena masalah jaringan (DNS lookup, koneksi ditolak, internet mati, dll.)
      print("❌ Upload failed (SocketException): ${task.fileKey} -> $e");
      failureCount++;
      failedFileDetails.add("${task.fileKey} (Network Error)"); // Pesan generik
    } on http.ClientException catch (e) {
      // Gagal karena masalah HTTP client lain
      print("❌ Upload failed (ClientException): ${task.fileKey} -> $e");
      failureCount++;
      failedFileDetails
          .add("${task.fileKey} (Connection Error)"); // Pesan generik
    } catch (e) {
      // Gagal karena alasan lain (file hilang, error tak terduga)
      print("❌ Upload failed (Exception): ${task.fileKey} -> $e");
      failureCount++;
      // Cek apakah error karena file hilang
      if (e.toString().contains("file tidak ditemukan")) {
        failedFileDetails.add("${task.fileKey} (file tidak ditemukan)");
        missingKeys.add(task.fileKey); // Tetap tandai missing
      } else {
        // Batasi panjang pesan error agar tidak terlalu panjang
        failedFileDetails.add(
            "${task.fileKey} (Error: ${e.toString().substring(0, min(e.toString().length, 30))}...)");
      }
    }
  }

  if (successfulUrls.isNotEmpty) {
    await notifyBackendBatch(successfulUrls);
  }

  List<String> finalFailedFiles = failedFileDetails.map((f) {
    final key = f.contains(" (") ? f.substring(0, f.indexOf(" (")) : f;
    return missingKeys.contains(key) ? "[MISSING] $f" : f;
  }).toList();

  progressCubit?.updateProgress(totalToUpload, totalToUpload, 'Selesai');

  return UploadResult(
    successCount: successCount,
    failureCount: failureCount,
    failedFiles: finalFailedFiles,
  );
}

String getHiveKeyForTransaction(String transNo) {
  return transNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

Future<InstallationUploadResult> uploadInstallationFiles({
  required Map<String, dynamic> apiResult,
  required UploadProgressCubit progressCubit,
  required InstallationEntryModel draft,
}) async {
  // A. Collect Local Paths
  Map<String, String> localFileMap = {};
  void collect(List<InstallationPhotoModel> photos) {
    for (var p in photos) {
      localFileMap[p.imageFileName] = p.imagePath;
    }
  }

  if (draft.storeFrontPhoto != null) {
    localFileMap[draft.storeFrontPhoto!.imageFileName] = draft.storeFrontPhoto!.imagePath;
  }
  if (draft.hasTransport && draft.transportEvidencePhoto != null) {
    localFileMap[draft.transportEvidencePhoto!.imageFileName] = draft.transportEvidencePhoto!.imagePath;
  }
  for (var u in draft.units) {
    for (var m in u.measurements) {
      if (m.photo != null) {
        localFileMap[m.photo!.imageFileName] = m.photo!.imagePath;
      }
    }
    collect(u.remarkPhotos);
    collect(u.remarkPhotosPsi);
  }
  for (var ev in draft.materialEvidences) {
    String fileName = ev.photoPath.split('/').last;
    localFileMap[fileName] = ev.photoPath;
  }
  collect(draft.finalPhotos);

  // B. Build Tasks
  List<Map<String, String>> uploadQueue = [];
  try {
    final details = apiResult['result']['detail'] as List;
    for (var d in details) {
      final uploads = d['uploads'] as List;
      for (var u in uploads) {
        final fname = u['filename'].toString();
        final url = u['url'].toString();
        if (localFileMap.containsKey(fname)) {
          uploadQueue.add(
              {'filename': fname, 'url': url, 'path': localFileMap[fname]!});
        } else {
          print("⚠️ Local file not found for: $fname");
        }
      }
    }
  } catch (e) {
    print("Error parsing uploads: $e");
  }

  // C. Execute Loop
  int totalFiles = uploadQueue.length;
  progressCubit.setTotal(totalFiles);

  if (totalFiles == 0) {
    progressCubit.updateProgress(0, 0, 'Selesai');
    return InstallationUploadResult(
        successCount: 0, failureCount: 0, failedFiles: []);
  }

  int successCount = 0;
  int failureCount = 0;
  List<String> failedFiles = [];
  List<String> successfulUrls = [];

  for (int i = 0; i < totalFiles; i++) {
    final task = uploadQueue[i];
    final fileName = task['filename']!;
    final url = task['url']!;
    final path = task['path']!;

    progressCubit.updateProgress(
        i + 1, totalFiles, "Mengupload ${i + 1} dari $totalFiles foto...");

    try {
      final file = File(path);
      if (!await file.exists()) throw Exception("File not found");

      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(path) ?? 'application/octet-stream';

      final response = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': mimeType, 'x-amz-acl': 'public-read'},
            body: bytes,
          )
          .timeout(const Duration(minutes: 2));

      if (response.statusCode == 200) {
        successCount++;
        // await notifyBackendSuccess(url); // Lapor Backend per file
        successfulUrls.add(url);
        print("✅ Upload success: $fileName");
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is TimeoutException) {
        errorMsg = "Timeout";
      } else if (e is SocketException) {
        errorMsg = "Network Error";
      }

      print("❌ Upload Failed: $fileName -> $errorMsg");
      failureCount++;
      failedFiles.add("$fileName ($errorMsg)");
    }
  }

  if (successfulUrls.isNotEmpty) {
    await notifyBackendBatch(successfulUrls);
  }

  return InstallationUploadResult(
      successCount: successCount,
      failureCount: failureCount,
      failedFiles: failedFiles);
}
