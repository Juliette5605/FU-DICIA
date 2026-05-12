// lib/models/collectrice.dart
class Collectrice {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String zone;
  final bool actif;

  Collectrice({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.zone,
    required this.actif,
  });

  factory Collectrice.fromMap(Map<String, dynamic> map) {
    return Collectrice(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      zone: map['zone'] ?? '',
      actif: map['actif'] ?? true,
    );
  }

  String get fullName => '$prenom $nom';

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'zone': zone,
        'actif': actif,
      };
}

// lib/models/collecte.dart
class Collecte {
  final String? id;
  final String collectriceId;
  final String clientNom;
  final String? clientQrCode;
  final double montantReel;
  final double montantAttendu;
  final double? latitude;
  final double? longitude;
  final String? photoPath;
  final String statut;
  final DateTime collectedAt;
  final bool synced;

  Collecte({
    this.id,
    required this.collectriceId,
    required this.clientNom,
    this.clientQrCode,
    required this.montantReel,
    this.montantAttendu = 5000,
    this.latitude,
    this.longitude,
    this.photoPath,
    this.statut = 'validee',
    required this.collectedAt,
    this.synced = false,
  });

  factory Collecte.fromMap(Map<String, dynamic> map) {
    return Collecte(
      id: map['id'],
      collectriceId: map['collectrice_id'] ?? '',
      clientNom: map['client_nom'] ?? '',
      clientQrCode: map['client_qr_code'],
      montantReel: (map['montant_reel'] as num?)?.toDouble() ?? 0,
      montantAttendu: (map['montant_attendu'] as num?)?.toDouble() ?? 5000,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      photoPath: map['photo_path'],
      statut: map['statut'] ?? 'validee',
      collectedAt: map['collected_at'] != null
          ? DateTime.parse(map['collected_at'])
          : DateTime.now(),
      synced: map['synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'collectrice_id': collectriceId,
        'client_nom': clientNom,
        'client_qr_code': clientQrCode,
        'montant_reel': montantReel,
        'montant_attendu': montantAttendu,
        'latitude': latitude,
        'longitude': longitude,
        'photo_path': photoPath,
        'statut': statut,
        'collected_at': collectedAt.toIso8601String(),
      };
}

// lib/models/anomalie.dart
class Anomalie {
  final String? id;
  final String? collecteId;
  final String collectriceId;
  final String typeAnomalie;
  final String severite;
  final int score;
  final String description;
  final bool resolu;
  final DateTime createdAt;

  Anomalie({
    this.id,
    this.collecteId,
    required this.collectriceId,
    required this.typeAnomalie,
    required this.severite,
    required this.score,
    required this.description,
    this.resolu = false,
    required this.createdAt,
  });

  factory Anomalie.fromMap(Map<String, dynamic> map) {
    return Anomalie(
      id: map['id'],
      collecteId: map['collecte_id'],
      collectriceId: map['collectrice_id'] ?? '',
      typeAnomalie: map['type_anomalie'] ?? '',
      severite: map['severite'] ?? 'moyen',
      score: map['score'] ?? 0,
      description: map['description'] ?? '',
      resolu: map['resolu'] == true || map['resolu'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}

// lib/models/gps_point.dart
class GpsPoint {
  final String? id;
  final String collectriceId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final bool synced;

  GpsPoint({
    this.id,
    required this.collectriceId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
        'collectrice_id': collectriceId,
        'latitude': latitude,
        'longitude': longitude,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
