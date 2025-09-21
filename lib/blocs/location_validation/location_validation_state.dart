import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

abstract class LocationValidationState extends Equatable {
  const LocationValidationState();

  @override
  List<Object?> get props => [];
}

class LocationValidationInitial extends LocationValidationState {}

class LocationValidationLoading extends LocationValidationState {}

class LocationPhotoLoaded extends LocationValidationState {
  final CapturedImageDetail? photo;
  final double? distance;

  const LocationPhotoLoaded(this.photo, {this.distance});

  @override
  List<Object?> get props => [photo, distance];
}

class LocationValidationSuccess extends LocationValidationState {}

class LocationValidationFailure extends LocationValidationState {
  final String message;
  final CapturedImageDetail? photo;
  final double? distance;

  const LocationValidationFailure(
      this.message, {
        this.photo,
        this.distance,
      });

  @override
  List<Object?> get props => [message, photo, distance];
}
