-- ============================================================
-- FU-DICIA — Script SQL Supabase COMPLET
-- À exécuter dans : SQL Editor → New Query
-- ============================================================

-- Table des collectrices (déjà créée - skip si erreur)
CREATE TABLE IF NOT EXISTS collectrices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  telephone TEXT UNIQUE NOT NULL,
  zone TEXT NOT NULL,
  photo_url TEXT,
  actif BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des positions GPS
CREATE TABLE IF NOT EXISTS positions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  collectrice_id UUID REFERENCES collectrices(id),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des collectes
CREATE TABLE IF NOT EXISTS collectes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  collectrice_id UUID REFERENCES collectrices(id),
  client_nom TEXT NOT NULL,
  client_qr_code TEXT,
  montant_reel DECIMAL(10,2) NOT NULL,
  montant_attendu DECIMAL(10,2) DEFAULT 5000,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  photo_path TEXT,
  statut TEXT DEFAULT 'validee',
  collected_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des anomalies
CREATE TABLE IF NOT EXISTS anomalies (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  collecte_id UUID REFERENCES collectes(id),
  collectrice_id UUID REFERENCES collectrices(id),
  type_anomalie TEXT NOT NULL,
  severite TEXT NOT NULL,
  score INTEGER DEFAULT 0,
  description TEXT,
  resolu BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOUVELLE TABLE : zones géofencing clients
CREATE TABLE IF NOT EXISTS client_zones (
  qr_code TEXT PRIMARY KEY,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  rayon_metres INTEGER DEFAULT 50,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Désactiver RLS pour la démo
ALTER TABLE collectrices DISABLE ROW LEVEL SECURITY;
ALTER TABLE positions DISABLE ROW LEVEL SECURITY;
ALTER TABLE collectes DISABLE ROW LEVEL SECURITY;
ALTER TABLE anomalies DISABLE ROW LEVEL SECURITY;
ALTER TABLE client_zones DISABLE ROW LEVEL SECURITY;

-- Activer Realtime sur les tables importantes
-- (À faire manuellement dans Database → Replication)
-- ✅ positions
-- ✅ collectes
-- ✅ anomalies

-- Données de test (10 collectrices)
INSERT INTO collectrices (nom, prenom, telephone, zone) VALUES
('Agbeko', 'Afi', '+22890000001', 'Marché Adawlato'),
('Dosseh', 'Akua', '+22890000002', 'Marché Assigamé'),
('Koffi', 'Edem', '+22890000003', 'Marché Hédzranawoé'),
('Amega', 'Sena', '+22890000004', 'Marché Agoè'),
('Tsatsu', 'Mawuli', '+22890000005', 'Marché Bè'),
('Gbloto', 'Yawa', '+22890000006', 'Marché Adidogomé'),
('Abalo', 'Komi', '+22890000007', 'Marché Nyékonakpoè'),
('Avlessi', 'Ama', '+22890000008', 'Marché Tokoin'),
('Dossou', 'Kafui', '+22890000009', 'Marché Akossombo'),
('Fiagbe', 'Ablavi', '+22890000010', 'Marché Hanoukopé')
ON CONFLICT (telephone) DO NOTHING;

-- Données de démo : quelques collectes simulées
INSERT INTO collectes (collectrice_id, client_nom, montant_reel, latitude, longitude)
SELECT
  c.id,
  'Client Test ' || generate_series,
  (RANDOM() * 15000 + 2000)::DECIMAL(10,2),
  6.1375 + (RANDOM() * 0.02),
  1.2123 + (RANDOM() * 0.02)
FROM collectrices c
CROSS JOIN generate_series(1, 3)
WHERE c.telephone = '+22890000001'
ON CONFLICT DO NOTHING;

-- Vue résumé par collectrice (utile pour le dashboard)
CREATE OR REPLACE VIEW vue_stats_collectrices AS
SELECT
  c.id,
  c.prenom || ' ' || c.nom AS nom_complet,
  c.zone,
  COUNT(col.id) AS total_collectes,
  COALESCE(SUM(col.montant_reel), 0) AS total_montant,
  MAX(col.collected_at) AS derniere_collecte
FROM collectrices c
LEFT JOIN collectes col ON col.collectrice_id = c.id
  AND col.collected_at >= CURRENT_DATE
GROUP BY c.id, c.prenom, c.nom, c.zone;
