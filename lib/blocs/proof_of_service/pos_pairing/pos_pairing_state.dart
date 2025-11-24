import 'package:equatable/equatable.dart';

class PosPairingState extends Equatable {
  final List<String> indoorSerials;
  final List<String> outdoorSerials;
  final Map<String, String> pairings;

  const PosPairingState({
    required this.indoorSerials,
    required this.outdoorSerials,
    required this.pairings,
  });

  /// Tampilkan daftar IN yang belum dipakai OUT lain.
  /// Pastikan pilihan saat ini tetap tersedia agar tidak hilang saat rebuild.
  List<String> availableFor(String outdoor) {
    final o = _norm(outdoor);
    final selectedForThis = pairings[o];
    final used = pairings.values.toSet()..remove(selectedForThis);
    return indoorSerials.where((sn) => !used.contains(_norm(sn))).toList();
  }

  bool get allOutdoorPaired =>
      outdoorSerials.every((o) => (pairings[_norm(o)] ?? '').isNotEmpty);

  PosPairingState copyWith({
    List<String>? indoorSerials,
    List<String>? outdoorSerials,
    Map<String, String>? pairings,
  }) {
    return PosPairingState(
      indoorSerials: indoorSerials ?? this.indoorSerials,
      outdoorSerials: outdoorSerials ?? this.outdoorSerials,
      pairings: pairings ?? this.pairings,
    );
  }

  static String _norm(String s) => s.trim().toUpperCase();

  @override
  List<Object?> get props => [indoorSerials, outdoorSerials, pairings];
}
