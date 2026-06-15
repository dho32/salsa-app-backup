import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
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

  static String generateHiveKey(String transNo) =>
      transNo.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  Future<void> _onLoadPhoto(
      LoadLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final key = generateHiveKey(event.transNo);
    print("📥 [BLoC] Loading Photo for Key: $key");

    final txn = transactionBox.get(key) as IPicPhotoStorable?;
    final photo = txn?.picImageDetail;

    print(key);
    print(txn);
    print(photo);

    if (photo != null) {
      // Validasi File Fisik
      if (File(photo.imagePath).existsSync()) {
        print("✅ [BLoC] Foto Ditemukan & File Ada: ${photo.imagePath}");
        final distance = await LocationHelper.calculateDistance(
          pic: photo,
          tokoLat: event.tokoLat,
          tokoLng: event.tokoLng,
        );
        emit(LocationPhotoLoaded(photo, distance: distance));
      } else {
        print(
            "❌ [BLoC] Data Hive Ada, Tapi File Fisik HILANG! Menghapus data Hive...");
        // Bersihkan data sampah
        if (txn != null) {
          txn.picImageDetail = null;
          await transactionBox.put(key, txn);
        }
        emit(const LocationPhotoLoaded(null));
      }
    } else {
      print("ℹ️ [BLoC] Tidak ada foto tersimpan untuk key ini.");
      emit(const LocationPhotoLoaded(null));
    }
  }

  Future<void> _onTakePhoto(
      TakeLocationPhoto event, Emitter<LocationValidationState> emit) async {
    emit(LocationValidationLoading());

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

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

      // GPS LOGIC
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        emit(const LocationValidationFailure(
            "Gagal mendeteksi lokasi akurat. Harap geser ke dekat jendela atau area terbuka.",
            photo: null));
        return;
      }

      final String locationString =
          "Loc: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";

      // Prepare Watermark
      final userData = await AuthStorage.getUser();
      final technicianName = userData['name'] ?? 'Unknown';
      final deviceModel = userData['device_model'] ?? 'Unknown Device';
      final timestamp = DateTime.now();

      // Ambil timezone dari device
      final zone = getIndonesianTimezoneAbbreviation(timestamp);

      // Format tanggal pakai locale (AMAN)
      final formattedDate =
          '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final targetPath = p.join(
          imagesDir.path, 'WM_PIC_${timestamp.millisecondsSinceEpoch}.jpg');

      final request = WatermarkRequest(
        originalPath: image.path,
        targetPath: targetPath,
        transNo: event.transNo,
        formattedDate: formattedDate,
        technicianName: technicianName,
        deviceModel: deviceModel,
        location: locationString,
        photoLabel: 'PIC Toko',
      );

      final String? finalImagePath =
          await WatermarkService.processImage(request);

      if (finalImagePath == null || !File(finalImagePath).existsSync()) {
        emit(const LocationValidationFailure(
            "Gagal memproses/menyimpan watermark foto",
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

      // 🔥 SIMPAN KE HIVE (SAFE METHOD)
      final key = generateHiveKey(event.transNo);
      var txn = transactionBox.get(key);

      if (txn != null && txn is IPicPhotoStorable) {
        txn.picImageDetail = detail;
        await transactionBox.put(key, txn); // Explicit PUT
        print("💾 [BLoC] Foto berhasil disimpan ke Hive: $key");
      } else {
        print(
            "⚠️ [BLoC] Transaksi tidak ditemukan di Hive ($key), foto tidak tersimpan ke database!");
        // Optional: Throw error kalau mau strict
      }

      emit(LocationPhotoLoaded(detail, distance: distance));
    } catch (e) {
      emit(LocationValidationFailure("Terjadi kesalahan: $e", photo: null));
    }
  }

  Future<void> _onRemovePhoto(
      RemoveLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final key = generateHiveKey(event.transNo);
    final txn = transactionBox.get(key) as IPicPhotoStorable?;
    if (txn != null) {
      txn.picImageDetail = null;
      await transactionBox.put(key, txn); // Explicit PUT
      print("🗑️ [BLoC] Foto dihapus dari Hive: $key");
    }
    emit(const LocationPhotoLoaded(null));
  }

  Future<void> _onSubmitValidation(SubmitLocationValidation event,
      Emitter<LocationValidationState> emit) async {
    // 🕵️ AMBIL FOTO DARI MEMORY (STATE) DULU SEBELUM LOADING
    CapturedImageDetail? currentPhoto;
    if (state is LocationPhotoLoaded) {
      currentPhoto = (state as LocationPhotoLoaded).photo;
    } else if (state is LocationValidationFailure) {
      currentPhoto = (state as LocationValidationFailure).photo;
    }

    emit(LocationValidationLoading());
    await Future.delayed(const Duration(milliseconds: 50));

    // Kalau di memory kosong, baru coba cari di Hive
    if (currentPhoto == null) {
      final key = generateHiveKey(event.transNo);
      final txn = transactionBox.get(key) as IPicPhotoStorable?;
      currentPhoto = txn?.picImageDetail;
    }

    if (currentPhoto == null) {
      emit(const LocationValidationFailure("Harap ambil foto terlebih dahulu"));
      return;
    }

    // Validasi final file exist
    if (!File(currentPhoto.imagePath).existsSync()) {
      emit(const LocationValidationFailure(
          "File foto fisik hilang. Harap ambil ulang."));
      return;
    }

    final isValid = await LocationHelper.validateLocation(
      pic: currentPhoto,
      tokoLat: event.tokoLat,
      tokoLng: event.tokoLng,
    );

    if (isValid) {
      emit(LocationValidationSuccess());
    } else {
      final distance = await LocationHelper.calculateDistance(
        pic: currentPhoto,
        tokoLat: event.tokoLat,
        tokoLng: event.tokoLng,
      );
      emit(LocationValidationFailure(
        "Lokasi foto terlalu jauh (${distance.toStringAsFixed(0)}m). Mohon ambil ulang di lokasi toko.",
        photo: currentPhoto,
        distance: distance,
      ));
    }
  }
}
