// lib/screens/collectrice/login_screen.dart
import 'package:flutter/material.dart';
import '../../config/locale_manager.dart';
import '../../services/supabase_service.dart';
import '../../services/gps_service.dart';
import 'home_screen.dart';
import 'inscription_screen.dart';

class CollectriceLoginScreen extends StatefulWidget {
  final LocaleManager localeManager;
  const CollectriceLoginScreen({super.key, required this.localeManager});

  @override
  State<CollectriceLoginScreen> createState() =>
      _CollectriceLoginScreenState();
}

class _CollectriceLoginScreenState extends State<CollectriceLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final t = widget.localeManager.t;
    final collectrice =
        await SupabaseService.loginByPhone(_phoneController.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (collectrice != null) {
      await GpsService.requestPermissions();
      GpsService.startPassiveTracking(collectrice.id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CollectriceHomeScreen(
            collectrice: collectrice,
            localeManager: widget.localeManager,
          ),
        ),
      );
    } else {
      // Vérifier le statut du numéro
      final statut = await SupabaseService.verifierStatut(
          _phoneController.text.trim());
      setState(() {
        _error = statut == 'en_attente'
            ? 'Compte en attente de validation superviseur'
            : statut == 'rejetee'
                ? 'Compte rejeté. Contactez votre superviseur'
                : t.unknownNumber;
      });
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
            colors: [Color(0xFF05060A), Color(0xFF0A1628), Color(0xFF05060A)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1BD6FF), Color(0xFF0A6EFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1BD6FF).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_pin_rounded,
                        color: Colors.white, size: 44),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'FU-DICIA',
                    style: TextStyle(
                      color: Color(0xFF1BD6FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.collectriceSpace,
                    style: const TextStyle(
                      color: Color(0xFF1BD6FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Champ téléphone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: t.phonePlaceholder,
                      hintText: t.phoneHint,
                      prefixIcon: const Icon(Icons.phone_rounded,
                          color: Color(0xFF1BD6FF)),
                      errorText: _error,
                      errorStyle:
                          const TextStyle(color: Color(0xFFFF3B3B)),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 28),

                  // Bouton connexion
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(t.accessTerrain),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton mode test
                  TextButton(
                    onPressed: () async {
                      _phoneController.text = '+22890000001';
                      await _login();
                    },
                    child: Text(
                      t.testMode,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton inscription
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InscriptionScreen(
                            localeManager: widget.localeManager),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Première fois ? ',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          const TextSpan(
                            text: "S'inscrire",
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}