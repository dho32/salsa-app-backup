part of 'upload_progress_cubit.dart';

class UploadProgressState extends Equatable {
  final int current;
  final int total;

  const UploadProgressState({
    required this.current,
    required this.total,
  });

  @override
  List<Object?> get props => [current, total];
}
