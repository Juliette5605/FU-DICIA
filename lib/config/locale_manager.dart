// lib/config/locale_manager.dart
import 'package:flutter/material.dart';

// ─── LANGUES SUPPORTÉES ───────────────────────────────────────
enum AppLanguage { francais, ewe, kabiye }

class LocaleManager extends ChangeNotifier {
  AppLanguage _current = AppLanguage.francais;

  AppLanguage get current => _current;

  String get languageCode {
    switch (_current) {
      case AppLanguage.francais:
        return 'fr';
      case AppLanguage.ewe:
        return 'ee';
      case AppLanguage.kabiye:
        return 'kbp';
    }
  }

  String get languageLabel {
    return getLanguageLabel(_current);
  }

  // Méthode statique pour obtenir le libellé d'une langue spécifique
  static String getLanguageLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.francais:
        return '🇫🇷 Français';
      case AppLanguage.ewe:
        return '🇹🇬 Éwé';
      case AppLanguage.kabiye:
        return '🇹🇬 Kabiyè';
    }
  }

  Future<void> init() async {
    // Langue par défaut : Français
    _current = AppLanguage.francais;
  }

  void setLanguage(AppLanguage lang) {
    _current = lang;
    notifyListeners();
  }

  // ── TRADUCTIONS ──────────────────────────────────────────────
  // Suppression de l'underscore pour rendre 'translations' accessible à l'extérieur
  AppTranslations get t => translations[_current]!;

  static final Map<AppLanguage, AppTranslations> translations = {
    AppLanguage.francais: AppTranslations(
      // App
      appName: 'FU-DICIA',
      appTagline: 'Système de Collecte Sécurisée',

      // Rôles
      chooseProfile: 'Choisissez votre profil',
      collectrice: 'COLLECTRICE',
      collectriceSubtitle: 'Accès terrain — Scan QR & Collecte',
      superviseur: 'SUPERVISEUR',
      superviseurSubtitle: 'Centre de contrôle — Suivi en temps réel',

      // Login collectrice
      collectriceSpace: 'ESPACE COLLECTRICE',
      loginSubtitle: 'Connectez-vous avec votre numéro de téléphone',
      phonePlaceholder: 'Numéro de téléphone',
      phoneHint: '+228 XX XX XX XX',
      accessTerrain: 'ACCÉDER AU TERRAIN',
      unknownNumber: 'Numéro non reconnu. Contactez votre superviseur.',
      testMode: '🧪 Mode Test',

      // Dashboard collectrice
      hello: 'Bonjour',
      online: 'EN LIGNE',
      offline: 'HORS LIGNE',
      dailyObjective: 'OBJECTIF JOURNALIER',
      objectiveReached: 'Objectif atteint ! Excellent travail 🎉',
      collectes: 'COLLECTES',
      montant: 'MONTANT',
      objectif: 'OBJECTIF',
      zone: 'ZONE',
      newCollecte: 'NOUVELLE COLLECTE',
      scanCarnet: 'Scanner le carnet client',
      gpsTracking: 'Tracking GPS',
      gpsActive: 'Actif — toutes les 5 min',

      // Navigation
      navHome: 'Accueil',
      navScan: 'Scanner',
      navHistory: 'Historique',

      // Scan flow
      scanCarnetTitle: 'SCANNER LE CARNET',
      scanStep: 'SCAN',
      confirmClient: 'CONFIRMATION CLIENT',
      clientName: 'Nom du client',
      confirmContinue: 'CONFIRMER ET CONTINUER',
      photoProof: 'PREUVE PHOTO',
      photoMandatory: 'Photo OBLIGATOIRE',
      photoMandatoryDesc: 'Les 3 premiers scans nécessitent une photo de preuve',
      photoRequired: 'Photo requise',
      photoRequiredDesc: 'Une vérification photo est demandée pour ce scan',
      takePhoto: 'PRENDRE LA PHOTO',
      skip: 'Passer',
      amountCollected: 'MONTANT COLLECTÉ',
      amountHint: 'Montant (FCFA)',
      validateAmount: 'VALIDER LE MONTANT',
      clientSignature: 'SIGNATURE CLIENT',
      signatureDesc: 'Le client signe pour confirmer la collecte',
      clearSignature: 'Effacer',
      finalizeCollecte: 'FINALISER LA COLLECTE',
      collecteValidated: 'COLLECTE VALIDÉE !',
      nextScan: 'SCAN SUIVANT',
      alreadyScanned: '⚠️ Ce client a déjà été scanné aujourd\'hui !',
      fillAllFields: 'Remplis tous les champs',
      validAmount: 'Entrez un montant valide',
      signatureRequired: 'La signature est requise',
      testSimulate: 'Mode Test — Simuler un scan',
      syncing: 'Synchronisation...',

      // Historique
      historyTitle: 'HISTORIQUE DU JOUR',
      noCollecteToday: 'Aucune collecte aujourd\'hui',

      // SOS
      sosTitle: 'ALERTE SOS',
      sosDanger: 'EN CAS DE DANGER',
      sosDesc: 'Appuyez pour envoyer une alerte SMS avec votre position GPS à votre superviseur',
      sosSend: '🆘 ENVOYER ALERTE SOS',
      sosSent: 'ALERTE ENVOYÉE !',
      sosSentDesc: 'Votre superviseur a été alerté avec votre position GPS',
      back: 'RETOUR',

      // Superviseur
      controlCenter: 'CENTRE DE CONTRÔLE',
      supervisorLogin: 'Accès superviseur sécurisé',
      accessCode: 'Code d\'accès',
      accessDashboard: 'ACCÉDER AU DASHBOARD',
      wrongCode: 'Code incorrect',
      demoCode: 'Code démo: 1234',
      live: 'LIVE',
      collectesPerHour: 'COLLECTES PAR HEURE',
      activeAnomalies: 'ANOMALIES ACTIVES',
      noAnomaly: 'Aucune anomalie active',
      navDashboard: 'Dashboard',
      navAlertes: 'Alertes',
      navTransactions: 'Transactions',
      unknownCollectrice: 'Collectrice inconnue',
    ),

    // ── ÉWÉ ──────────────────────────────────────────────────
    AppLanguage.ewe: AppTranslations(
      appName: 'FU-DICIA',
      appTagline: 'Mɔ̃fia Dɔwɔnu Si Le Ŋutilame',

      chooseProfile: 'Tia wò dɔ ŋu',
      collectrice: 'MƆFIALA',
      collectriceSubtitle: 'Afime dɔwɔ — QR kpɔ & Mɔ̃fia',
      superviseur: 'ƑOƑO',
      superviseurSubtitle: 'Ŋkume ƒe xɔ — Kpɔ be ne yɔna',

      collectriceSpace: 'MƆFIALA ƑE XƆ',
      loginSubtitle: 'Zã wò telefon nɔme aɖe wò ŋu',
      phonePlaceholder: 'Telefon nɔme',
      phoneHint: '+228 XX XX XX XX',
      accessTerrain: 'DZO AFI ME',
      unknownNumber: 'Nɔme maɖo o. Zã wò ƒoƒo.',
      testMode: '🧪 Lãtse Nu',

      hello: 'Ŋdi na',
      online: 'LE MƆRPƆ',
      offline: 'ÁLE MƆRPƆ O',
      dailyObjective: 'EDZɔ ƑE NUƑƒO',
      objectiveReached: 'Nuƒƒo wòe wɔ! Dɔ nyuie wɔm 🎉',
      collectes: 'MƆ̃FIA',
      montant: 'ŊKEKE',
      objectif: 'NUƑƒO',
      zone: 'XƆ',
      newCollecte: 'MƆ̃FIA YEYE',
      scanCarnet: 'Kpɔ apamegã ŋu',
      gpsTracking: 'GPS Kpɔkpɔ',
      gpsActive: 'Le dɔm — ŋɔli 5 me',

      navHome: 'Ƒe',
      navScan: 'Kpɔ',
      navHistory: 'Edzi',

      scanCarnetTitle: 'KPƆ APAMEGÃ',
      scanStep: 'KPƆ',
      confirmClient: 'ƑOƑO AƉE ŊU',
      clientName: 'Ƒoƒo ŋkɔ',
      confirmContinue: 'ƑO ŊU ƁE NÁ BƆ DO EDZI',
      photoProof: 'FOTO NUƑOƑO',
      photoMandatory: 'Foto DZETONA',
      photoMandatoryDesc: 'Kpɔ akpa etɔ̃ gbã ƒe photo hia',
      photoRequired: 'Foto Hia',
      photoRequiredDesc: 'Foto aɖe hia kpɔ sia ƒe ŋu',
      takePhoto: 'DU FOTO',
      skip: 'Ɖo ewui',
      amountCollected: 'MƆ̃FIA ŊKEKE',
      amountHint: 'Ŋkeke (FCFA)',
      validateAmount: 'ƑO ŊKEKE ŊU',
      clientSignature: 'ƑOƑO ƑE ŊƆŊLƆ',
      signatureDesc: 'Ƒoƒo ŋlɔ ŋkɔ be aɖe mɔ̃fia ŋu',
      clearSignature: 'Ɖu',
      finalizeCollecte: 'WƆWƆ MƆ̃FIA ƉOƉO',
      collecteValidated: 'MƆ̃FIA WƆM!',
      nextScan: 'KPƆ AƉE',
      alreadyScanned: '⚠️ Ƒoƒo sia wòkpɔe egɔme fifia!',
      fillAllFields: 'Ŋlɔ nu keke o',
      validAmount: 'Ŋlɔ ŋkeke nyuie',
      signatureRequired: 'Ŋɔŋlɔ hia',
      testSimulate: 'Lãtse — Wɔ kpɔkpɔ yeye',
      syncing: 'Le dzam...',

      historyTitle: 'EGƆME MƆ̃FIA',
      noCollecteToday: 'Mɔ̃fia mele fifia o',

      sosTitle: 'SOS ŊƆ',
      sosDanger: 'NÚVEVE LE',
      sosDesc: 'Tia be wòna SMS le wò GPS ƒe xɔxɔ dzi yia wò ƒoƒo',
      sosSend: '🆘 XƆSE SOS ŊƆ',
      sosSent: 'ŊƆ XƆM!',
      sosSentDesc: 'Wò ƒoƒo ƒe kɔ le wò GPS ƒe xɔ dzi',
      back: 'DO MEGBE',

      controlCenter: 'ŊKUME ƑE XƆ',
      supervisorLogin: 'Ƒoƒo ƒe xɔxɔ',
      accessCode: 'Xɔxɔ nɔme',
      accessDashboard: 'XƆ DASHBOARD',
      wrongCode: 'Nɔme nyí o',
      demoCode: 'Lãtse nɔme: 1234',
      live: 'FIFIA',
      collectesPerHour: 'MƆ̃FIA ÃHA ŊU',
      activeAnomalies: 'NUƑOƑO NYONYOME',
      noAnomaly: 'Nuƒoƒo mele o',
      navDashboard: 'Dashboard',
      navAlertes: 'Ŋɔŋlɔ',
      navTransactions: 'Mɔ̃fia',
      unknownCollectrice: 'Mɔfiala maɖo o',
    ),

    // ── KABIYÈ ───────────────────────────────────────────────
    AppLanguage.kabiye: AppTranslations(
      appName: 'FU-DICIA',
      appTagline: 'Kɔlɔɣa Tɔnʊ Sɩ Ɩkpɛlɩɣ',

      chooseProfile: 'Tɛ n tɔm ŋmʊ',
      collectrice: 'KƆLƆƔA TƱ',
      collectriceSubtitle: 'Tɛtʊ kɔlɔɣa — QR tʊ & Kɔlɔɣa',
      superviseur: 'ÑƱSƖ TƲ',
      superviseurSubtitle: 'Hɔʊ tɔm — Nɩɣ pɩ lɛ',

      collectriceSpace: 'KƆLƆƔA TƲ ƑE XƆ',
      loginSubtitle: 'Sɩzɩ n telefono nɔmɛɛ ŋmʊ',
      phonePlaceholder: 'Telefono nɔmɛɛ',
      phoneHint: '+228 XX XX XX XX',
      accessTerrain: 'KƆ TƐ TƲ',
      unknownNumber: 'Nɔmɛɛ tɩ nɩɣ. Yɔ ñʊsɩ tʊ.',
      testMode: '🧪 Lɛlɛ Tɛ',

      hello: 'Laaɓal',
      online: 'LE REZO',
      offline: 'REZO ALAA',
      dailyObjective: 'CACA TƆM ÑƲ',
      objectiveReached: 'Tɔm ñʊ talaa! Tʊma ŋʊ! 🎉',
      collectes: 'KƆLƆƔA',
      montant: 'LIIDIYE',
      objectif: 'TƆM ÑƲ',
      zone: 'TEŊU',
      newCollecte: 'KƆLƆƔA KƖFAM',
      scanCarnet: 'Tɛ kɛɣ QR tʊ',
      gpsTracking: 'GPS Nɩɣnʊ',
      gpsActive: 'Pɩlakɩ — miniiti 5 taa',

      navHome: 'Ɖɩɣa',
      navScan: 'Tɛ',
      navHistory: 'Tɔzʊ',

      scanCarnetTitle: 'TƐ KƐƔCƐ',
      scanStep: 'TƐ',
      confirmClient: 'SƖNZƖ TƲ',
      clientName: 'Sɩnzɩ tʊ hɩɖɛ',
      confirmContinue: 'SƖNZƖ NƐ KƆ PƖSƖ',
      photoProof: 'FOTO KAƔLƱ',
      photoMandatory: 'Foto WAƉƖ',
      photoMandatoryDesc: 'Tɛ natozo pɩdɩɩnɩ foto kaɣlʊ',
      photoRequired: 'Foto Waɖɩ',
      photoRequiredDesc: 'Foto kaɣlʊ kɩlɩɣ tɛ taa',
      takePhoto: 'DU FOTO',
      skip: 'Ɖɛɛ',
      amountCollected: 'KƆLƆƔA LIIDIYE',
      amountHint: 'Liidiye (FCFA)',
      validateAmount: 'SƖNZƖ LIIDIYE',
      clientSignature: 'SƖNZƖ TƲ ÑƖŊ',
      signatureDesc: 'Sɩnzɩ tʊ ñɩŋ kɔlɔɣa sɩnzɩ',
      clearSignature: 'Pɛɛ',
      finalizeCollecte: 'LƖZƖ KƆLƆƔA',
      collecteValidated: 'KƆLƆƔA TALAA!',
      nextScan: 'TƐ LƐƐLƐƐ',
      alreadyScanned: '⚠️ Sɩnzɩ tʊ tɛ-ɩ kɔnɩ caca!',
      fillAllFields: 'Yɔɔdɩ tɔm kpeekpe',
      validAmount: 'Yɔɔdɩ liidiye ŋʊ',
      signatureRequired: 'Ñɩŋ waɖɩ',
      testSimulate: 'Lɛlɛ tɛ — Tɛ kɩfam',
      syncing: 'Pɩlakɩ...',

      historyTitle: 'TƆZƱ KƆLƆƔA',
      noCollecteToday: 'Kɔlɔɣa alaa caca',

      sosTitle: 'SOS TAABALƖ',
      sosDanger: 'KAƉƐSAƔ LE',
      sosDesc: 'Tɛ SMS nɛ GPS teŋu cɔlɔ ñʊsɩ tʊ',
      sosSend: '🆘 TIYƖ SOS TAABALƖ',
      sosSent: 'TAABALƖ TƖƖ!',
      sosSentDesc: 'Ñʊsɩ tʊ nɩɩ GPS teŋu ŋmʊ',
      back: 'KƆƆ WIYE',

      controlCenter: 'HOʊ TƆM',
      supervisorLogin: 'Ñʊsɩ tʊ sɩzɩ',
      accessCode: 'Sɩzɩ nɔmɛɛ',
      accessDashboard: 'KƆ DASHBOARD',
      wrongCode: 'Nɔmɛɛ tɩtʊ o',
      demoCode: 'Lɛlɛ nɔmɛɛ: 1234',
      live: 'SƆNƆ',
      collectesPerHour: 'KƆLƆƔA AAŊ TAA',
      activeAnomalies: 'KAƔLƱ TƆM',
      noAnomaly: 'Kaɣlʊ tɔm alaa',
      navDashboard: 'Dashboard',
      navAlertes: 'Taabalɩ',
      navTransactions: 'Kɔlɔɣa',
      unknownCollectrice: 'Kɔlɔɣa tʊ tɩnɩɣ',
    ),
  };
}

