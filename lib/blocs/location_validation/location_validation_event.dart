import 'package:equatable/equatable.dart';

abstract class LocationValidationEvent extends Equatable {
  const LocationValidationEvent();

  @override
  List<Object?> get props => [];
}

class LoadLocationPhoto extends LocationValidationEvent {
  final String transNo;
  final double tokoLat;
  final double tokoLng;

  const LoadLocationPhoto(this.transNo, this.tokoLat, this.tokoLng);

  @override
  List<Object?> get props => [transNo, tokoLat, tokoLng];
}

class TakeLocationPhoto extends LocationValidationEvent {
  final String transNo;
  final double tokoLat;
  final double tokoLng;

  /// Nama toko untuk baris watermark (menggantikan transNo).
  final String storeName;

  const TakeLocationPhoto(this.transNo, this.tokoLat, this.tokoLng,
      {this.storeName = ''});

  @override
  List<Object?> get props => [transNo, tokoLat, tokoLng, storeName];
}

class RemoveLocationPhoto extends LocationValidationEvent {
  final String transNo;

  const RemoveLocationPhoto(this.transNo);

  @override
  List<Object?> get props => [transNo];
}

class SubmitLocationValidation extends LocationValidationEvent {
  final String transNo;
  final String store;
  final double tokoLat;
  final double tokoLng;

  const SubmitLocationValidation(
      this.transNo, this.store, this.tokoLat, this.tokoLng);

  @override
  List<Object?> get props => [transNo, store, tokoLat, tokoLng];
}
