class RROFormState {
  final String picName;
  final String picPhone;
  final String picNik;
  final String picPosition;

  final String technician1;
  final String technician2;
  final String technician3;
  final bool showTechnician3;

  const RROFormState({
    this.picName = '',
    this.picPhone = '',
    this.picNik = '',
    this.picPosition = '',
    this.technician1 = '',
    this.technician2 = '',
    this.technician3 = '',
    this.showTechnician3 = false,
  });

  RROFormState copyWith({
    String? picName,
    String? picPhone,
    String? picNik,
    String? picPosition,
    String? technician1,
    String? technician2,
    String? technician3,
    bool? showTechnician3,
  }) {
    return RROFormState(
      picName: picName ?? this.picName,
      picPhone: picPhone ?? this.picPhone,
      picNik: picNik ?? this.picNik,
      picPosition: picPosition ?? this.picPosition,
      technician1: technician1 ?? this.technician1,
      technician2: technician2 ?? this.technician2,
      technician3: technician3 ?? this.technician3,
      showTechnician3: showTechnician3 ?? this.showTechnician3,
    );
  }

  // Validasi dasar
  bool get isPicStoreValid => picName.isNotEmpty && picPhone.isNotEmpty;
  bool get isTechnicianValid => technician1.isNotEmpty;
}