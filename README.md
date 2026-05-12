# FU-DICIA — Application Mobile Flutter
## Système de Collecte Sécurisée | D-CLIC Hackathon 2026

---

##  STRUCTURE DU PROJET

```
fu_dicia/
├── lib/
│   ├── main.dart                          ← Point d'entrée
│   ├── config/
│   │   └── supabase_config.dart           ← Clés Supabase
│   ├── models/
│   │   └── models.dart                    ← Collectrice, Collecte, Anomalie, GpsPoint
│   ├── services/
│   │   ├── database_service.dart          ← SQLite offline-first
│   │   ├── gps_service.dart               ← GPS + Geofencing
│   │   └── supabase_service.dart          ← Sync cloud
│   └── screens/
│       ├── splash_screen.dart             ← Intro animée
│       ├── role_selector_screen.dart      ← Choix Collectrice / Superviseur
│       ├── collectrice/
│       │   ├── login_screen.dart          ← Login par téléphone
│       │   ├── home_screen.dart           ← Dashboard collectrice
│       │   ├── scan_flow_screen.dart      ← QR → GPS → Photo → Montant → Signature
│       │   ├── historique_screen.dart     ← Historique du jour
│       │   └── sos_screen.dart            ← Alerte SOS
│       └── superviseur/
│           ├── supervisor_login_screen.dart  ← Login code 1234
│           └── dashboard_screen.dart         ← Dashboard temps réel
```

---

##  INSTALLATION

### Étape 1 — Copier les fichiers
Remplace le dossier `lib/` et le fichier `pubspec.yaml` de ton projet existant.

### Étape 2 — Installer les dépendances
```bash
cd C:\Users\alokp\fu_dicia
flutter pub get
```

### Étape 3 — Supabase (si pas encore fait)
Va sur : https://supabase.com/dashboard/project/cxruflcdfsirnrkegdqp/sql
Exécute le fichier `supabase_setup.sql`

### Étape 4 — Lancer l'app
```bash
flutter run
```

---

##  FONCTIONNALITÉS COMPLÈTES

### CÔTÉ COLLECTRICE
| Fonctionnalité | Détail |
|---|---|
|  Login | Par numéro de téléphone |
|  Dashboard | Objectif journalier + KPIs en temps réel |
|  Scanner QR | Caméra + mode test simulé |
|  Anti-double scan | Détection si client déjà scanné aujourd'hui |
|  GPS | Tracking passif toutes les 5 min |
|  Geofencing | Apprentissage 3 premiers scans, contrôle rayon 50m |
|  Photo preuve | Obligatoire 3 premiers scans, aléatoire après |
|  Saisie montant | Montants rapides + validation |
|  Signature digitale | Le client signe sur l'écran |
|  Offline-first | SQLite local + sync auto Supabase |
|  Bouton SOS | SMS GPS au superviseur |
|  Historique | Collectes du jour + total |

### CÔTÉ SUPERVISEUR
| Fonctionnalité | Détail |
|---|---|
|  Login | Code PIN (1234 pour la démo) |
|  Dashboard | KPIs + graphique horaire temps réel |
|  Alertes | Anomalies en temps réel avec score de risque |
|  Transactions | Toutes les collectes + collectrice + zone |
|  Auto-refresh | Toutes les 10 secondes |

---

##  FLUX UTILISATEUR COMPLET

```
App → Splash (animation) → Choix rôle
                               │
              ┌────────────────┴────────────────┐
              ▼                                  ▼
        COLLECTRICE                         SUPERVISEUR
        Login téléphone                     Login code PIN
              │                                  │
        Dashboard                          Dashboard temps réel
        (objectif + KPIs)                  (KPIs + alertes)
              │
        [Bouton SCANNER]
              │
        Étape 1 : Scanner QR
              │
        Étape 2 : Confirmer client
              │
        Étape 3 : Photo (si requis)
              │
        Étape 4 : Saisir montant
              │
        Étape 5 : Signature client
              │
         Succès → Sauvegarde SQLite → Sync Supabase
```

---

##  TESTS RAPIDES

### Tester sans QR Code réel
Sur l'écran scanner → Cliquer **"Mode Test — Simuler un scan"** en bas

### Comptes de test
| Rôle | Identifiant |
|---|---|
| Collectrice | +22890000001 (Afi Agbeko, Marché Adawlato) |
| Collectrice | +22890000002 (Akua Dosseh, Marché Assigamé) |
| Superviseur | Code PIN : 1234 |

---

##  GÉNÉRER L'APK

```bash
# APK debug (pour tester)
flutter build apk --debug

# APK release (pour distribuer)
flutter build apk --release

# Chemin de l'APK généré :
# build/app/outputs/flutter-apk/app-release.apk
```

---

##  DÉPANNAGE

### Erreur "package not found"
```bash
flutter pub get
flutter clean
flutter pub get
```

### Erreur caméra sur émulateur
→ Utiliser le bouton "Mode Test" à la place

### Erreur GPS
→ L'app utilise une position simulée automatiquement si le GPS n'est pas disponible

### Erreur Supabase connexion
→ Vérifier la connexion internet
→ L'app fonctionne en mode offline et sync dès que le réseau revient

---

##  SUPABASE CONFIG

- **Project URL** : `https://cxruflcdfsirnrkegdqp.supabase.co`
- **Project ID** : `cxruflcdfsirnrkegdqp`
- **Tables** : collectrices, positions, collectes, anomalies, client_zones

---

*FU-DICIA © 2026 — D-CLIC Hackathon | OIF × CUBE × PROEDV-TOGO*
