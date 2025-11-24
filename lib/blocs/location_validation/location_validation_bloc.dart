import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../components/shared_function.dart';
import 'location_validation_event.dart';
import 'location_validation_state.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/i_pic_photo_storable.dart';
import '../../components/services/watermark_service.dart';
import '../auth/auth_storage.dart';

class LocationValidationBloc
    extends Bloc<LocationValidationEvent, LocationValidationState> {
  final Box transactionBox;

  LocationValidationBloc({required this.transactionBox})
      : super(LocationValidationInitial()) {
    on<LoadLocationPhoto>(_onLoadPhoto);
    on<TakeLocationPhoto>(_onTakePhoto);
    on<RemoveLocationPhoto>(_onRemovePhoto);
    on<SubmitLocationValidation>(_onSubmitValidation);
  }

  String _getHiveKey(String transNo) => transNo.trim().toUpperCase();

  Future<void> _onLoadPhoto(
      LoadLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final txn =
        transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
    final photo = txn?.picImageDetail;

    if (photo != null) {
      final distance = await LocationHelper.calculateDistance(
        pic: photo,
        tokoLat: event.tokoLat,
        tokoLng: event.tokoLng,
      );
      emit(LocationPhotoLoaded(photo, distance: distance));
    } else {
      emit(const LocationPhotoLoaded(null));
    }
  }

  Future<void> _onTakePhoto(
      TakeLocationPhoto event, Emitter<LocationValidationState> emit) async {
    emit(LocationValidationLoading());

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image == null) {
        add(LoadLocationPhoto(event.transNo, event.tokoLat, event.tokoLng));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final String locationString =
          "Loc: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";

      // 1. Siapkan Data User (Untuk Watermark)
      final userData = await AuthStorage.getUser();
      final technicianName = userData['name'] ?? 'Unknown';
      final deviceModel = userData['device_model'] ?? 'Unknown Device';
      final timestamp = DateTime.now();

      // 2. Siapkan Directory Permanen
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }

      // 3. Tentukan Path Tujuan (Prefix WM_PIC_)
      final targetPath = p.join(
          imagesDir.path, 'WM_PIC_${timestamp.millisecondsSinceEpoch}.jpg');

      // 4. PROSES WATERMARK
      final request = WatermarkRequest(
        originalPath: image.path,
        targetPath: targetPath,
        transNo: event.transNo,
        timestamp: timestamp,
        technicianName: technicianName,
        deviceModel: deviceModel,
        location: locationString,
      );

      final String? finalImagePath =
          await WatermarkService.processImage(request);

      if (finalImagePath == null) {
        emit(const LocationValidationFailure("Gagal memproses watermark foto",
            photo: null));
        return;
      }

      final detail = CapturedImageDetail(
        imagePath: finalImagePath,
        timestamp: timestamp,
        latitude: position.latitude,
        longitude: position.longitude,
        address: "",
        technicianName: technicianName,
        deviceModel: deviceModel,
        transNo: event.transNo,
      );

      final distance = await LocationHelper.calculateDistance(
        pic: detail,
        tokoLat: event.tokoLat,
        tokoLng: event.tokoLng,
      );

      // 6. Simpan ke Hive (via Interface)
      final txn =
          transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
      if (txn != null) {
        txn.picImageDetail = detail;
        await txn.save();
      } else {
        print(
            "PERINGATAN: Gagal menemukan TransactionInfo/PosTransactionInfo untuk ${event.transNo}");
      }

      emit(LocationPhotoLoaded(detail, distance: distance));
    } catch (e) {
      emit(LocationValidationFailure("Terjadi kesalahan: $e", photo: null));
    }
  }

  Future<void> _onRemovePhoto(
      RemoveLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final txn =
        transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
    if (txn != null) {
      txn.picImageDetail = null;
      await txn.save();
    }
    emit(const LocationPhotoLoaded(null));
  }

  Future<void> _onSubmitValidation(SubmitLocationValidation event,
      Emitter<LocationValidationState> emit) async {
    emit(LocationValidationLoading());
    await Future.delayed(const Duration(milliseconds: 50));

    final txn =
        transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
    final photo = txn?.picImageDetail;

    if (photo == null) {
      emit(const LocationValidationFailure("Harap ambil foto terlebih dahulu"));
      return;
    }

    final isValid = await LocationHelper.validateLocation(
      pic: photo,
      tokoLat: event.tokoLat,
      tokoLng: event.tokoLng,
    );

    if (isValid) {
      emit(LocationValidationSuccess());
    } else {
      final distance = await LocationHelper.calculateDistance(
        pic: photo,
        tokoLat: event.tokoLat,
        tokoLng: event.tokoLng,
      );
      emit(LocationValidationFailure(
        "Lokasi foto tidak sesuai dengan toko terdaftar. Mohon ambil ulang di lokasi toko.",
        photo: photo,
        distance: distance,
      ));
    }
  }
}
