import 'package:equatable/equatable.dart';

abstract class LocationValidationEvent extends Equatable {
  const LocationValidationEvent();

  @override
  List<Object?> get props => [];
}

class LoadLocationPhoto extends LocationValidationEvent {
  final String transNo;
  const LoadLocationPhoto(this.transNo);

  @override
  List<Object?> get props => [transNo];
}

class TakeLocationPhoto extends LocationValidationEvent {
  final String transNo;
  const TakeLocationPhoto(this.transNo);

  @override
  List<Object?> get props => [transNo];
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
