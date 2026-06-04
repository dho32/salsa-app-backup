import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/auth/auth_event.dart';
import '../../../../blocs/auth/auth_storage.dart';

class MainProfileBodyMobile extends StatefulWidget {
  const MainProfileBodyMobile({super.key});

  @override
  State<MainProfileBodyMobile> createState() => _MainProfileBodyMobileState();
}

class _MainProfileBodyMobileState extends State<MainProfileBodyMobile> {
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthStorage.getUser();
    if (!mounted) return;
    setState(() {
      userName = user['name'] ?? '';
      userEmail = user['email'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // HEADER
        Container(
          padding: EdgeInsets.only(top: statusBarHeight + 24, bottom: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/images/salsa.png'),
              ),
              const SizedBox(height: 10),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                userEmail,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // MENU
        const ProfileMenuItem(icon: Icons.edit, label: 'Edit Profile'),
        const ProfileMenuItem(icon: Icons.help_outline, label: 'Help Center'),

        // LOGOUT
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: Colors.grey.withAlpha(50),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                context.read<AuthBloc>().add(LoggedOut());
              },
              child: const ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: Colors.grey.withAlpha(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Tambah navigasi sesuai kebutuhan
          },
          child: ListTile(
            leading: Icon(icon, color: Colors.green),
            title: Text(label),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
        ),
      ),
    );
  }
}
