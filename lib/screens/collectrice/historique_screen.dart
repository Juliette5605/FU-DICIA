// lib/screens/collectrice/historique_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Assure-toi que ce fichier exporte bien la classe Collecte et Collectrice
import '../../models/models.dart'; 
import '../../services/database_service.dart';

class HistoriqueScreen extends StatefulWidget {
  final Collectrice collectrice;

  const HistoriqueScreen({super.key, required this.collectrice});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  // Correction du type : Utilisation du modèle 'Collecte' défini dans tes fichiers models
  List<Collecte> _collectes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await DatabaseService.getCollectesToday(widget.collectrice.id);
      if (mounted) {
        setState(() {
          _collectes = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des données')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    
    // Correction : Utilisation de 'montantReel' au lieu de 'montant'
    final total = _collectes.fold<double>(0, (s, c) => s + c.montantReel);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text('HISTORIQUE DU JOUR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1BD6FF)),
            )
          : Column(
              children: [
                // Résumé des collectes
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        // Mise à jour de withOpacity vers withValues (norme Flutter 2024+)
                        const Color(0xFF1BD6FF).withValues(alpha: 0.12),
                        const Color(0xFF1BD6FF).withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1BD6FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_collectes.length} collectes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${formatter.format(total)} F',
                        style: const TextStyle(
                          color: Color(0xFF1BD6FF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des transactions
                Expanded(
                  child: _collectes.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune collecte aujourd\'hui',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _collectes.length,
                          itemBuilder: (context, i) {
                            final c = _collectes[i];
                            // Logique de validation visuelle (exemple : vert si >= 3000)
                            final bool ok = c.montantReel >= 3000;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1117),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: ok
                                      ? const Color(0xFF00E676).withValues(alpha: 0.25)
                                      : const Color(0xFFFF3B3B).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ok
                                          ? const Color(0xFF00E676).withValues(alpha: 0.1)
                                          : const Color(0xFFFF3B3B).withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      ok ? Icons.check_circle : Icons.warning,
                                      color: ok
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF3B3B),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.clientNom,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(c.collectedAt),
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${formatter.format(c.montantReel)} F',
                                        style: TextStyle(
                                          color: ok
                                              ? const Color(0xFF00E676)
                                              : const Color(0xFFFF3B3B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // Indicateur de synchronisation cloud
                                      Icon(
                                        c.synced ? Icons.cloud_done : Icons.cloud_off,
                                        size: 12,
                                        color: c.synced 
                                          ? const Color(0xFF1BD6FF) 
                                          : Colors.white24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}