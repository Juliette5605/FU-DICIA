// lib/screens/collectrice/sos_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/gps_service.dart';

class SosScreen extends StatefulWidget {
  final Collectrice collectrice;

  const SosScreen({super.key, required this.collectrice});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _sending = false;
  bool _sent = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSos() async {
    setState(() => _sending = true);

    final pos = await GpsService.getCurrentPosition();

    final locationText = pos != null
        ? 'GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
        : 'Position non disponible';

    final message = Uri.encodeComponent(
      '🆘 ALERTE SOS — FU-DICIA\n'
      'Collectrice: ${widget.collectrice.fullName}\n'
      'Zone: ${widget.collectrice.zone}\n'
      '$locationText\n'
      'Heure: ${DateTime.now().toString().substring(0, 19)}',
    );

    // Numéro superviseur (à configurer)
    const superviseurTel = '+22890000000';

    final uri = Uri.parse('sms:$superviseurTel?body=$message');
    try {
      await launchUrl(uri);
    } catch (_) {
      // Fallback: appel direct
      final callUri = Uri.parse('tel:$superviseurTel');
      await launchUrl(callUri);
    }

    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text('ALERTE SOS'),
        backgroundColor: const Color(0xFFFF3B3B).withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton SOS pulsant
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + (_pulseCtrl.value * 0.05),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF3B3B).withOpacity(0.15),
                    border: Border.all(
                      color: const Color(0xFFFF3B3B)
                          .withOpacity(0.5 + _pulseCtrl.value * 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B3B)
                            .withOpacity(0.2 + _pulseCtrl.value * 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: _sent
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF00E676), size: 80)
                      : const Icon(Icons.emergency_rounded,
                          color: Color(0xFFFF3B3B), size: 80),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Text(
              _sent ? 'ALERTE ENVOYÉE !' : 'EN CAS DE DANGER',
              style: TextStyle(
                color: _sent ? const Color(0xFF00E676) : const Color(0xFFFF3B3B),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _sent
                  ? 'Votre superviseur a été alerté avec votre position GPS'
                  : 'Appuyez pour envoyer une alerte SMS avec votre position GPS à votre superviseur',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            if (!_sent)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendSos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B3B),
                    foregroundColor: Colors.white,
                  ),
                  child: _sending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '🆘 ENVOYER ALERTE SOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),

            if (_sent) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('RETOUR'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
