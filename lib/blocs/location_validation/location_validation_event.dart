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

  const TakeLocationPhoto(this.transNo, this.tokoLat, this.tokoLng);

  @override
  List<Object?> get props => [transNo, tokoLat, tokoLng];
}

class RemoveLocationPhoto extends LocationValidationEvent {
  final String transNo;
  const RemoveLocationPhoto(this.transNo);

  @override
  List<Object?> get props => [transNo];
}

class SubmitLocationValidation extends LocationValidationEvent {
  final String transNo;
  final double tokoLat;
  final double tokoLng;

  const SubmitLocationValidation(this.transNo, this.tokoLat, this.tokoLng);

  @override
  List<Object?> get props => [transNo, tokoLat, tokoLng];
}
