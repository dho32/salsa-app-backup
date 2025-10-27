import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/service_call/problem_source_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';
import 'package:salsa/screens/service_call/service_call_validation/components/widgets/service_call_validation_widgets.dart';

import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import 'components/remote_validation_body_mobile.dart';

// Model sederhana untuk merepresentasikan kartu masalah di state lokal
class _ProblemCard {
  String problemId;
  List<String> solutionIds;

  _ProblemCard({required this.problemId, this.solutionIds = const []});
}

class RemoteValidationScreen extends StatefulWidget {
  final String transNo;
  final String uniqueId;
  final String articleName;
  final ServiceCallValidationEntryModel? initialData;
  final String complaintDetails;
  final String imageFile;
  final List<ProblemSourceModel> problemSources;

  const RemoteValidationScreen({
    super.key,
    required this.transNo,
    required this.uniqueId,
    required this.articleName,
    this.initialData,
    required this.complaintDetails,
    required this.imageFile,
    required this.problemSources,
  });

  @override
  State<RemoteValidationScreen> createState() => _RemoteValidationScreenState();
}

class _RemoteValidationScreenState extends State<RemoteValidationScreen> {
  // State lokal untuk halaman ini
  bool _isLoading = true;
  List<ProblemSourceModel> _problemSources = [];
  String? _selectedUnitType;
  final List<_ProblemCard> _selectedProblemCards = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final remoteProblemSource = widget.problemSources.firstWhereOrNull(
        (src) => src.unitType.toUpperCase() == 'REMOTE',
      );
      if (remoteProblemSource == null) {
        throw Exception("Konfigurasi masalah untuk 'REMOTE' tidak ditemukan.");
      }
      // 1. Ambil data master masalah & solusi
      setState(() {
        // ✅ Simpan HANYA problem source 'REMOTE'
        _problemSources = [remoteProblemSource];
        // ✅ Set unit type secara otomatis ke 'REMOTE'
        _selectedUnitType = 'REMOTE';
        // 2. Jika ada data awal (draft), pulihkan state
        if (widget.initialData != null) {
          if (widget.initialData!.unitType.toUpperCase() == 'REMOTE') {
            final initialProblems = widget.initialData!.problems;
            for (var p in initialProblems) {
              _selectedProblemCards.add(_ProblemCard(
                  problemId: p.problemId, solutionIds: p.solutionIds));
            }
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat data: ${e.toString()}")));
      }
    }
  }

  Future<void> _saveValidation() async {
    // Validasi sederhana
    if (_selectedUnitType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih sumber permasalahan.")));
      return;
    }
    if (_selectedProblemCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tambahkan minimal satu permasalahan.")));
      return;
    }

    // Siapkan data untuk disimpan
    final entry = ServiceCallValidationEntryModel(
      transNo: widget.transNo,
      serialNo: widget.uniqueId,
      unitType: _selectedUnitType!,
      problems: _selectedProblemCards
          .map((p) => ValidationProblem(
              problemId: p.problemId, solutionIds: p.solutionIds))
          .toList(),
      isCompleted: true,
      // Field lain kita isi dengan data kosong
      imagePathsBefore: [],
      measurementsBefore: [],
      imagePathsAfter: [],
      measurementsAfter: [],
    );

    // Buka box Hive dan simpan
    final box = await Hive.openBox<ServiceCallValidationEntryModel>(
        kServiceCallHiveBox);
    final existingKey = box.keys.cast<dynamic>().firstWhereOrNull((key) {
      final item = box.get(key);
      // Tambahkan pengecekan transNo
      return item?.serialNo == widget.uniqueId &&
          item?.transNo == widget.transNo;
    });

    if (existingKey != null) {
      await box.put(existingKey, entry);
    } else {
      await box.add(entry);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Validasi remote berhasil disimpan!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(true);
    }
  }

  void _showAddProblemDialog() {
    // _selectedUnitType PASTI 'REMOTE' atau null jika belum load
    if (_selectedUnitType == null || _problemSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Data sumber masalah belum siap."),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // ✅ Langsung ambil problems dari _problemSources[0] (karena hanya ada 1)
    final problemsForType = _problemSources[0].problems;
    final existingIds = _selectedProblemCards.map((p) => p.problemId).toList();

    showDialogAddProblem(
      context: context,
      problems: problemsForType,
      existingProblemIds: existingIds,
      onAdd: (problemId, solutionIds) {
        setState(() {
          _selectedProblemCards.add(
              _ProblemCard(problemId: problemId, solutionIds: solutionIds));
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold sekarang dibangun di sini
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: _isLoading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ),
      body: RemoteValidationBodyMobile(
        // Kirim semua data dan FUNGSI ke body
        isLoading: _isLoading,
        problemSources: _problemSources,
        selectedProblemCards: _selectedProblemCards
            .map((p) => SelectedProblemCard(
                selectedProblemId: p.problemId,
                selectedSolutionIds: p.solutionIds))
            .toList(),
        transNo: widget.transNo,
        uniqueId: widget.uniqueId,
        complaintDetails: widget.complaintDetails,
        imageFile: widget.imageFile,
        onAddProblem: _showAddProblemDialog,
        onRemoveProblem: (card) {
          setState(() {
            _selectedProblemCards
                .removeWhere((p) => p.problemId == card.selectedProblemId);
          });
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Tambah Sumber Masalah & Solusi"),
                onPressed: _showAddProblemDialog,
                // Tambahkan style ini agar sama persis
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Simpan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _saveValidation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
