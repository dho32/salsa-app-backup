import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import 'components/maintenance_selection_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String? emailError;
  String? passwordError;
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  String _appVersion = '';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _initAppVersion();
  }

  Future<void> _initAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _appVersion = 'Versi $_version';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void login() {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(LoginRequested(
        emailController.text.trim().toLowerCase(), passwordController.text, _version));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      if (state is AuthFailure) {
        setState(() {
          final errorMsg = state.message.toLowerCase();
          if (errorMsg.contains("user")) {
            emailError = state.message;
            FocusScope.of(context).requestFocus(emailFocusNode);
          } else if (errorMsg.contains("password")) {
            passwordError = state.message;
            FocusScope.of(context).requestFocus(passwordFocusNode);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        });

        _formKey.currentState?.validate();
      } else if (state is AuthRequiresMaintenanceSelection) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: MaintenanceSelectionDialog(
              options: state.maintenanceOptions,
              token: state.token,
            ),
          ),
        );
      }
    }, builder: (context, state) {
      bool isLoading = context.watch<AuthBloc>().state is AuthLoading;
      return Scaffold(
        body: Stack(
          children: [
            // Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Foreground content with fade-in animation
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 130,
                          width: 130,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            // biar bulat
                            child: Image.asset('assets/images/salsa.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "SELAMAT DATANG DI SALSA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Service And Log Support Application",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          focusNode: emailFocusNode,
                          controller: emailController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nomor telp tidak boleh kosong';
                            }

                            // // Validasi format email
                            // final emailRegExp =
                            //     RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            // if (!emailRegExp.hasMatch(value.trim())) {
                            //   return 'Format email tidak valid';
                            // }

                            // Tambahkan ini:
                            if (emailError != null) {
                              final msg = emailError;
                              emailError = null;
                              return msg;
                            }

                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "Nomor Telepon / NIK",
                            hintText:
                                "Masukan Nomor Telepon / NIK anda yang terdaftar",
                            prefixIcon:
                                const Icon(Icons.account_circle_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          focusNode: passwordFocusNode,
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password tidak boleh kosong';
                            }

                            if (passwordError != null) {
                              final msg = passwordError;
                              passwordError = null;
                              return msg;
                            }

                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.password_sharp),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ))
                                : const Icon(
                                    Icons.login,
                                    color: Colors.white60,
                                  ),
                            label: isLoading
                                ? const Text("LOGGING IN...",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold))
                                : const Text("LOGIN",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Tidak punya akun? Hubungi admin.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        if (_appVersion.isNotEmpty)
                          Text(
                            _appVersion,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
