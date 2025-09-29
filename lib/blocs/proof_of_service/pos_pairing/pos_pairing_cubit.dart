import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_pairing_state.dart';

class PosPairingCubit extends Cubit<PosPairingState> {
  PosPairingCubit({
    required List<String> indoorSerials,
    required List<String> outdoorSerials,
    Map<String, String>? initialPairings,
  }) : super(PosPairingState(
    indoorSerials: indoorSerials.map(_norm).toList(),
    outdoorSerials: outdoorSerials.map(_norm).toList(),
    pairings: (initialPairings ?? {})
        .map((k, v) => MapEntry(_norm(k), _norm(v))),
  ));

  static String _norm(String s) => s.trim().toUpperCase();

  void selectIndoorForOutdoor(String outdoor, String? indoor) {
    final o = _norm(outdoor);
    final newMap = Map<String, String>.from(state.pairings);
    if (indoor == null || indoor.isEmpty) {
      newMap.remove(o);
    } else {
      newMap[o] = _norm(indoor);
    }
    emit(state.copyWith(pairings: newMap));
  }
}
