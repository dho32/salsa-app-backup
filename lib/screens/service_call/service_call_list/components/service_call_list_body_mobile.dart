import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/screens/service_call/service_call_list/components/widgets/service_call_list_widgets.dart';
import '../../../../blocs/service_call/service_call_list/service_call_list_bloc.dart';
import '../../../../blocs/service_call/service_call_list/service_call_list_event.dart';
import '../../../../blocs/service_call/service_call_list/service_call_list_repository.dart';
import '../../../../blocs/service_call/service_call_list/service_call_list_state.dart';
import '../../../../components/shared_function.dart';

class ServiceCallListBodyMobile extends StatefulWidget {
  final String initialStatus;
  final String maintenanceBy;

  const ServiceCallListBodyMobile({
    super.key, required this.initialStatus, required this.maintenanceBy,});

  @override
  State<ServiceCallListBodyMobile> createState() =>
      _ServiceCallListBodyMobileState();
}

class _ServiceCallListBodyMobileState extends State<ServiceCallListBodyMobile> {
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterKeywords = [];
  final Map<String, Color> _chipBackgroundColors = {};
  String _selectedStatus = '';
  late ServiceCallListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _bloc = ServiceCallListBloc(
      repository: ServiceCallListRepository(),
    );

    _triggerSearch();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _bloc.add(FetchServiceCallList());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _triggerSearch() {
    _bloc.add(UpdateServiceCallFilter(
      status: _selectedStatus,
      keyword: _filterKeywords.join(','),
      maintenanceBy: widget.maintenanceBy,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildFilterBar()),
          if (_filterKeywords.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: ChipBarDelegate(_buildChipBar()),
            ),
          SliverList(
            delegate: SliverChildListDelegate([_buildListSection()]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFEFEF),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Semua')),
              DropdownMenuItem(
                  value: 'not_done_priority', child: Text('Prioritas')),
              DropdownMenuItem(value: 'not_done', child: Text('Belum Selesai')),
              DropdownMenuItem(value: 'done', child: Text('Selesai')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value ?? '');
              _triggerSearch();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ketik nama/kode/alamat lalu tekan Enter',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty && !_filterKeywords.contains(trimmed)) {
                setState(() {
                  _filterKeywords.add(trimmed);
                  _chipBackgroundColors[trimmed] = generateRandomColor();
                  _searchController.clear();
                });
                _triggerSearch();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChipBar() {
    return Container(
      color: const Color(0xFFEFEFEF), // Sama dengan filter bar
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Wrap(
        spacing: 8,
        children: _filterKeywords.map((keyword) {
          final backgroundColor =
              _chipBackgroundColors[keyword] ?? Colors.grey.shade400;
          final textColor = backgroundColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white;

          return Chip(
            label: Text(keyword, style: TextStyle(color: textColor)),
            deleteIcon: Icon(Icons.close, color: textColor),
            backgroundColor: backgroundColor,
            shape: const StadiumBorder(),
            onDeleted: () {
              setState(() {
                _filterKeywords.remove(keyword);
                _chipBackgroundColors.remove(keyword);
              });
              _triggerSearch();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListSection() {
    return BlocBuilder<ServiceCallListBloc, ServiceCallListState>(
      builder: (context, state) {
        if (state is ServiceCallListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ServiceCallListError) {
          return Center(child: buildErrorView(message: state.message));
        } else if (state is ServiceCallListLoaded) {
          if (state.list.isEmpty) {
            return Center(child: buildNoDataView(message: "Data tidak ditemukan"));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.list.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < state.list.length) {
                final item = state.list[index];
                return buildServiceCallCard(context, item, widget.maintenanceBy);
              } else {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget buildNoDataView({String message = "Tidak ada data"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorView({String message = "Error Data"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


