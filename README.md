# FU-DICIA
### Système de Collecte Sécurisée — Application Mobile Android

> Lauréat du Hackathon **D-CLIC 2026** | OIF × CUBE × PROEDV-TOGO

---

## Présentation

FU-DICIA est une application mobile conçue pour les institutions de microfinance et tontines au Togo. Elle permet de **tracer, sécuriser et contrôler** les collectes d'argent effectuées par des agents sur le terrain, en éliminant les risques de fraude et de détournement.

**Problème résolu :** Les institutions envoient des agents collecter l'épargne de leurs clients sur les marchés. Sans outil de contrôle, il est impossible de vérifier que les agents font bien leur travail, que les montants collectés sont exacts, et que les clients sont bien visités.

**Solution FU-DICIA :** Chaque collecte est horodatée, géolocalisée, photographiée et signée digitalement par le client.

---

## Fonctionnalités

| Fonctionnalité | Description |
|---|---|
| Scan QR Code | Scanner le carnet de chaque client pour enregistrer la collecte |
| Anti-double scan | Un client ne peut pas être scanné deux fois dans la même journée |
| GPS + Géofencing | Vérification automatique que l'agent est bien à l'adresse du client |
| Preuve photo | Photo obligatoire sur les premiers scans, aléatoire ensuite |
| Signature digitale | Le client signe sur l'écran pour confirmer la collecte |
| Mode offline | Fonctionne sans connexion internet, synchronisation automatique |
| Alerte SOS | L'agent peut envoyer une alerte d'urgence avec sa position GPS |
| Multi-langue | Français, English, Éwé, Kabiyè |
| Dashboard web | Supervision en temps réel (transactions, agents actifs, alertes) |

---

## Technologies

- **Mobile** — Flutter (Dart) pour Android
- **Base de données cloud** — Supabase (PostgreSQL + Realtime)
- **Base de données locale** — SQLite (offline-first)
- **Authentification** — Supabase Auth (email + mot de passe)
- **Dashboard web** — Flutter Web + Riverpod

---

---

## Installation (développeurs)

```bash
# 1. Cloner le dépôt
git clone https://github.com/Juliette5605/FU-DICIA.git
cd FU-DICIA

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run

# 4. Générer l'APK
flutter build apk --release
```

**Prérequis :** Flutter 3.x, Android SDK, compte Supabase

---

## Structure du projet

```
lib/
├── main.dart                     ← Point d'entrée
├── config/                       ← Configuration (Supabase, langues)
├── models/                       ← Modèles de données
├── services/                     ← GPS, base de données, sync cloud
└── screens/
    ├── scanner/                  ← Flux de collecte (QR → Photo → Signature)
    ├── dashboard/                ← Tableau de bord agent
    ├── map/                      ← Carte GPS
    ├── historique/               ← Historique des collectes
    └── profile/                  ← Profil + SOS + Langue
```

---

## Déploiement

- **APK Android** disponible sur demande
- **Play Store** — en cours de déploiement
- **Dashboard web superviseur** — hébergé séparément

---

*FU-DICIA © 2026 — D-CLIC Hackathon | OIF × CUBE × PROEDV-TOGO*