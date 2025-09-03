// lib/screens/schedule_list/components/schedule_list_body_mobile.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:salsa/blocs/schedule/schedule_list/schedule_list_repository.dart';
import 'package:salsa/models/schedule/schedule_list_model.dart';

import '../../../../blocs/schedule/schedule_list/schedule_list_bloc.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/widgets/default_card_list.dart';
import '../../proof_of_service/proof_of_service_screen.dart';

class ScheduleListBodyMobile extends StatefulWidget {
  final String initialStatus;
  final String maintenanceBy;

  const ScheduleListBodyMobile({
    super.key,
    required this.initialStatus,
    required this.maintenanceBy,
  });

  @override
  State<ScheduleListBodyMobile> createState() => _ScheduleListBodyMobileState();
}

class _ScheduleListBodyMobileState extends State<ScheduleListBodyMobile> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Color> _chipBackgroundColors = {};
  final ScrollController _scrollController = ScrollController();
  final List<String> _filterKeywords = [];
  String _selectedStatus = '';
  late ScheduleListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _bloc = ScheduleListBloc(
      repository: ScheduleListRepository(),
    );

    _triggerSearch();

    // _scrollController.addListener(() {
    //   if (_scrollController.position.pixels >=
    //       _scrollController.position.maxScrollExtent - 200) {
    //     _bloc.add(FetchScheduleList());
    //   }
    // });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _bloc.add(FetchScheduleList());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _triggerSearch() {
    _bloc.add(UpdateScheduleList(
      status: _selectedStatus,
      keyword: _filterKeywords.join(','),
      maintenanceBy: widget.maintenanceBy,
    ));
  }

// Helper untuk menghasilkan warna acak
  Color generateRandomColor() {
    final random = Random();
    return Color.fromARGB(255, 100 + random.nextInt(156),
        100 + random.nextInt(156), 100 + random.nextInt(156));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildFilterSection()),
          if (_filterKeywords.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: ChipBarDelegate(_buildChipBar()),
            ),
          _buildListSection(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFEFEF),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: 'priority', child: Text('Prioritas')),
              DropdownMenuItem(value: 'overdue', child: Text('Terlambat')),
              DropdownMenuItem(value: 'today', child: Text('Hari Ini')),
              DropdownMenuItem(value: 'scheduled', child: Text('Terjadwal')),
              DropdownMenuItem(value: 'done', child: Text('Selesai')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value ?? '');
              _triggerSearch();
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Status'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari & tekan enter...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
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
    return BlocBuilder<ScheduleListBloc, ScheduleListState>(
      builder: (context, state) {
        if (state is ScheduleListLoading) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }
        if (state is ScheduleListError) {
          return SliverFillRemaining(
              child: Center(child: Text('Error: ${state.message}')));
        }
        if (state is ScheduleListLoaded) {
          if (state.list.isEmpty) {
            return const SliverFillRemaining(
                child: Center(child: Text('Data tidak ditemukan.')));
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index < state.list.length) {
                  final item = state.list[index];
                  return _buildScheduleCard(context, item);
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
              childCount: state.list.length + (state.hasMore ? 1 : 0), // Tambah 1 untuk loading indicator
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, ScheduleListItemModel schedule) {
    final IconData statusIcon = schedule.scheduleStatus == "done"
        ? FontAwesomeIcons.check
        : schedule.scheduleStatus == "scheduled"
            ? FontAwesomeIcons.solidCalendarDays
            : schedule.scheduleStatus == "late"
                ? FontAwesomeIcons.triangleExclamation
                : FontAwesomeIcons.clock;
    final Color statusColor = schedule.scheduleStatus == "done"
        ? Colors.green
        : schedule.scheduleStatus == "scheduled"
            ? Colors.blue
            : schedule.scheduleStatus == "late"
                ? Colors.red
                : Colors.orange;
    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.transNo,
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      // Format tanggal agar mudah dibaca
                      DateFormat('d MMM yyyy').format(schedule.scheduleDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              schedule.type,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${schedule.shipToName} (${schedule.shipTo})',
          style: const TextStyle(fontSize: 16),
          softWrap: true,
        ),
        Text(
          schedule.branchName,
          style: const TextStyle(fontSize: 16),
          softWrap: true,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: cardList(
          statusColor: statusColor,
          child: child,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProofOfServiceScreen(
                  transNo: schedule.transNo, // Gunakan transNo dari objek job
                ),
              ),
            );
          }),
    );
  }
}

