import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/schedule/proof_of_service/proof_of_service_bloc.dart';
import '../../../../models/schedule/proof_of_service/proof_of_service_response.dart';
import '../../proof_of_service_detail/proof_of_service_detail_screen.dart';

class ProofOfServiceBodyMobile extends StatefulWidget {
  const ProofOfServiceBodyMobile({super.key});

  @override
  State<ProofOfServiceBodyMobile> createState() =>
      _ProofOfServiceBodyMobileState();
}

class _ProofOfServiceBodyMobileState extends State<ProofOfServiceBodyMobile> {
  // --- Controllers untuk semua input di form ---
  // PIC
  final _nikPicCtrl = TextEditingController();
  final _namePicCtrl = TextEditingController();
  final _positionPicCtrl = TextEditingController();

  // Teknisi
  final _technician1Ctrl = TextEditingController();
  final _technician2Ctrl = TextEditingController();
  final _technician3Ctrl = TextEditingController();

  // Pengukuran
  final _temperatureInCtrl = TextEditingController();
  final _temperatureOutCtrl = TextEditingController();
  final _serviceTimeCtrl = TextEditingController();

  // State lokal untuk mengontrol visibilitas field Teknisi 3
  bool _showTeknisi3 = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Tambahkan listener ke controller teknisi opsional
    _technician2Ctrl.addListener(_dispatchUpdateEvent);
    _technician3Ctrl.addListener(_dispatchUpdateEvent);
  }

  @override
  void dispose() {
    // Selalu dispose semua controller untuk mencegah memory leak
    _nikPicCtrl.dispose();
    _namePicCtrl.dispose();
    _positionPicCtrl.dispose();
    _technician1Ctrl.dispose();
    _technician2Ctrl.dispose();
    _technician3Ctrl.dispose();
    _temperatureInCtrl.dispose();
    _temperatureOutCtrl.dispose();
    _serviceTimeCtrl.dispose();
    super.dispose();
  }

  // Helper untuk mengirim event update ke BLoC
  void _dispatchUpdateEvent() {
    // Ambil semua nilai terbaru dari controller
    final picData = PICInputData(
      nik: _nikPicCtrl.text,
      name: _namePicCtrl.text,
      position: _positionPicCtrl.text,
    );

    final technicianData = [
      _technician1Ctrl.text,
      _technician2Ctrl.text,
      _technician3Ctrl.text
    ].where((t) => t.isNotEmpty).toList();

    final measurementData = POSMeasurementData(
      picInput: picData,
      technician: technicianData,
      temperatureIn: _temperatureInCtrl.text,
      temperatureOut: _temperatureOutCtrl.text,
      serviceTime: _serviceTimeCtrl.text,
    );
    // Kirim event ke BLoC
    context.read<ProofOfServiceBloc>().add(UpdateMeasurements(measurementData));
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan BlocConsumer untuk mengisi data awal ke controller sekali saja
    return BlocConsumer<ProofOfServiceBloc, ProofOfServiceState>(
      listenWhen: (previous, current) =>
          current is POSLoaded && previous is! POSLoaded,
      listener: (context, state) {
        if (state is POSLoaded) {
          // Isi data awal saat pertama kali dimuat
          _nikPicCtrl.text = state.measurements.picInput.nik;
          _namePicCtrl.text = state.measurements.picInput.name;
          _positionPicCtrl.text = state.measurements.picInput.position;
          _technician1Ctrl.text = state.measurements.technician.isNotEmpty
              ? state.measurements.technician[0]
              : '';
          _technician2Ctrl.text = state.measurements.technician.length > 1
              ? state.measurements.technician[1]
              : '';
          _technician3Ctrl.text = state.measurements.technician.length > 2
              ? state.measurements.technician[2]
              : '';
          _temperatureInCtrl.text = state.measurements.temperatureIn;
          _temperatureOutCtrl.text = state.measurements.temperatureOut;
          _serviceTimeCtrl.text = state.measurements.serviceTime;

          if (state.measurements.technician.length > 2) {
            _showTeknisi3 = true;
          }
        }
      },
      builder: (context, state) {
        if (state is POSError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is POSLoading || state is POSInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is POSLoaded) {
          final allUnitsDone =
              state.unitList.every((unit) => unit.isDetailFilled);
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeaderSection(context, state.headerData),
                      const SizedBox(height: 12),
                      _buildMeasurementSection(context, state.measurements),
                      const SizedBox(height: 12),
                      _buildUnitListSection(context, state.unitList),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
              if (allUnitsDone)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24),
                    color: Colors.transparent,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Jika semua field valid, jalankan aksi submit
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Form valid, data sedang diproses...')),
                          );
                          // TODO: Panggil event ke BLoC untuk mengirim data ke server
                          // context.read<ProofOfServiceBloc>().add(SubmitPOSData());
                        } else {
                          // Jika ada field yang tidak valid, tampilkan pesan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Harap lengkapi semua data yang wajib diisi')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- WIDGET HELPER UNTUK SETIAP SECTION ---

  Widget _buildHeaderSection(BuildContext context, POSHeaderData data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business_center_outlined, color: Colors.grey),
                SizedBox(width: 8),
                Text("Informasi Umum",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.transNo,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: Colors.grey[700], size: 20),
                    SizedBox(width: 8),
                    Text(data.poDate,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.store_outlined, color: Colors.grey[700], size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.shipToName} (${data.shipToCode})',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data.shipToAddress,
                        softWrap: true,
                      ),
                    ],
                  ),
                )
              ],
            ),
            Row(
              children: [
                Icon(Icons.apartment_outlined,
                    color: Colors.grey[700], size: 20),
                const SizedBox(width: 16),
                Text(
                  data.branchName,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementSection(
      BuildContext context, POSMeasurementData data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule_outlined, color: Colors.grey),
                SizedBox(width: 8),
                Text("Input Pengukuran & Personil",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            const Text("PIC Toko",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        controller: _nikPicCtrl,
                        label: "NIK",
                        align: TextAlign.left,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIK tidak boleh kosong';
                          }
                          return null;
                        })),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildTextField(
                        controller: _positionPicCtrl,
                        label: "Jabatan",
                        align: TextAlign.left,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jabatan tidak boleh kosong';
                          }
                          return null;
                        })),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _namePicCtrl,
                label: "Nama Lengkap",
                align: TextAlign.left,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap tidak boleh kosong';
                  }
                  return null;
                }),

            // --- Bagian Input Teknisi yang Baru ---
            const SizedBox(height: 10),
            if (_showTeknisi3) const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Teknisi",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                // Tombol untuk menambah/menghapus Teknisi 3
                if (!_showTeknisi3)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Teknisi 3"),
                    onPressed: () => setState(() => _showTeknisi3 = true),
                  )
              ],
            ),
            if (_showTeknisi3) const SizedBox(height: 12),

            _buildTextField(
              controller: _technician1Ctrl,
              label: "Nama Teknisi 1",
              align: TextAlign.left,
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 12),
            _buildTextField(
                controller: _technician2Ctrl,
                label: "Nama Teknisi 2 (Opsional)",
                align: TextAlign.left),

            const SizedBox(height: 12),

            if (_showTeknisi3)
              _buildTextField(
                controller: _technician3Ctrl,
                label: "Nama Teknisi 3 (Opsional)",
                align: TextAlign.left,
                // Tambahkan tombol hapus
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _showTeknisi3 = false;
                      _technician3Ctrl.clear();
                    });
                    _dispatchUpdateEvent();
                  },
                ),
              ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Suhu",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            controller: _temperatureInCtrl,
                            label: "Suhu Dalam",
                            align: TextAlign.right,
                            keyboardType: TextInputType.number,
                            suffixText: '°C',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Suhu dalam tidak boleh kosong';
                              }
                              return null;
                            })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTextField(
                            controller: _temperatureOutCtrl,
                            label: "Suhu Luar",
                            align: TextAlign.right,
                            keyboardType: TextInputType.number,
                            suffixText: '°C',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Suhu luar tidak boleh kosong';
                              }
                              return null;
                            })),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _serviceTimeCtrl,
                        label: "Jam Service",
                        align: TextAlign.right,
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jam service tidak boleh kosong';
                          }
                          return null;
                        },
                        onTap: () async {
                          final time = await showTimePicker(
                            helpText: "Pilih Waktu Service",
                              initialEntryMode: TimePickerEntryMode.input,
                              context: context, initialTime: TimeOfDay.now());
                          if (time != null && mounted) {
                            _serviceTimeCtrl.text = time.format(context);
                            _dispatchUpdateEvent(); // Kirim update ke BLoC setelah waktu dipilih
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextAlign align,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? suffixText,
    bool readOnly = false,
    bool enabled = true,
    void Function()? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      keyboardType: keyboardType,
      onChanged: (_) => _dispatchUpdateEvent(),
      textAlign: align,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildUnitListSection(BuildContext context, List<POSUnitItem> units) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-header di dalam kartu
            const Row(
              children: [
                Icon(Icons.ac_unit, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  "Unit yang di-Service",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Tampilkan pesan jika tidak ada unit
            if (units.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Tidak ada unit yang terdaftar.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            // Tampilkan daftar unit jika ada
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  // Panggil helper untuk setiap kartu unit
                  return _buildUnitCard(context, unit);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, POSUnitItem unit) {
    final bool isFilled = unit.isDetailFilled;
    final IconData statusIcon =
        isFilled ? Icons.check_circle : Icons.radio_button_unchecked_outlined;
    final Color statusColor = isFilled ? Colors.green : Colors.grey;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      // DIUBAH: Pastikan warna kartu putih
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unit.articleNameUnit,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(unit.serialNo,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(unit.description,
              style: const TextStyle(color: Colors.black54)),
        ),
        trailing: Icon(statusIcon, color: statusColor),
        onTap: () async {
          final currentState = context.read<ProofOfServiceBloc>().state;
          if (currentState is POSLoaded) {
            final result = await Navigator.push<bool>(
              // <-- Tambahkan await dan tipe data <bool>
              context,
              MaterialPageRoute(
                builder: (_) => ProofOfServiceDetailScreen(
                  transNo: currentState.headerData.transNo,
                  unit: unit,
                ),
              ),
            );

            if (result == true && mounted) {
              context
                  .read<ProofOfServiceBloc>()
                  .add(FetchPOSDetail(currentState.headerData.transNo));
            }
          }
        },
      ),
    );
  }
}
