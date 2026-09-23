part of 'scf_detail_bloc.dart';

abstract class ScfDetailEvent extends Equatable {
  const ScfDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Ambil detail tugas Service Call Freezer (header toko + daftar freezer +
/// master Permasalahan & Solusi) dari repository.
class FetchScfDetail extends ScfDetailEvent {
  final String transNo;

  const FetchScfDetail(this.transNo);

  @override
  List<Object?> get props => [transNo];
}
