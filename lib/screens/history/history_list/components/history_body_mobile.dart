import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../blocs/history/history_bloc.dart';
import '../../../../blocs/history/history_event.dart';
import '../../../../blocs/history/history_state.dart';
import '../../../../components/constants.dart';
import '../../../../models/history/history_transaction_model.dart';
import '../../history_detail/pos_history_detail/pos_history_detail_screen.dart';
import '../../history_detail/sc_history_detail/sc_history_detail_screen.dart';

class HistoryBodyMobile extends StatefulWidget {
  const HistoryBodyMobile({super.key});

  @override
  State<HistoryBodyMobile> createState() => _HistoryBodyMobileState();
}

class _HistoryBodyMobileState extends State<HistoryBodyMobile> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  final Map<String, String> _transactionTypeOptions = {
    'ALL': 'Semua',
    'service_call': 'Service Call',
    'proof_of_service': 'Proof of Service',
  };

  final Map<String, String> _statusOptions = {
    'ALL': 'Semua',
    'Selesai': 'Selesai',
    'Dalam Proses': 'Dalam Proses',
    'Upload Foto': 'Upload Foto',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<HistoryBloc>().add(HistoryFetched());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kColorBackgroundDefault,
      child: Column(
        children: [
          // --- Bagian Search & Filter ---
          _buildFilterSection(),

          // --- Daftar Transaksi ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<HistoryBloc>().add(const HistoryRefreshed());
                await context.read<HistoryBloc>().stream.firstWhere(
                    (state) => state.status != HistoryStatus.loading);
              },
              child: BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  switch (state.status) {
                    case HistoryStatus.failure:
                      return const Center(child: Text('Gagal memuat riwayat'));
                    case HistoryStatus.success:
                      if (state.transactions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 80.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset('assets/images/not_found.png',
                                  width: 200, height: 200),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.hasReachedMax
                            ? state.transactions.length
                            : state.transactions.length + 1,
                        controller: _scrollController,
                        itemBuilder: (BuildContext context, int index) {
                          return index >= state.transactions.length
                              ? const Center(child: CircularProgressIndicator())
                              : _buildHistoryCard(state.transactions[index]);
                        },
                      );
                    case HistoryStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    default:
                      return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk Search Bar dan Filter Dropdown
  Widget _buildFilterSection() {
    final currentState = context.read<HistoryBloc>().state;
    return Container(
      padding: const EdgeInsets.only(right: 16.0, left: 16, top: 16, bottom: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Masukkan nomor transaksi',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Panggil BLoC dengan teks dari controller
                  context.read<HistoryBloc>().add(
                      HistoryRefreshed(searchQuery: _searchController.text));
                  // Hilangkan fokus dari textfield
                  FocusScope.of(context).unfocus();
                },
              ),
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              context
                  .read<HistoryBloc>()
                  .add(HistoryRefreshed(searchQuery: value));
            },
          ),
          const SizedBox(height: 12),
          // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Jenis Transaksi',
                  value: currentState.transactionType,
                  items: _transactionTypeOptions,
                  onChanged: (value) {
                    if (value != null) {
                      context
                          .read<HistoryBloc>()
                          .add(HistoryRefreshed(transactionType: value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Status',
                  value: currentState.filterStatus,
                  items: _statusOptions,
                  onChanged: (value) {
                    if (value != null) {
                      context
                          .read<HistoryBloc>()
                          .add(HistoryRefreshed(status: value));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget helper untuk membuat DropdownButton
  Widget _buildDropdown({
    required String? label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.entries.map((entry) {
        // Gunakan .entries.map
        return DropdownMenuItem<String>(
          value: entry.key, // `value` adalah 'ALL'
          child: Text(entry.value,
              style: const TextStyle(fontSize: 14)), // Tampilan adalah 'Semua'
        );
      }).toList(),
      onChanged: onChanged,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Widget untuk menampilkan satu Card Riwayat
  Widget _buildHistoryCard(HistoryTransactionModel transaction) {
    final isServiceCall = transaction.transactionType == 'SERVICE_CALL';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (isServiceCall) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ScHistoryDetailScreen(
                          transNo: transaction.transNo,
                        )));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PosHistoryDetailScreen(
                          transNo: transaction.transNo,
                        )));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: No Transaksi & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transaction.transNo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: transaction.status.toUpperCase() == 'SELESAI'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        color: transaction.status.toUpperCase() == 'SELESAI'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              // Detail Informasi
              Row(
                children: [
                  Expanded(
                      child: _buildInfoItem(Icons.store_mall_directory_outlined,
                          'Nama Toko', transaction.storeName)),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _buildInfoItem(Icons.person_outline, 'PIC Toko',
                          transaction.picName)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today_outlined,
                      'Tanggal Servis',
                      DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(
                          DateTime.parse(transaction.serviceDate)),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _buildInfoItem(Icons.layers_outlined,
                          'Jumlah Unit', transaction.totalUnits.toString())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget helper untuk setiap item info di dalam card
  Widget _buildInfoItem(IconData icon, String label, String value) {
    Color color = Colors.blue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          maxRadius: 12,
          child: FaIcon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
