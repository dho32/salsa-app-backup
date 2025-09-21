import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../../components/constants.dart';
import '../../components/shared_function.dart';
import 'location_validation_event.dart';
import 'location_validation_state.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';

class LocationValidationBloc
    extends Bloc<LocationValidationEvent, LocationValidationState> {
  LocationValidationBloc() : super(LocationValidationInitial()) {
    on<LoadLocationPhoto>(_onLoadPhoto);
    on<TakeLocationPhoto>(_onTakePhoto);
    on<RemoveLocationPhoto>(_onRemovePhoto);
    on<SubmitLocationValidation>(_onSubmitValidation);
  }

  Future<void> _onLoadPhoto(
      LoadLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final box = Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    final txn = box.get(event.transNo);
    emit(LocationPhotoLoaded(txn?.picImageDetail));
  }

  Future<void> _onTakePhoto(
      TakeLocationPhoto event, Emitter<LocationValidationState> emit) async {
    emit(LocationValidationLoading());

    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (pickedFile == null) {
      final box = Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
      final txn = box.get(event.transNo);
      emit(LocationPhotoLoaded(txn?.picImageDetail));
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final detail = CapturedImageDetail(
      imagePath: pickedFile.path,
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      address: "",
      technicianName: "Pejabat Toko",
      deviceModel: "",
      transNo: event.transNo,
    );

    final box = Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    final txn = box.get(event.transNo);
    if (txn != null) {
      txn.picImageDetail = detail;
      await txn.save();
    }

    emit(LocationPhotoLoaded(detail));
  }

  Future<void> _onRemovePhoto(
      RemoveLocationPhoto event, Emitter<LocationValidationState> emit) async {
    final box = Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    final txn = box.get(event.transNo);
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

    final box = Hive.box<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    final txn = box.get(event.transNo);
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
        // "Lokasi tidak sesuai (jarak ${distance.toStringAsFixed(1)} m)"));
        "Lokasi foto tidak sesuai dengan toko terdaftar. Mohon ambil ulang di lokasi toko.",
        photo: photo,
      ));
    }
  }
}
