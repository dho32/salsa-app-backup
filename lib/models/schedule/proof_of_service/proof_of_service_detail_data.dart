import 'package:hive/hive.dart';

part 'proof_of_service_detail_data.g.dart'; // Nama file yang akan di-generate

@HiveType(typeId: 4) // Beri ID unik untuk setiap model Hive
class ProofOfServiceDetailData extends HiveObject {
  @HiveField(0)
  String note;

  @HiveField(1)
  List<String> imagePaths;

  @HiveField(2)
  String volt;

  @HiveField(3)
  String ampere;

  @HiveField(4)
  String psi;

  @HiveField(5)
  String temperature;

  ProofOfServiceDetailData({
    this.note = '',
    this.imagePaths = const [],
    this.volt = '0.0',
    this.ampere = '0.0',
    this.psi = '0.0',
    this.temperature = '0.0',
  });

  ProofOfServiceDetailData copyWith({
    String? note,
    List<String>? imagePaths,
    String? volt,
    String? ampere,
    String? psi,
    String? temperature,
  }) {
    return ProofOfServiceDetailData(
      note: note ?? this.note,
      imagePaths: imagePaths ?? this.imagePaths,
      volt: volt ?? this.volt,
      ampere: ampere ?? this.ampere,
      psi: psi ?? this.psi,
      temperature: temperature ?? this.temperature,
    );
  }
}
