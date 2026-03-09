import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import '../../components/shared_function.dart';

// --- HELPER CLASSES & METHODS ---
class InstallationUploadResult {
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;

  InstallationUploadResult({
    required this.successCount,
    required this.failureCount,
    required this.failedFiles,
  });

  bool get allSuccess => failureCount == 0;
}

// --- MAIN REPOSITORY ---
class InstallationRepository {
  // --- 1. GET DETAIL ---
  Future<InstallationDetailModel> getInstallationDetail(
      String transNo, String vendorId) async {
    final params = {'trans_no': transNo, 'vendor_id': vendorId};
    Uri uri = getUrl(pathUrl: 'installation/detail', params: params);
    final response = await http.get(uri);
    try {
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK') {
          return InstallationDetailModel.fromJson(body);
        } else {
          throw Exception('API returned error: ${body['message']}');
        }
      } else {
        throw Exception('Failed to load detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: ${e.toString()}');
    }
  }

  // --- 2. VALIDATE SN ---
  Future<Map<String, dynamic>> validateSerialNumbers({
    required String transNo,
    required String vendorCode,
    required List<Map<String, String>> items,
  }) async {
    final requestBody = {
      'trans_no': transNo,
      'vendor_code': vendorCode,
      'items': items
    };

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    log("====== REQUEST BODY FINAL ======");
    log(encoder.convert(requestBody));

    Uri uri = getUrl(pathUrl: 'installation/validate/sn');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  }

  // --- 3. SUBMIT FINAL (METADATA JSON) ---
  Future<Map<String, dynamic>> submitFinalInstallation({
    required String createdBy,
    required String transNo,
    required String vendorCode,
    required InstallationEntryModel draft,
    required String remark,
    required String deviceName,
  }) async {
    // --- Helper Maps ---
    Map<String, dynamic>? mapPhoto(InstallationPhotoModel? photo) {
      if (photo == null || photo.imagePath.isEmpty) return null;
      return {
        "image_file_name": photo.imageFileName,
        "timestamp": photo.timestamp,
        "latitude": photo.latitude,
        "longitude": photo.longitude,
        "device": deviceName, // Pakai parameter deviceName
      };
    }

    List<Map<String, dynamic>> mapPhotoList(
        List<InstallationPhotoModel> photos) {
      List<Map<String, dynamic>> result = [];
      for (var p in photos) {
        final m = mapPhoto(p);
        if (m != null) result.add(m);
      }
      return result;
    }

    String mapUsageType(String appType) {
      switch (appType) {
        case 'PIPA_AC':
          return 'REFRIGERANT';
        case 'PIPA_DRAIN':
          return 'DRAIN';
        case 'KABEL_POWER':
          return 'POWER';
        case 'KABEL_CONTROL':
          return 'CONTROL';
        case 'KABEL_DUCT':
          return 'DUCT';
        default:
          return appType;
      }
    }

    // Map Article Type
    Map<String, String> articleTypeMap = {};
    for (var u in draft.units) {
      for (var p in u.materials.pipes) {
        articleTypeMap[p.articleId] = "PIPE";
      }
      for (var c in u.materials.cables) {
        articleTypeMap[c.articleId] = "CABLE";
      }
    }

    List<Map<String, dynamic>> unitsIndoor = [];
    List<Map<String, dynamic>> unitsOutdoor = [];
    List<Map<String, dynamic>> materialsPayload = [];
    List<Map<String, dynamic>> materialsImagePayload = [];

    // --- LOOPING UNIT ---
    for (var unit in draft.units) {
      List<Map<String, dynamic>> measurementsList = [];
      List<Map<String, dynamic>> installationImagesList = [];

      for (var m in unit.measurements) {
        String mId = m.measurementId.toLowerCase();
        bool isDocPhoto = mId.contains('photo') ||
            mId.contains('image') ||
            mId.contains('foto');

        if (isDocPhoto) {
          if (m.photo != null) {
            final pMap = mapPhoto(m.photo);
            if (pMap != null) installationImagesList.add(pMap);
          }
        } else {
          measurementsList.add({
            "measurement_id": mId,
            "value": m.isSkipped ? 0 : (m.value ?? 0),
            "unit": m.unit,
            "is_skipped": m.isSkipped,
            "image": m.isSkipped ? null : mapPhoto(m.photo)
          });
        }
      }

      // MAPPING INDOOR
      if (unit.articleType == 'IN') {
        unitsIndoor.add({
          "unit_index": unit.unitIndex,
          "unit_type": "IN",
          "article_no": unit.articleNo,
          "serial_no": unit.serialNo,
          "paired_serial_no": unit.pairedSerialNo ?? "",
          "reff_line_no": unit.reffLineNo,
          "note": unit.note ?? "",
          "remark": unit.remark,
          "remark_photos": mapPhotoList(unit.remarkPhotos),
          "measurements": measurementsList,
          "installation_images": installationImagesList,
        });
      }
      // MAPPING OUTDOOR
      else if (unit.articleType == 'OUT') {
        String finalNoteOutdoor = unit.note ?? "";
        String finalNotePsi = unit.notePsi;
        // Regex Parse Legacy
        if (finalNoteOutdoor.contains("[Listrik:") &&
            finalNoteOutdoor.contains("[PSI:")) {
          try {
            final regex = RegExp(r"\[Listrik:\s*(.*?)\]\s*\[PSI:\s*(.*?)\]");
            final match = regex.firstMatch(finalNoteOutdoor);
            if (match != null) {
              finalNoteOutdoor = match.group(1)?.trim() ?? finalNoteOutdoor;
              finalNotePsi = match.group(2)?.trim() ?? "";
            }
          } catch (e) {
            log("Regex parse error: $e");
          }
        }

        unitsOutdoor.add({
          "unit_index": unit.unitIndex,
          "unit_type": "OUT",
          "article_no": unit.articleNo,
          "serial_no": unit.serialNo,
          "paired_serial_no": unit.pairedSerialNo ?? "",
          "reff_line_no": unit.reffLineNo,
          "note_outdoor": finalNoteOutdoor,
          "remark_outdoor": unit.remark,
          "remark_photos_outdoor": mapPhotoList(unit.remarkPhotos),
          "note_psi": finalNotePsi,
          "remark_psi": unit.remarkPsi,
          "remark_photos_psi": mapPhotoList(unit.remarkPhotosPsi),
          "measurements": measurementsList,
          "installation_images": installationImagesList,
        });

        // MAPPING MATERIALS
        if (unit.materials.pipes.isNotEmpty ||
            unit.materials.cables.isNotEmpty) {
          List<Map<String, dynamic>> items = [];
          for (var p in unit.materials.pipes) {
            if (p.length > 0) {
              items.add({
                "material_type": "PIPE",
                "material_sub_type": mapUsageType(p.usageType),
                "article_id": p.articleId,
                "brand_id": p.brandId,
                "qty": p.length,
                "uom": "M"
              });
            }
          }
          for (var c in unit.materials.cables) {
            if (c.length > 0) {
              items.add({
                "material_type": "CABLE",
                "material_sub_type": mapUsageType(c.usageType),
                "article_id": c.articleId,
                "brand_id": c.brandId,
                "qty": c.length,
                "uom": "M"
              });
            }
          }
          if (items.isNotEmpty) {
            materialsPayload.add({
              "serial_no_indoor": unit.pairedSerialNo ?? "",
              "serial_no_outdoor": unit.serialNo,
              "materials": items,
              "mounting_type": unit.materials.mountingType,
              "has_jasa_perapihan": unit.materials.hasJasaPerapihan
            });
          }
        }
      }
    }

    // --- MAPPING MATERIALS IMAGE ---
    for (var ev in draft.materialEvidences) {
      final parts = ev.key.split('_');
      String articleId = parts.isNotEmpty ? parts[0] : "";
      String brandId = parts.length > 1 ? parts[1] : "";
      String type = articleTypeMap[articleId] ?? "PIPE";

      var imageDetail = {
        "image_file_name": ev.photoPath.split('/').last,
        "timestamp": DateTime.now().toIso8601String(),
        "latitude": 0,
        "longitude": 0,
        "device": deviceName
      };
      materialsImagePayload.add({
        "material_type": type,
        "article_id": articleId,
        "brand_id": brandId,
        "image": imageDetail
      });
    }

    final requestBody = {
      "trans_no": transNo,
      "vendor_code": vendorCode,
      "technician_1": draft.technician1Name,
      "technician_2": draft.technician2Name,
      "technician_3": draft.technician3Name,
      "start_date": draft.startDate?.toIso8601String(),
      "finish_date": DateTime.now().toIso8601String(),
      "remark": remark,
      "created_by": createdBy,
      "has_transport": draft.hasTransport,
      if (draft.hasTransport && draft.storeFrontPhoto != null)
        "store_front_image": mapPhoto(draft.storeFrontPhoto),
      if (draft.hasTransport)
        "transport_distance": draft.transportDistance,
      if (draft.hasTransport)
        "transport_distance_image": draft.transportEvidencePhoto,
      "units_indoor": unitsIndoor,
      "units_outdoor": unitsOutdoor,
      "materials": materialsPayload,
      "materials_image": materialsImagePayload,
    };

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    log("====== REQUEST BODY FINAL ======");
    log(encoder.convert(requestBody));

    Uri uri = getUrl(pathUrl: 'installation/submitted');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Submit Failed: ${response.statusCode} - ${response.body}");
    }
  }
}