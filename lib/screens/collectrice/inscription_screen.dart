// lib/screens/collectrice/inscription_screen.dart
import 'package:flutter/material.dart';
import '../../config/locale_manager.dart';
import '../../services/supabase_service.dart';

class InscriptionScreen extends StatefulWidget {
  final LocaleManager localeManager;
  const InscriptionScreen({super.key, required this.localeManager});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telController = TextEditingController();
  String? _zoneSelectionnee;
  bool _loading = false;
  String? _error;
  bool _succes = false;

  final List<String> _zones = [
    'Marché Adawlato',
    'Marché Agoè',
    'Marché Hédzranawoé',
    'Marché Assigamé',
    'Marché Tokoin',
    'Marché Nyékonakpoè',
    'Marché Adidogomé',
    'Marché Akossombo',
    'Marché Bè',
    'Marché Hanoukopé',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telController.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    // Validation
    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty ||
        _telController.text.trim().isEmpty ||
        _zoneSelectionnee == null) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }

    if (!_telController.text.trim().startsWith('+')) {
      setState(
          () => _error = 'Le numéro doit commencer par + (ex: +22890000001)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await SupabaseService.inscrireCollectrice(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _telController.text.trim(),
      zone: _zoneSelectionnee!,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok == 'existe') {
      setState(() => _error = 'Ce numéro est déjà enregistré.');
    } else if (ok == 'erreur') {
      setState(() => _error = 'Erreur réseau. Réessayez.');
    } else {
      setState(() => _succes = true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: _succes ? _buildSucces() : _buildFormulaire(),
        ),
      ),
    );
  }

  Widget _buildFormulaire() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Bouton retour
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_rounded,
                      color: Color(0xFF1BD6FF), size: 18),
                  Text('Retour',
                      style:
                          TextStyle(color: Color(0xFF1BD6FF), fontSize: 14)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00897B)]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 40),
          ),

          const SizedBox(height: 20),

          const Text(
            'NOUVELLE COLLECTRICE',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Votre demande sera validée par le superviseur',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),

          const SizedBox(height: 36),

          // Champ Prénom
          TextField(
            controller: _prenomController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Prénom',
              prefixIcon:
                  Icon(Icons.person_rounded, color: Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 16),

          // Champ Nom
          TextField(
            controller: _nomController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom de famille',
              prefixIcon:
                  Icon(Icons.badge_rounded, color: Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 16),

          // Champ Téléphone
          TextField(
            controller: _telController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '+228XXXXXXXX',
              prefixIcon:
                  Icon(Icons.phone_rounded, color: Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 16),

          // Sélecteur de zone
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _zoneSelectionnee != null
                    ? const Color(0xFF00E676)
                    : const Color(0xFF1BD6FF).withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _zoneSelectionnee,
                hint: const Text('Sélectionner votre zone / marché',
                    style: TextStyle(color: Color(0xFF3D4F6A), fontSize: 14)),
                dropdownColor: const Color(0xFF0D1117),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF00E676)),
                items: _zones
                    .map((z) => DropdownMenuItem(
                          value: z,
                          child: Text(z,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _zoneSelectionnee = v),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B3B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF3B3B).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFFF3B3B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFFF3B3B), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Bouton s'inscrire
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _inscrire,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('ENVOYER MA DEMANDE',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSucces() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.5),
                    width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00E676), size: 55),
            ),
            const SizedBox(height: 24),
            const Text(
              'Demande envoyée !',
              style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre demande est en attente de validation par le superviseur.\n\nVous recevrez une confirmation dès que votre compte sera activé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BD6FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('RETOUR À LA CONNEXION',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}