import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:salsa/components/widgets/default_card_list.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../blocs/auth/auth_storage.dart';
import '../../../blocs/schedule_calendar/schedule_calendar_bloc.dart';
import '../../../components/shared_function.dart';

class ScheduleCalendarBodyMobile extends StatefulWidget {
  const ScheduleCalendarBodyMobile({super.key});

  @override
  State<ScheduleCalendarBodyMobile> createState() =>
      _ScheduleCalendarBodyMobileState();
}

class _ScheduleCalendarBodyMobileState
    extends State<ScheduleCalendarBodyMobile> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late String formattedDate;
  String userName = "";
  String maintenanceByName = "";
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    formattedDate = getFormattedIndonesianDate();
    _loadUserData();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await AuthStorage.getUser();
    setState(() {
      userName = user['name'] ?? '';
      maintenanceByName = user['maintenance_by_name'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCalendarBloc, ScheduleCalendarState>(
      builder: (context, state) {
        if (state is ScheduleCalendarError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is ScheduleCalendarLoaded) {
          _selectedDay = state.selectedDay;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // BAGIAN 1: HEADER (Di Atas)
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 16),
                  child: buildHeader(
                    title: "Welcome to SALSA",
                    user: userName,
                    company: maintenanceByName,
                    date: formattedDate,
                  ),
                ),

                // BAGIAN 2: DAFTAR JADWAL (DI TENGAH, MENGISI SISA RUANG)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildPOListSection(context, state),
                      ),
                      Expanded(flex: 2, child: _buildCalendar(context, state)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// Membangun widget TableCalendar
  Widget _buildCalendar(BuildContext context, ScheduleCalendarLoaded state) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month - 1, 1);
    final lastDay = DateTime(now.year, now.month + 2, 0);

    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(255, 255, 255, 0.4),
              Color.fromRGBO(255, 255, 255, 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white, // Latar belakang putih solid
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Tambahkan sedikit bayangan agar terlihat bagus
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 64,
              child: TableCalendar(
                // Rentang tanggal yang bisa diakses di kalender
                firstDay: firstDay,
                lastDay: lastDay,
                focusedDay: _focusedDay,

                // Menentukan tanggal mana yang akan ditandai sebagai 'terpilih'
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                // Callback saat pengguna mengetuk sebuah tanggal
                onDaySelected: (selectedDay, focusedDay) {
                  // Hindari panggil event jika tanggal yang sama diklik berulang kali
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    // 1. Update UI lokal untuk memindahkan marker visual secara instan
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // 2. Kirim event ke BLoC untuk mengambil data baru
                    context
                        .read<ScheduleCalendarBloc>()
                        .add(SelectCalendarDay(selectedDay));
                  }
                },

                // Callback saat pengguna mengganti bulan/halaman
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },

                // Kustomisasi tampilan header (misal: "Juni 2025")
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),

                // Builder untuk membuat marker kustom di bawah tanggal
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final dayUtc = DateTime.utc(day.year, day.month, day.day);
                    final dataForDay = state.scheduleData[dayUtc];
                    if (dataForDay != null) {
                      return Positioned(
                        bottom: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (dataForDay.scCount > 0)
                              _buildMarker(dataForDay.scCount,Colors.red),
                            if (dataForDay.posCount > 0)
                              _buildMarker(dataForDay.posCount,Colors.green),
                          ],
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper kecil untuk membuat satu titik marker
  Widget _buildMarker(int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPOListSection(
      BuildContext context, ScheduleCalendarLoaded state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(255, 255, 255, 0.4),
              Color.fromRGBO(255, 255, 255, 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jadwal untuk ${DateFormat('d MMMM yyyy', 'id_ID').format(state.selectedDay)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: ${state.selectedDayPOList.length}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Tampilkan pesan jika daftar kosong
                  if (state.selectedDayPOList.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Tidak ada jadwal pada tanggal ini.',
                        ),
                      ),
                    )
                  // Tampilkan PageView jika ada isinya
                  else
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: (state.selectedDayPOList.length / 2).ceil(),
                        // Hitung jumlah halaman
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final int startIndex = index * 2;
                          final int endIndex =
                              (startIndex + 2 > state.selectedDayPOList.length)
                                  ? state.selectedDayPOList.length
                                  : startIndex + 2;
                          final pageItems =
                              state.selectedDayPOList.sublist(startIndex, endIndex);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: pageItems
                                .map((po) => buildServiceCallCard(context, po))
                                .toList(),
                          );
                        },
                      ),
                    ),

                  // Tampilkan indikator jika ada lebih dari 1 halaman
                  if ((state.selectedDayPOList.length / 2).ceil() > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildPageIndicator(
                          (state.selectedDayPOList.length / 2).ceil(),
                          _currentPage),
                    ),
                ],
              ),
              if (state.isListLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget buildServiceCallCard(BuildContext context, POService po) {
    Color statusColor = po.isDone ? Colors.green : Colors.red;
    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  po.type == "POS"
                      ? Icons.calendar_month
                      : FontAwesomeIcons.screwdriverWrench,
                  color: po.isDone ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  po.type == "POS"
                      ? 'Service Bulanan'
                      : 'Service Call',
                  style: TextStyle(
                    fontSize: 12,
                    color: po.isDone ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              po.transNo,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          po.description,
          style: const TextStyle(fontSize: 16),
          softWrap: true,
        ),
      ],
    );
    return cardList(statusColor: statusColor, child: child, onTap: (){});
  }

  Widget buildHeader({
    required String title,
    required String user,
    required String company,
    required String date,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "$user / $company",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(date,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset('assets/images/salsa.png', width: 60, height: 60),
        ),
      ],
    );
  }
}