// ─── MODÈLE DE TRADUCTIONS ────────────────────────────────────
class AppTranslations {
  final String appName;
  final String appTagline;
  final String chooseProfile;
  final String collectrice;
  final String collectriceSubtitle;
  final String superviseur;
  final String superviseurSubtitle;
  final String collectriceSpace;
  final String loginSubtitle;
  final String phonePlaceholder;
  final String phoneHint;
  final String accessTerrain;
  final String unknownNumber;
  final String testMode;
  final String hello;
  final String online;
  final String offline;
  final String dailyObjective;
  final String objectiveReached;
  final String collectes;
  final String montant;
  final String objectif;
  final String zone;
  final String newCollecte;
  final String scanCarnet;
  final String gpsTracking;
  final String gpsActive;
  final String navHome;
  final String navScan;
  final String navHistory;
  final String scanCarnetTitle;
  final String scanStep;
  final String confirmClient;
  final String clientName;
  final String confirmContinue;
  final String photoProof;
  final String photoMandatory;
  final String photoMandatoryDesc;
  final String photoRequired;
  final String photoRequiredDesc;
  final String takePhoto;
  final String skip;
  final String amountCollected;
  final String amountHint;
  final String validateAmount;
  final String clientSignature;
  final String signatureDesc;
  final String clearSignature;
  final String finalizeCollecte;
  final String collecteValidated;
  final String nextScan;
  final String alreadyScanned;
  final String fillAllFields;
  final String validAmount;
  final String signatureRequired;
  final String testSimulate;
  final String syncing;
  final String historyTitle;
  final String noCollecteToday;
  final String sosTitle;
  final String sosDanger;
  final String sosDesc;
  final String sosSend;
  final String sosSent;
  final String sosSentDesc;
  final String back;
  final String controlCenter;
  final String supervisorLogin;
  final String accessCode;
  final String accessDashboard;
  final String wrongCode;
  final String demoCode;
  final String live;
  final String collectesPerHour;
  final String activeAnomalies;
  final String noAnomaly;
  final String navDashboard;
  final String navAlertes;
  final String navTransactions;
  final String unknownCollectrice;

