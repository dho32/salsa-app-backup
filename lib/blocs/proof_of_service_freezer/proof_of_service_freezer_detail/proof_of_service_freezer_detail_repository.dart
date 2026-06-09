import '../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';

/// Repository data tugas Cuci Freezer.
///
/// NOTE(backend): endpoint Cuci Freezer BELUM tersedia. Untuk sekarang
/// [getDetail] mengembalikan data dummy supaya UI bisa jalan offline.
/// Saat endpoint siap, ganti isi [getDetail] dengan HTTP call, mis.:
///   final uri = getUrl(pathUrl: 'proof_of_service_freezer/detail', params: {'trans_no': transNo});
///   final res = await http.get(uri);
///   return ProofOfServiceFreezerDetailModel.fromJson(jsonDecode(res.body));
class ProofOfServiceFreezerDetailRepository {
  Future<ProofOfServiceFreezerDetailModel> getDetail(String transNo) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simulasi network
    return _mockDetail(transNo);
  }

  ProofOfServiceFreezerDetailModel _mockDetail(String transNo) {
    return ProofOfServiceFreezerDetailModel(
      header: ProofOfServiceFreezerHeader(
        transNo: transNo,
        poDate: '2026-06-04',
        shipTo: 'STR-001',
        shipToName: 'Toko Demo Indomaret Sudirman',
        shipToAddress: 'Jl. Jend. Sudirman No. 1, Jakarta Pusat',
        shipToMail: 'demo@store.co.id',
        branchCode: 'JKT',
        branchName: 'Jakarta Pusat',
        latitude: -6.2,
        longitude: 106.8,
      ),
      items: List.generate(
        4,
        (i) => ProofOfServiceFreezerItem(
          serialNo: 'FRZ-$transNo-${(i + 1).toString().padLeft(3, '0')}',
          articleNo: 'ART-FRZ-${i + 1}',
          articleDesc: i.isEven ? 'Freezer Box 200L' : 'Showcase Cooler 300L',
          unitDesc: 'Unit',
          lineNo: i + 1,
          isGeneric: false,
          unitIndex: i,
        ),
      ),
    );
  }
}
