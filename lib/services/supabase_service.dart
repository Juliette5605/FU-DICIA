import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'database_service.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  static Future<Collectrice?> loginByPhone(String telephone) async {
    try {
      final data = await _client
          .from('collectrices')
          .select()
          .eq('telephone', telephone.trim())
          .maybeSingle();
      
      print('SUPABASE DATA: $data'); // ← ajoute CETTE ligne
      
      return data != null ? Collectrice.fromMap(data) : null;
    } catch (e) {
      print('Erreur Login Supabase: $e');
      return null;
    }
  }

  // ── SYNCHRONISATION UNITAIRE ──────────────────────────────
  static Future<bool> syncCollecte(Collecte c) async {
    try {
      // Conversion du modèle en Map pour l'insertion cloud
      await _client.from('collectes').insert(c.toMap());
      return true;
    } catch (e) {
      print('Erreur Insert Collecte sur Supabase: $e');
      return false;
    }
  }

  // ── RÉCUPÉRATION HISTORIQUE ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getCollectesAll() async {
    try {
      final data = await _client
          .from('collectes')
          .select('*, collectrices(nom, prenom, zone)')
          .order('collected_at', ascending: false)
          .limit(200);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  // ── GESTION DES ANOMALIES ──────────────────────────────────
  static Future<void> createAnomalie({
    required String collectriceId,
    required String type,
    required String severite,
    required int score,
    required String description,
  }) async {
    try {
      await _client.from('anomalies').insert({
        'collectrice_id': collectriceId,
        'type_anomalie': type,
        'severite': severite,
        'score': score,
        'description': description,
        'resolu': false,
      });
    } catch (e) {
      print('Erreur création anomalie: $e');
    }
  }

  // ── SYNC OFFLINE → ONLINE (CORRIGÉ) ──────────────────────
  static Future<int> syncPendingCollectes() async {
    int syncedCount = 0;
    
    // 1. Récupérer les collectes locales non synchronisées
    // (Utilise ta méthode DatabaseService.getUnsyncedCollectes)
    final pending = await DatabaseService.getUnsyncedCollectes();
    
    for (final c in pending) {
      final ok = await syncCollecte(c);
      
      if (ok) {
        // 2. Mise à jour du flag local
        // Utilise markCollecteSynced et convertit l'ID en int
        if (c.id != null) {
          final localId = int.tryParse(c.id.toString());
          if (localId != null) {
            await DatabaseService.markCollecteSynced(localId);
            syncedCount++;
          }
        }
      }
    }
    return syncedCount;
  }

  // ── STATS DASHBOARD ───────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

      final results = await Future.wait([
        _client.from('collectes').select().gte('collected_at', startOfDay),
        _client.from('anomalies').select().eq('resolu', false),
        _client.from('positions')
            .select('collectrice_id')
            .gte('recorded_at', DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String()),
      ]);

      final collectes = results[0] as List;
      final anomalies = results[1] as List;
      final positions = results[2] as List;

      final double totalMontant = collectes.fold<double>(
          0, (s, c) => s + ((c['montant_reel'] as num?)?.toDouble() ?? 0));

      return {
        'total_collectes': collectes.length,
        'total_montant': totalMontant,
        'anomalies_actives': anomalies.length,
        'agents_actifs': positions.map((p) => p['collectrice_id']).toSet().length,
      };
    } catch (e) {
      print('Erreur Stats Dashboard: $e');
      return {
        'total_collectes': 0,
        'total_montant': 0.0,
        'anomalies_actives': 0,
        'agents_actifs': 0,
      };
    }
  }

  // ── TEMPS RÉEL (STREAMS) ──────────────────────────────────
  static Stream<List<Map<String, dynamic>>> watchPositions() {
    return _client
        .from('positions')
        .stream(primaryKey: ['id'])
        .order('recorded_at', ascending: false)
        .limit(50)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  static Stream<List<Map<String, dynamic>>> watchAnomalies() {
    return _client
        .from('anomalies')
        .stream(primaryKey: ['id'])
        .eq('resolu', false)
        .order('created_at', ascending: false)
        .limit(30)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // ── POSITIONS TEMPS RÉEL POUR LA CARTE ───────────────────
static Future<List<Map<String, dynamic>>> getLatestPositions() async {
  try {
    final data = await _client
        .from('positions')
        .select('*, collectrices(nom, prenom, zone)')
        .order('recorded_at', ascending: false)
        .limit(50);

    // Garder seulement la position la plus récente par collectrice
    final Map<String, Map<String, dynamic>> latest = {};
    for (final p in data) {
      final id = p['collectrice_id'] as String?;
      if (id != null && !latest.containsKey(id)) {
        latest[id] = p;
      }
    }
    return latest.values.toList();
  } catch (e) {
    print('Erreur positions: $e');
    return [];
  }
  }

  static Future<String> inscrireCollectrice({
  required String nom,
  required String prenom,
  required String telephone,
  required String zone,
}) async {
  try {
    final existing = await _client
        .from('collectrices')
        .select('id')
        .eq('telephone', telephone)
        .maybeSingle();
    if (existing != null) return 'existe';
    await _client.from('collectrices').insert({
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'zone': zone,
      'actif': false,
      'statut': 'en_attente',
    });
    return 'ok';
  } catch (e) {
    return 'erreur';
  }
}

static Future<String> verifierStatut(String telephone) async {
  try {
    final data = await _client
        .from('collectrices')
        .select('statut')
        .eq('telephone', telephone.trim())
        .maybeSingle();
    return data?['statut'] ?? 'inconnu';
  } catch (e) {
    return 'inconnu';
  }
}

static Future<List<Map<String, dynamic>>> getDemandesEnAttente() async {
  try {
    final data = await _client
        .from('collectrices')
        .select()
        .eq('statut', 'en_attente')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    return [];
  }
}

static Future<void> validerCollectrice(String id) async {
  await _client.from('collectrices')
      .update({'statut': 'validee', 'actif': true}).eq('id', id);
}

static Future<void> rejeterCollectrice(String id) async {
  await _client.from('collectrices')
      .update({'statut': 'rejetee', 'actif': false}).eq('id', id);
}
} 