  const AppTranslations({
    required this.appName,
    required this.appTagline,
    required this.chooseProfile,
    required this.collectrice,
    required this.collectriceSubtitle,
    required this.superviseur,
    required this.superviseurSubtitle,
    required this.collectriceSpace,
    required this.loginSubtitle,
    required this.phonePlaceholder,
    required this.phoneHint,
    required this.accessTerrain,
    required this.unknownNumber,
    required this.testMode,
    required this.hello,
    required this.online,
    required this.offline,
    required this.dailyObjective,
    required this.objectiveReached,
    required this.collectes,
    required this.montant,
    required this.objectif,
    required this.zone,
    required this.newCollecte,
    required this.scanCarnet,
    required this.gpsTracking,
    required this.gpsActive,
    required this.navHome,
    required this.navScan,
    required this.navHistory,
    required this.scanCarnetTitle,
    required this.scanStep,
    required this.confirmClient,
    required this.clientName,
    required this.confirmContinue,
    required this.photoProof,
    required this.photoMandatory,
    required this.photoMandatoryDesc,
    required this.photoRequired,
    required this.photoRequiredDesc,
    required this.takePhoto,
    required this.skip,
    required this.amountCollected,
    required this.amountHint,
    required this.validateAmount,
    required this.clientSignature,
    required this.signatureDesc,
    required this.clearSignature,
    required this.finalizeCollecte,
    required this.collecteValidated,
    required this.nextScan,
    required this.alreadyScanned,
    required this.fillAllFields,
    required this.validAmount,
    required this.signatureRequired,
    required this.testSimulate,
    required this.syncing,
    required this.historyTitle,
    required this.noCollecteToday,
    required this.sosTitle,
    required this.sosDanger,
    required this.sosDesc,
    required this.sosSend,
    required this.sosSent,
    required this.sosSentDesc,
    required this.back,
    required this.controlCenter,
    required this.supervisorLogin,
    required this.accessCode,
    required this.accessDashboard,
    required this.wrongCode,
    required this.demoCode,
    required this.live,
    required this.collectesPerHour,
    required this.activeAnomalies,
    required this.noAnomaly,
    required this.navDashboard,
    required this.navAlertes,
    required this.navTransactions,
    required this.unknownCollectrice,
  });
}