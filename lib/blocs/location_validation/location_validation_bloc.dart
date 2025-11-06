import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  String _getHiveKey(String transNo) =>
      transNo.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  Future<void> _onLoadPhoto(
      LoadLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final txn = transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
    final photo = txn?.picImageDetail;

    if (photo != null) {
      // Jika ada foto, hitung ulang jaraknya
      final distance = await LocationHelper.calculateDistance(
        pic: photo,
        tokoLat: event.tokoLat,
        tokoLng: event.tokoLng,
      );
      // Kirim state dengan foto DAN jaraknya
      emit(LocationPhotoLoaded(photo, distance: distance));
    } else {
      // Jika tidak ada foto, kirim state kosong
      emit(const LocationPhotoLoaded(null));
    }
  }

  Future<void> _onTakePhoto(
      TakeLocationPhoto event, Emitter<LocationValidationState> emit) async {
    emit(LocationValidationLoading());

    print("masukkkkk");

    final picker = ImagePicker();
    // Ambil gambar dengan kualitas asli terlebih dahulu
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      final txn = transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
      emit(LocationPhotoLoaded(txn?.picImageDetail));
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create();
    }
    // Buat nama file baru yang standar menggunakan timestamp
    final targetPath =
        p.join(imagesDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Kompres gambar dan simpan ke targetPath
    final XFile? compressedImage =
        await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      targetPath,
      quality: 70,
    );

    if (compressedImage == null) {
      // Handle jika kompresi gagal
      emit(LocationValidationFailure("Gagal memproses gambar.", photo: null));
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final detail = CapturedImageDetail(
      // Gunakan path dari gambar yang sudah dikompres dan diganti namanya
      imagePath: compressedImage.path,
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      address: "",
      technicianName: "Pejabat Toko",
      deviceModel: "",
      transNo: event.transNo,
    );

    final distance = await LocationHelper.calculateDistance(
      pic: detail,
      tokoLat: event.tokoLat,
      tokoLng: event.tokoLng,
    );

    print("masukkkkk lagi");

    final txn = transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
    if (txn != null) {
      txn.picImageDetail = detail;
      await txn.save();
    } else {
      // Handle jika 'txn' null (seharusnya tidak terjadi jika form cubit sudah jalan)
      print(
          "PERINGATAN: Gagal menemukan TransactionInfo/PosTransactionInfo untuk ${event.transNo}");
    }

    print("keluar");


    emit(LocationPhotoLoaded(detail, distance: distance));
  }

  Future<void> _onRemovePhoto(
      RemoveLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final txn = transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
    if (txn != null) {
      txn.picImageDetail = null;
      await txn.save();
    }
    emit(const LocationPhotoLoaded(null));
  }

  Future<void> _onSubmitValidation(SubmitLocationValidation event,
      Emitter<LocationValidationState> emit) async {
    emit(LocationValidationLoading());
    // Beri jeda singkat agar UI punya waktu untuk me-render ulang loading spinner
    await Future.delayed(const Duration(milliseconds: 50));

    final txn = transactionBox.get(_getHiveKey(event.transNo)) as IPicPhotoStorable?;
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
        // "Lokasi tidak sesuai (jarak ${distance.toStringAsFixed(1)} m)",
        "Lokasi foto tidak sesuai dengan toko terdaftar. Mohon ambil ulang di lokasi toko.",
        photo: photo,
        distance: distance, // <-- SERTAKAN NILAI JARAK DI SINI
      ));
    }
  }
}
