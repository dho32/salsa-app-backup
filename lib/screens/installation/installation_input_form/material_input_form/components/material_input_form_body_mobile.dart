import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_event.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';

class MaterialInputFormBodyMobile extends StatefulWidget {
  final InstallationTargetUnitModel target;
  final InstallationUnitModel existingData;
  final String transNo;

  const MaterialInputFormBodyMobile({
    super.key,
    required this.target,
    required this.existingData,
    required this.transNo,
  });

  @override
  State<MaterialInputFormBodyMobile> createState() =>
      _MaterialInputFormBodyMobileState();
}

class _MaterialInputFormBodyMobileState
    extends State<MaterialInputFormBodyMobile> {
  // --- MASTER DATA (OPTIONS) ---
  List<InstallationMasterOptionModel> _pipeOptions = [];
  List<InstallationMasterOptionModel> _drainOptions = [];
  List<InstallationMasterOptionModel> _cableOptions = [];
  List<InstallationMasterOptionModel> _ductOptions = [];

  // --- FORM STATE ---
  Map<String, dynamic> _pipeACForm = {};
  Map<String, dynamic> _cableControlForm = {};
  List<Map<String, dynamic>> _pipeDrainForms = [];
  List<Map<String, dynamic>> _cableAdditionalForms = [];

  // --- ACCESSORIES ---
  String _mountingType = 'NONE';
  // [DIHAPUS] _hasJasaPerapihan sudah pindah ke halaman Summary (Global)

  Timer? _debounceTimer;
  bool _isSubmittingFinal = false;
  bool _isBackDataSaved = false;

  bool get _isOriginalCompleted =>
      widget.existingData.materialStatus == 'COMPLETED';

  final InputBorder _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  final InputBorder _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
  );

  @override
  void initState() {
    super.initState();
    _initMandatoryForms();
    _loadMasterData();
    _initializeFormData();
  }

  void _initMandatoryForms() {
    _pipeACForm = _createEmptyRow();
    _cableControlForm = _createEmptyRow(usageType: 'KABEL_CONTROL');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pipeACForm['lengthController'].dispose();
    _cableControlForm['lengthController'].dispose();
    for (var f in _pipeDrainForms) f['lengthController'].dispose();
    for (var f in _cableAdditionalForms) f['lengthController'].dispose();
    super.dispose();
  }

  Map<String, dynamic> _createEmptyRow(
      {String? usageType, String? articleId, String? brandId, double? length}) {
    final controller = TextEditingController(
        text: (length != null && length > 0) ? length.toString() : '');
    controller.addListener(_onFormChanged);
    return {
      'articleId': articleId,
      'brandId': brandId,
      'lengthController': controller,
      'usageType': usageType,
    };
  }

  void _onFormChanged() {
    if (_isOriginalCompleted) return;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _saveInternal(isFinal: false);
    });
  }

  void _loadMasterData() {
    final state = context.read<InstallationBloc>().state;
    final master = state.taskDetail?.masterMaterials;
    if (master != null) {
      setState(() {
        _pipeOptions = master.pipes;
        _drainOptions = master.drains;
        _cableOptions = master.cables;
        _ductOptions = master.ducts;
      });
    }
  }

  void _initializeFormData() {
    final materials = widget.existingData.materials;
    _mountingType =
    materials.mountingType.isNotEmpty ? materials.mountingType : 'NONE';
    // [DIHAPUS] Inisialisasi _hasJasaPerapihan

    final existingAC = materials.pipes.firstWhere(
            (p) => p.usageType != 'PIPA_DRAIN',
        orElse: () => InstallationMaterialItemModel(
            articleId: '',
            articleName: '',
            brandId: '',
            brandName: '',
            length: 0,
            usageType: ''));
    if (existingAC.articleId.isNotEmpty || existingAC.length > 0) {
      _updateFormMap(_pipeACForm, existingAC);
    }

    for (var p in materials.pipes) {
      if (p.usageType == 'PIPA_DRAIN') {
        if (_pipeDrainForms.isEmpty) _addPipeDrainRow(p);
      }
    }

    final existingControl = materials.cables.firstWhere(
            (c) => c.usageType == 'KABEL_CONTROL',
        orElse: () => InstallationMaterialItemModel(
            articleId: '',
            articleName: '',
            brandId: '',
            brandName: '',
            length: 0,
            usageType: ''));
    if (existingControl.articleId.isNotEmpty || existingControl.length > 0) {
      _updateFormMap(_cableControlForm, existingControl);
    }

    for (var c in materials.cables) {
      if (c.usageType != 'KABEL_CONTROL') {
        bool isTypeExists = _cableAdditionalForms
            .any((form) => form['usageType'] == c.usageType);
        if (!isTypeExists && _cableAdditionalForms.length < 2) {
          _addCableAdditionalRow(c);
        }
      }
    }
  }

  void _updateFormMap(
      Map<String, dynamic> form, InstallationMaterialItemModel data) {
    form['articleId'] = (data.articleId.isNotEmpty) ? data.articleId : null;
    form['brandId'] = (data.brandId.isNotEmpty) ? data.brandId : null;
    form['lengthController'].text =
    (data.length > 0) ? data.length.toString() : '';
  }

  void _addPipeDrainRow(InstallationMaterialItemModel? data) {
    if (_pipeDrainForms.isNotEmpty) return;
    setState(() {
      _pipeDrainForms.add(_createEmptyRow(
          articleId: data?.articleId,
          brandId: data?.brandId,
          length: data?.length));
    });
  }

  void _removePipeDrainRow(int index) {
    setState(() {
      _pipeDrainForms[index]['lengthController'].dispose();
      _pipeDrainForms.removeAt(index);
    });
    _onFormChanged();
  }

  void _addCableAdditionalRow(InstallationMaterialItemModel? data) {
    if (_cableAdditionalForms.length >= 2) return;
    String defaultType = 'KABEL_POWER';
    bool hasPower =
    _cableAdditionalForms.any((f) => f['usageType'] == 'KABEL_POWER');
    bool hasDuct =
    _cableAdditionalForms.any((f) => f['usageType'] == 'KABEL_DUCT');

    if (hasPower && !hasDuct) {
      defaultType = 'KABEL_DUCT';
    } else if (!hasPower && hasDuct) {
      defaultType = 'KABEL_POWER';
    }
    String finalUsage = data?.usageType ?? defaultType;

    setState(() {
      _cableAdditionalForms.add(_createEmptyRow(
          usageType: finalUsage,
          articleId: data?.articleId,
          brandId: data?.brandId,
          length: data?.length));
    });
  }

  void _removeCableAdditionalRow(int index) {
    setState(() {
      _cableAdditionalForms[index]['lengthController'].dispose();
      _cableAdditionalForms.removeAt(index);
    });
    _onFormChanged();
  }

  InstallationMaterialsModel? _buildModel({required bool isFinal}) {
    List<InstallationMaterialItemModel> finalPipes = [];
    List<InstallationMaterialItemModel> finalCables = [];

    var acItem =
    _parseRow(_pipeACForm, 'Pipa AC', isFinal, 'PIPA_AC', _pipeOptions);
    if (acItem != null)
      finalPipes.add(acItem);
    else if (isFinal && _isRowTouched(_pipeACForm)) return null;

    for (var form in _pipeDrainForms) {
      var item =
      _parseRow(form, 'Pipa Drain', isFinal, 'PIPA_DRAIN', _drainOptions);
      if (item != null)
        finalPipes.add(item);
      else if (isFinal && _isRowTouched(form)) return null;
    }

    var ctrlItem = _parseRow(_cableControlForm, 'Kabel Control', isFinal,
        'KABEL_CONTROL', _cableOptions);
    if (ctrlItem != null) {
      finalCables.add(ctrlItem);
    } else if (isFinal && _isRowTouched(_cableControlForm)) return null;

    for (var form in _cableAdditionalForms) {
      String usage = form['usageType'];
      List<InstallationMasterOptionModel> opts =
      (usage == 'KABEL_DUCT') ? _ductOptions : _cableOptions;
      var item = _parseRow(form, 'Kabel Tambahan', isFinal, usage, opts);
      if (item != null) {
        finalCables.add(item);
      } else if (isFinal && _isRowTouched(form)) return null;
    }

    if (isFinal) {
      if (!finalPipes.any((p) => p.usageType == 'PIPA_AC')) {
        _showError("Pipa AC (Wajib) belum diisi!");
        return null;
      }
      if (!finalCables.any((c) => c.usageType == 'KABEL_CONTROL')) {
        _showError("Kabel Control (Wajib) belum diisi!");
        return null;
      }
    }

    return InstallationMaterialsModel(
      pipes: finalPipes,
      cables: finalCables,
      mountingType: _mountingType,
      hasJasaPerapihan: false, // [DIHAPUS] Default false karena dipindah
    );
  }

  bool _isRowTouched(Map<String, dynamic> form) {
    return form['articleId'] != null ||
        form['brandId'] != null ||
        form['lengthController'].text.isNotEmpty;
  }

  InstallationMaterialItemModel? _parseRow(
      Map<String, dynamic> form,
      String label,
      bool isFinal,
      String usageType,
      List<InstallationMasterOptionModel> sourceOptions) {
    final String? artId = form['articleId'];
    final String? brandId = form['brandId'];
    final String lenStr = form['lengthController'].text;

    String artName = '';
    String brandName = '';

    if (artId != null) {
      try {
        final opt = sourceOptions.firstWhere((e) => e.id == artId);
        artName = opt.name;
        if (brandId != null) {
          final brand = opt.brands.firstWhere((b) => b.id == brandId);
          brandName = brand.name;
        }
      } catch (_) {}
    }

    if (!isFinal) {
      if (artId != null || brandId != null || lenStr.isNotEmpty) {
        return InstallationMaterialItemModel(
            articleId: artId ?? '',
            articleName: artName,
            brandId: brandId ?? '',
            brandName: brandName,
            length: double.tryParse(lenStr.replaceAll(',', '.')) ?? 0.0,
            usageType: usageType);
      }
      return null;
    }

    if (_isRowTouched(form)) {
      if (artId == null) {
        _showError("$label: Jenis belum dipilih!");
        return null;
      }
      if (brandId == null) {
        _showError("$label: Merk belum dipilih!");
        return null;
      }
      if (lenStr.isEmpty) {
        _showError("$label: Panjang belum diisi!");
        return null;
      }
      final double? len = double.tryParse(lenStr.replaceAll(',', '.'));
      if (len == null || len <= 0) {
        _showError("$label: Panjang tidak valid!");
        return null;
      }

      return InstallationMaterialItemModel(
          articleId: artId,
          articleName: artName,
          brandId: brandId,
          brandName: brandName,
          length: len,
          usageType: usageType);
    }
    return null;
  }

  void _saveInternal({required bool isFinal}) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    final newMaterials = _buildModel(isFinal: isFinal);
    if (newMaterials == null) return;

    if (!isFinal &&
        newMaterials.pipes.isEmpty &&
        newMaterials.cables.isEmpty &&
        _mountingType == 'NONE') { // [DIHAPUS] Cek _hasJasaPerapihan
      return;
    }

    context.read<InstallationBloc>().add(SaveMaterialSet(
        unitIndex: widget.target.unitIndex,
        materials: newMaterials,
        isFinal: isFinal));

    if (isFinal) {
      _isSubmittingFinal = true;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Data Material Tersimpan"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating));
  }

  Widget _buildFixedRow(
      {required Map<String, dynamic> form,
        required List<InstallationMasterOptionModel> articleOptions,
        required String labelArticle}) {
    List<InstallationBrandModel> currentBrands = [];
    if (form['articleId'] != null) {
      try {
        final selectedOpt =
        articleOptions.firstWhere((e) => e.id == form['articleId']);
        currentBrands = selectedOpt.brands;
      } catch (_) {}
    }

    return Column(children: [
      _buildDropdown(
          label: labelArticle,
          value: form['articleId'],
          items: articleOptions
              .map((e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) {
            setState(() {
              form['articleId'] = v;
              form['brandId'] = null;
            });
            _onFormChanged();
          }),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            flex: 3,
            child: _buildDropdown(
                label: "Merk",
                value: form['brandId'],
                items: currentBrands
                    .map((e) => DropdownMenuItem(
                    value: e.id,
                    child:
                    Text(e.name, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  setState(() => form['brandId'] = v);
                  _onFormChanged();
                })),
        const SizedBox(width: 12),
        Expanded(
            flex: 2,
            child: _buildTextField(
                controller: form['lengthController'], label: "Panjang (m)")),
      ]),
    ]);
  }

  Widget _buildRemovableRow(
      {required int index,
        required Map<String, dynamic> form,
        required List<InstallationMasterOptionModel> articleOptions,
        required String labelArticle,
        required VoidCallback onRemove}) {
    List<InstallationBrandModel> currentBrands = [];
    if (form['articleId'] != null) {
      try {
        final selectedOpt =
        articleOptions.firstWhere((e) => e.id == form['articleId']);
        currentBrands = selectedOpt.brands;
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: _buildDropdown(
                  label: labelArticle,
                  value: form['articleId'],
                  items: articleOptions
                      .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name,
                          style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      form['articleId'] = v;
                      form['brandId'] = null;
                    });
                    _onFormChanged();
                  })),
          const SizedBox(width: 8),
          InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.red[700], size: 20)))
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              flex: 3,
              child: _buildDropdown(
                  label: "Merk",
                  value: form['brandId'],
                  items: currentBrands
                      .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name,
                          style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => form['brandId'] = v);
                    _onFormChanged();
                  })),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: _buildTextField(
                  controller: form['lengthController'], label: "Panjang (m)")),
        ]),
      ]),
    );
  }

  Widget _buildAdditionalCableRow(int index) {
    String usage = _cableAdditionalForms[index]['usageType'];
    List<InstallationMasterOptionModel> opts =
    (usage == 'KABEL_DUCT') ? _ductOptions : _cableOptions;
    String label = (usage == 'KABEL_DUCT') ? "Jenis Duct" : "Jenis Kabel";

    List<InstallationBrandModel> currentBrands = [];
    String? artId = _cableAdditionalForms[index]['articleId'];
    if (artId != null) {
      try {
        final selectedOpt = opts.firstWhere((e) => e.id == artId);
        currentBrands = selectedOpt.brands;
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [
              _buildToggleChip(index, "Power", "KABEL_POWER", usage),
              _buildToggleChip(index, "Duct", "KABEL_DUCT", usage),
            ]),
          ),
          InkWell(
              onTap: () => _removeCableAdditionalRow(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.close, color: Colors.red[700], size: 18)))
        ]),
        const SizedBox(height: 12),
        _buildDropdown(
            label: label,
            value: _cableAdditionalForms[index]['articleId'],
            items: opts
                .map((e) => DropdownMenuItem(
                value: e.id,
                child: Text(e.name, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) {
              setState(() {
                _cableAdditionalForms[index]['articleId'] = v;
                _cableAdditionalForms[index]['brandId'] = null;
              });
              _onFormChanged();
            }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              flex: 3,
              child: _buildDropdown(
                  label: "Merk",
                  value: _cableAdditionalForms[index]['brandId'],
                  items: currentBrands
                      .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name,
                          style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _cableAdditionalForms[index]['brandId'] = v);
                    _onFormChanged();
                  })),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: _buildTextField(
                  controller: _cableAdditionalForms[index]['lengthController'],
                  label: "Panjang (m)")),
        ]),
      ]),
    );
  }

  Widget _buildDropdown(
      {required String label,
        required String? value,
        required List<DropdownMenuItem<String>> items,
        required Function(String?) onChanged}) {
    return DropdownButtonFormField2<String>(
      isExpanded: true,
      decoration: InputDecoration(
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          labelText: label,
          border: _inputBorder,
          enabledBorder: _inputBorder,
          focusedBorder: _focusedBorder,
          filled: true,
          fillColor: Colors.white),
      hint: const Text('Pilih...',
          style: TextStyle(fontSize: 13, color: Colors.grey)),
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _buildToggleChip(
      int index, String label, String value, String current) {
    bool active = value == current;
    bool isTaken = _cableAdditionalForms
        .asMap()
        .entries
        .any((e) => e.key != index && e.value['usageType'] == value);

    if (isTaken) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade300,
                decoration: TextDecoration.lineThrough)),
      );
    }

    return GestureDetector(
      onTap: () {
        if (!active) {
          setState(() {
            _cableAdditionalForms[index]['usageType'] = value;
            _cableAdditionalForms[index]['articleId'] = null;
          });
          _onFormChanged();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: active ? Colors.orange.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.orange.shade900 : Colors.grey)),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          labelText: label,
          border: _inputBorder,
          enabledBorder: _inputBorder,
          focusedBorder: _focusedBorder,
          filled: true,
          fillColor: Colors.white),
    );
  }

  Widget _buildRadioTile(String title, String value) {
    bool selected = _mountingType == value;
    return InkWell(
      onTap: () {
        setState(() => _mountingType = value);
        _onFormChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
            color: selected ? Colors.green.shade50 : null,
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.green : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.green.shade900 : Colors.black87))
        ]),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))));

  Widget _buildHeaderInfo() {
    String indoorSN = widget.existingData.pairedSerialNo ?? '-';
    String indoorName = "Indoor Unit";
    if (indoorSN != '-' && indoorSN.isNotEmpty) {
      try {
        final inUnit = context
            .read<InstallationBloc>()
            .state
            .draftEntry
            ?.units
            .firstWhere((u) => u.serialNo == indoorSN && u.articleType == 'IN');
        if (inUnit != null) indoorName = inUnit.articleDesc;
      } catch (_) {}
    }
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(FontAwesomeIcons.doorOpen,
                        size: 16, color: Colors.indigo)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("INDOOR",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text(indoorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          Text(indoorSN,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.indigo[800],
                                  fontWeight: FontWeight.bold))
                        ]))
              ]),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1)),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(FontAwesomeIcons.fan,
                        size: 16, color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("OUTDOOR",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text(widget.target.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          Text(widget.existingData.serialNo,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold))
                        ]))
              ]),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSubmittingFinal || _isOriginalCompleted) {
          if (context.mounted) Navigator.of(context).pop(result);
          return;
        }
        if (_isBackDataSaved) return;
        _isBackDataSaved = true;
        _saveInternal(isFinal: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                      title: "PIPA AC (REFRIGERANT)",
                      icon: FontAwesomeIcons.snowflake,
                      color: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      isMandatory: true,
                      children: [
                        _buildFixedRow(
                            form: _pipeACForm,
                            articleOptions: _pipeOptions,
                            labelArticle: "Jenis Pipa AC"),
                      ]),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                      title: "PIPA DRAIN (PEMBUANGAN)",
                      icon: FontAwesomeIcons.faucet,
                      color: Colors.cyan.shade50,
                      iconColor: Colors.cyan,
                      children: [
                        ..._pipeDrainForms.asMap().entries.map((e) =>
                            _buildRemovableRow(
                                index: e.key,
                                form: e.value,
                                articleOptions: _drainOptions,
                                labelArticle: "Jenis Pipa Drain",
                                onRemove: () => _removePipeDrainRow(e.key))),
                        if (_pipeDrainForms.isEmpty)
                          _buildAddButton("Tambah Pipa Drain",
                                  () => _addPipeDrainRow(null)),
                      ]),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                      title: "KABEL CONTROL",
                      icon: FontAwesomeIcons.plug,
                      color: Colors.orange.shade50,
                      iconColor: Colors.orange,
                      isMandatory: true,
                      children: [
                        _buildFixedRow(
                            form: _cableControlForm,
                            articleOptions: _cableOptions,
                            labelArticle: "Jenis Kabel Control"),
                      ]),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                      title: "KABEL TAMBAHAN / DUCT",
                      icon: FontAwesomeIcons.bolt,
                      color: Colors.yellow.shade50,
                      iconColor: Colors.orange.shade800,
                      children: [
                        ..._cableAdditionalForms
                            .asMap()
                            .entries
                            .map((e) => _buildAdditionalCableRow(e.key)),
                        if (_cableAdditionalForms.length < 2)
                          _buildAddButton("Tambah Kabel Power / Duct",
                                  () => _addCableAdditionalRow(null)),
                      ]),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                      title: "MOUNTING", // [DIUBAH] Judulnya dirapikan
                      icon: FontAwesomeIcons.screwdriverWrench,
                      color: Colors.grey.shade100,
                      iconColor: Colors.grey.shade700,
                      children: [
                        const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text("Pilih Mounting:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black54))),
                        _buildRadioTile("Tidak Ada", "NONE"),
                        const Divider(height: 1),
                        _buildRadioTile("Bracket Outdoor", "BRACKET"),
                        const Divider(height: 1),
                        _buildRadioTile("Kerangkeng", "KERANGKENG"),
                        const Divider(height: 1),
                        _buildRadioTile("Mounting Outdoor", "MOUNTING_OUTDOOR"),

                        // [DIHAPUS] Switch Biaya Tambahan Jasa Perapihan
                      ]),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4))
            ]),
            child: ElevatedButton(
              onPressed: () => _saveInternal(isFinal: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_as_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text("SIMPAN FINAL",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white))
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title,
        required IconData icon,
        required Color color,
        required Color iconColor,
        required List<Widget> children,
        bool isMandatory = false}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: color,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          fontSize: 13))),
              if (isMandatory)
                Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: iconColor.withOpacity(0.3))),
                    child: Text("WAJIB",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: iconColor)))
            ])),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children))
      ]),
    );
  }
}