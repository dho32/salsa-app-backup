import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_event.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_state.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_repository.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/common/measurement_limits.dart';

class ServiceCallDetailBloc
    extends Bloc<ServiceCallDetailEvent, ServiceCallDetailState> {
  final ServiceCallDetailRepository repository;

  ServiceCallDetailBloc(this.repository) : super(ServiceCallDetailInitial()) {
    on<FetchServiceCallDetail>((event, emit) async {
      emit(ServiceCallDetailLoading());
      try {
        // 1. Tarik Data Detail dari API
        final result = await repository.fetchServiceCallDetail(
            event.transNo, event.vendorId);

        // 2. Buka kotak Global Master dari Hive dengan AMAN
        // ⚠️ PASTIKAN NAMA BOX-NYA SESUAI DENGAN PUNYA AKANG (Misal: kAppConfigBox)
        const String configBoxName = kAppConfigBox;

        Box configBox;
        if (Hive.isBoxOpen(configBoxName)) {
          configBox = Hive.box(configBoxName);
        } else {
          configBox = await Hive.openBox(configBoxName);
        }

        // --- A. LIMIT SC BEFORE ---
        Map<String, MeasurementLimits> mergedLimitsBefore = {};
        final rawLimitsBefore = configBox.get('limits_sc_before');
        if (rawLimitsBefore is Map) {
          rawLimitsBefore.forEach((key, value) {
            if (key is String && value is MeasurementLimits) {
              mergedLimitsBefore[key] = value;
            }
          });
        }
        result.customLimitsBefore.forEach((key, value) {
          mergedLimitsBefore[key] = value;
        });

        // --- B. LIMIT SC AFTER ---
        Map<String, MeasurementLimits> mergedLimitsAfter = {};
        final rawLimitsAfter = configBox.get('limits_sc_after');
        if (rawLimitsAfter is Map) {
          rawLimitsAfter.forEach((key, value) {
            if (key is String && value is MeasurementLimits) {
              mergedLimitsAfter[key] = value;
            }
          });
        }
        result.customLimitsAfter.forEach((key, value) {
          mergedLimitsAfter[key] = value;
        });

        // 3. Emit data yang udah di-merge ke UI
        emit(ServiceCallDetailLoaded(
          data: result,
          limitsBefore: mergedLimitsBefore,
          limitsAfter: mergedLimitsAfter,
        ));

      } catch (e) {
        emit(ServiceCallDetailError(e.toString()));
      }
    });
  }
}