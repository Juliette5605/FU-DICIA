// lib/screens/superviseur/supervisor_login_screen.dart
import 'package:flutter/material.dart';
import '../../config/locale_manager.dart';
import 'dashboard_screen.dart';

class SupervisorLoginScreen extends StatefulWidget {
  final LocaleManager localeManager;
  const SupervisorLoginScreen({super.key, required this.localeManager});

  @override
  State<SupervisorLoginScreen> createState() =>
      _SupervisorLoginScreenState();
}

class _SupervisorLoginScreenState extends State<SupervisorLoginScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  // Code superviseur simple pour la démo
  static const _supervisorCode = '1234';

  Future<void> _login() async {
    final t = widget.localeManager.t;
    if (_codeController.text == _supervisorCode) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SupervisorDashboardScreen(
              localeManager: widget.localeManager,
            ),
          ),
        );
      }
    } else {
      setState(() => _error = t.wrongCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.localeManager.t;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF05060A), Color(0xFF0A0A28)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF3D1ECC)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withOpacity(0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.dashboard_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CENTRE DE CONTRÔLE',
                  style: TextStyle(
                    color: Color(0xFF7C4DFF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Accès superviseur sécurisé',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, letterSpacing: 6),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Code d\'accès',
                    prefixIcon:
                        const Icon(Icons.lock_rounded, color: Color(0xFF7C4DFF)),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ACCÉDER AU DASHBOARD'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Code démo: 1234',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.2), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
