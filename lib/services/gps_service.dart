// lib/services/gps_service.dart
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'database_service.dart';

class GpsService {
  static Timer? _trackingTimer;
  static Position? _lastPosition;
  static String? _currentCollectriceId;

  // Rayon geofencing en mètres
  static const double geofenceRadius = 50.0;

  // Seuil de mouvement (en mètres) pour considérer un déplacement
  static const double _moveThreshold = 10.0;

  // Cache des zones clients
  static final Map<String, Map<String, double>> _clientZones = {};

  // ── PERMISSIONS ─────────────────────────────────────────
  static Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ── POSITION ACTUELLE ────────────────────────────────────
  static Future<Position?> getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastPosition = pos;
      return pos;
    } catch (_) {
      return _lastPosition;
    }
  }

  // ── TRACKING ACTIF (toutes les 30 secondes) ─────────────
  static void startPassiveTracking(String collectriceId) {
    _currentCollectriceId = collectriceId;
    _trackingTimer?.cancel();

    // Enregistrer position immédiatement au démarrage
    _recordPosition(collectriceId, type: 'connexion');

    // Puis toutes les 30 secondes
    _trackingTimer =
        Timer.periodic(const Duration(seconds: 30), (_) async {
      await _recordPosition(collectriceId, type: 'deplacement');
    });
  }

  static void stopTracking() {
    if (_currentCollectriceId != null) {
      _recordPosition(_currentCollectriceId!, type: 'deconnexion');
    }
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _currentCollectriceId = null;
  }

  // ── ENREGISTRER UNE COLLECTE (point d'arrêt) ────────────
  static Future<void> recordCollecte(String collectriceId) async {
    await _recordPosition(collectriceId, type: 'collecte');
  }

  // ── LOGIQUE INTERNE D'ENREGISTREMENT ────────────────────
  static Future<void> _recordPosition(
    String collectriceId, {
    required String type,
  }) async {
    final pos = await getCurrentPosition();
    if (pos == null) return;

    // Calculer vitesse et distance depuis dernière position
    double vitesse = 0;
    bool hasSignificantMove = true;

    if (_lastPosition != null && type == 'deplacement') {
      final distance = _haversineDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );

      // Si déplacement inférieur au seuil → pas besoin d'enregistrer
      if (distance < _moveThreshold) {
        hasSignificantMove = false;
      }

      // Vitesse en km/h (distance en m / temps en s * 3.6)
      final timeDiff = pos.timestamp
              .difference(_lastPosition!.timestamp)
              .inSeconds
              .toDouble();
      if (timeDiff > 0) {
        vitesse = (distance / timeDiff) * 3.6;
      }
    }

    // Pour les types spéciaux, toujours enregistrer
    if (type != 'deplacement') hasSignificantMove = true;

    if (!hasSignificantMove) return;

    _lastPosition = pos;

    final point = GpsPoint(
      collectriceId: collectriceId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      recordedAt: DateTime.now(),
    );

    // Sauvegarde locale
    await DatabaseService.insertGpsPoint(point);

    // Sync Supabase
    try {
      await Supabase.instance.client.from('positions').insert({
        'collectrice_id': collectriceId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'type': type,
        'vitesse': vitesse,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Offline — déjà sauvegardé localement
    }
  }

  // ── HISTORIQUE TRAJET PAR JOUR ───────────────────────────
  static Future<List<Map<String, dynamic>>> getTrajetDuJour(
    String collectriceId, {
    DateTime? date,
  }) async {
    final jour = date ?? DateTime.now();
    final debut =
        DateTime(jour.year, jour.month, jour.day).toIso8601String();
    final fin = DateTime(jour.year, jour.month, jour.day, 23, 59, 59)
        .toIso8601String();

    try {
      final data = await Supabase.instance.client
          .from('positions')
          .select()
          .eq('collectrice_id', collectriceId)
          .gte('recorded_at', debut)
          .lte('recorded_at', fin)
          .order('recorded_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  // ── TOUTES LES POSITIONS DU JOUR (toutes collectrices) ──
  static Future<List<Map<String, dynamic>>> getAllTrajetsAujourdhui() async {
    final today = DateTime.now();
    final debut =
        DateTime(today.year, today.month, today.day).toIso8601String();

    try {
      final data = await Supabase.instance.client
          .from('positions')
          .select('*, collectrices(nom, prenom, zone)')
          .gte('recorded_at', debut)
          .order('recorded_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  // ── GEOFENCING ──────────────────────────────────────────
  static Future<void> learnClientZone(
      String qrCode, double lat, double lng) async {
    _clientZones[qrCode] = {'lat': lat, 'lng': lng};
    try {
      await Supabase.instance.client.from('client_zones').upsert({
        'qr_code': qrCode,
        'latitude': lat,
        'longitude': lng,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<GeofenceResult> validateLocation(
      String qrCode, Position currentPos) async {
    if (!_clientZones.containsKey(qrCode)) {
      try {
        final data = await Supabase.instance.client
            .from('client_zones')
            .select()
            .eq('qr_code', qrCode)
            .maybeSingle();
        if (data != null) {
          _clientZones[qrCode] = {
            'lat': (data['latitude'] as num).toDouble(),
            'lng': (data['longitude'] as num).toDouble(),
          };
        }
      } catch (_) {}
    }

    final zone = _clientZones[qrCode];
    if (zone == null) return GeofenceResult.learning;

    final distance = _haversineDistance(
      zone['lat']!,
      zone['lng']!,
      currentPos.latitude,
      currentPos.longitude,
    );

    return distance <= geofenceRadius
        ? GeofenceResult.inside
        : GeofenceResult.outside;
  }

  // ── HAVERSINE ────────────────────────────────────────────
  static double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lng2 - lng1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // ── DISTANCE TOTALE PARCOURUE ────────────────────────────
  static double calculerDistanceTotale(
      List<Map<String, dynamic>> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _haversineDistance(
        (points[i]['latitude'] as num).toDouble(),
        (points[i]['longitude'] as num).toDouble(),
        (points[i + 1]['latitude'] as num).toDouble(),
        (points[i + 1]['longitude'] as num).toDouble(),
      );
    }
    return total / 1000; // En km
  }
}

enum GeofenceResult { inside, outside, learning }