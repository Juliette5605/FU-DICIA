// lib/screens/superviseur/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../config/locale_manager.dart';
import '../../services/supabase_service.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  final LocaleManager localeManager;
  const SupervisorDashboardScreen({super.key, required this.localeManager});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState
    extends State<SupervisorDashboardScreen> with TickerProviderStateMixin {
  int _tab = 0;
  Map<String, dynamic> _stats = {
    'total_collectes': 0,
    'total_montant': 0.0,
    'anomalies_actives': 0,
    'agents_actifs': 0,
  };
  List<Map<String, dynamic>> _collectes = [];
  List<Map<String, dynamic>> _anomalies = [];
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _loading = true;
  Timer? _refreshTimer;

  static const _lomeCenter = LatLng(6.1375, 1.2123);

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final stats = await SupabaseService.getDashboardStats();
    final collectes = await SupabaseService.getCollectesAll();
    final positions = await SupabaseService.getLatestPositions();
    final demandes = await SupabaseService.getDemandesEnAttente();
    if (mounted) {
      setState(() {
        _stats = stats;
        _collectes = collectes;
        _positions = positions;
        _demandes = demandes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        leading:
            const Icon(Icons.dashboard_rounded, color: Color(0xFF7C4DFF)),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CENTRE DE CONTRÔLE',
                style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: Color(0xFF7C4DFF))),
            Text('FU-DICIA Superviseur',
                style: TextStyle(fontSize: 11, color: Colors.white38)),
          ],
        ),
        actions: [
          // Badge demandes en attente
          if (_demandes.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add_rounded,
                      color: Color(0xFFFF9100)),
                  onPressed: () => setState(() => _tab = 4),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B3B),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_demandes.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00E676).withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF00E676), size: 7),
                SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : _tab == 0
              ? _buildDashboard()
              : _tab == 1
                  ? _buildCarte()
                  : _tab == 2
                      ? _buildAlertes()
                      : _tab == 3
                          ? _buildTransactions()
                          : _buildDemandes(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── DASHBOARD ─────────────────────────────────────────────
  Widget _buildDashboard() {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                .format(DateTime.now())
                .toUpperCase(),
            style: const TextStyle(
                color: Colors.white38, fontSize: 11, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _SuperKpi(
                label: 'COLLECTES',
                value: '${_stats['total_collectes']}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF1BD6FF),
                trend: '+12% vs hier',
              ),
              _SuperKpi(
                label: 'MONTANT TOTAL',
                value:
                    '${formatter.format(_stats['total_montant'])} F',
                icon: Icons.payments_rounded,
                color: const Color(0xFF00E676),
                trend: 'Objectif 500K F',
              ),
              _SuperKpi(
                label: 'ANOMALIES',
                value: '${_stats['anomalies_actives']}',
                icon: Icons.warning_rounded,
                color: const Color(0xFFFF3B3B),
                trend: 'En attente',
              ),
              _SuperKpi(
                label: 'AGENTS ACTIFS',
                value: '${_stats['agents_actifs']}',
                icon: Icons.people_rounded,
                color: const Color(0xFF7C4DFF),
                trend: 'Sur le terrain',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCollectesChart(),

          // Bannière demandes en attente
          if (_demandes.isNotEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _tab = 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9100).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFF9100).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_rounded,
                        color: Color(0xFFFF9100), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_demandes.length} demande(s) en attente',
                            style: const TextStyle(
                                color: Color(0xFFFF9100),
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          const Text(
                            'Appuyez pour valider les inscriptions',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFFF9100), size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectesChart() {
    final hourlyData = List.generate(
      12,
      (i) => FlSpot(
        i.toDouble(),
        (5000 + (i * 3000 + DateTime.now().second * 10) % 20000)
            .toDouble(),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COLLECTES PAR HEURE',
              style: TextStyle(
                  color: Colors.white38, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFF1A2332), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        '${(v.toInt() + 7)}h',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                      reservedSize: 20,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyData,
                    isCurved: true,
                    color: const Color(0xFF7C4DFF),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF7C4DFF).withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CARTE GPS ─────────────────────────────────────────────
  Widget _buildCarte() {
    final colors = [
      const Color(0xFF1BD6FF),
      const Color(0xFF00E676),
      const Color(0xFFFF9100),
      const Color(0xFFFF3B3B),
      const Color(0xFF7C4DFF),
      const Color(0xFFFFEB3B),
    ];
    final markers = <Marker>[];
    for (int i = 0; i < _positions.length; i++) {
      final p = _positions[i];
      final lat = (p['latitude'] as num?)?.toDouble();
      final lng = (p['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final color = colors[i % colors.length];
      final nom = p['collectrices'] != null
          ? '${p['collectrices']['prenom']} ${p['collectrices']['nom']}'
          : 'Collectrice';
      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showAgentInfo(context, p, color),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.person_pin_rounded,
                    color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(nom.split(' ').first,
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ));
    }
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF0D1117),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFF1BD6FF), size: 18),
              const SizedBox(width: 8),
              Text('${markers.length} agent(s) localisé(s)',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: const Row(children: [
                  Icon(Icons.refresh_rounded,
                      color: Color(0xFF1BD6FF), size: 16),
                  SizedBox(width: 4),
                  Text('Actualiser',
                      style: TextStyle(
                          color: Color(0xFF1BD6FF), fontSize: 12)),
                ]),
              ),
            ],
          ),
        ),
        Expanded(
          child: markers.isEmpty
              ? _buildCarteVide()
              : FlutterMap(
                  options: MapOptions(
                      initialCenter: _lomeCenter,
                      initialZoom: 13,
                      maxZoom: 18,
                      minZoom: 5),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fudicia.app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
        ),
        if (_positions.isNotEmpty)
          Container(
            height: 90,
            color: const Color(0xFF0A1628),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              itemCount: _positions.length,
              itemBuilder: (_, i) {
                final p = _positions[i];
                final color = colors[i % colors.length];
                final nom = p['collectrices'] != null
                    ? '${p['collectrices']['prenom']} ${p['collectrices']['nom']}'
                    : 'Collectrice';
                final zone = p['collectrices']?['zone'] ?? '';
                final time = p['recorded_at'] != null
                    ? DateFormat('HH:mm').format(
                        DateTime.parse(p['recorded_at']).toLocal())
                    : '--:--';
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        Icon(Icons.circle, color: color, size: 8),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(nom,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(zone,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                      Text('Vu à $time',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCarteVide() {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
              initialCenter: _lomeCenter, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fudicia.app',
            ),
          ],
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_rounded,
                    color: Colors.white38, size: 40),
                SizedBox(height: 12),
                Text('Aucune collectrice\nlocalisée pour l\'instant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white54, fontSize: 14)),
                SizedBox(height: 8),
                Text(
                    'Les positions apparaissent\ndès qu\'une collectrice se connecte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAgentInfo(
      BuildContext context, Map<String, dynamic> p, Color color) {
    final nom = p['collectrices'] != null
        ? '${p['collectrices']['prenom']} ${p['collectrices']['nom']}'
        : 'Collectrice';
    final zone = p['collectrices']?['zone'] ?? 'Zone inconnue';
    final lat =
        (p['latitude'] as num?)?.toStringAsFixed(5) ?? '--';
    final lng =
        (p['longitude'] as num?)?.toStringAsFixed(5) ?? '--';
    final time = p['recorded_at'] != null
        ? DateFormat('HH:mm dd/MM')
            .format(DateTime.parse(p['recorded_at']).toLocal())
        : '--';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(nom,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(zone,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                    label: 'Latitude', value: lat, color: color),
                _InfoChip(
                    label: 'Longitude', value: lng, color: color),
                _InfoChip(label: 'Vu à', value: time, color: color),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── ALERTES ───────────────────────────────────────────────
  Widget _buildAlertes() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.watchAnomalies(),
      builder: (_, snapshot) {
        final anomalies = snapshot.data ?? _anomalies;
        if (anomalies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF00E676), size: 60),
                const SizedBox(height: 16),
                Text('Aucune anomalie active',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: anomalies.length,
          itemBuilder: (_, i) =>
              _AnomalieCard(anomalie: anomalies[i]),
        );
      },
    );
  }

  // ── TRANSACTIONS ──────────────────────────────────────────
  Widget _buildTransactions() {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _collectes.length,
      itemBuilder: (_, i) {
        final c = _collectes[i];
        final montant =
            (c['montant_reel'] as num?)?.toDouble() ?? 0;
        final ok = montant >= 3000;
        final collectrice = c['collectrices'];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ok
                  ? const Color(0xFF00E676).withOpacity(0.2)
                  : const Color(0xFFFF3B3B).withOpacity(0.2),
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
                      ? const Color(0xFF00E676).withOpacity(0.1)
                      : const Color(0xFFFF3B3B).withOpacity(0.1),
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
                    Text(c['client_nom'] ?? 'Client',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text(
                      collectrice != null
                          ? '${collectrice['prenom']} ${collectrice['nom']} • ${collectrice['zone']}'
                          : 'Collectrice inconnue',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${formatter.format(montant)} F',
                style: TextStyle(
                    color: ok
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF3B3B),
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── DEMANDES ──────────────────────────────────────────────
  Widget _buildDemandes() {
    if (_demandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF00E676), size: 60),
            const SizedBox(height: 16),
            Text(
              'Aucune demande en attente',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouvelles inscriptions apparaîtront ici',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _demandes.length,
      itemBuilder: (_, i) {
        final d = _demandes[i];
        final nom = '${d['prenom'] ?? ''} ${d['nom'] ?? ''}';
        final tel = d['telephone'] ?? '';
        final zone = d['zone'] ?? '';
        final date = d['created_at'] != null
            ? DateFormat('dd/MM/yyyy HH:mm')
                .format(DateTime.parse(d['created_at']).toLocal())
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFFF9100).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF9100).withOpacity(0.15),
                      border: Border.all(
                          color:
                              const Color(0xFFFF9100).withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFFFF9100), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nom,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(tel,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9100).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('EN ATTENTE',
                        style: TextStyle(
                            color: Color(0xFFFF9100),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Infos zone + date
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(zone,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.access_time_rounded,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(date,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),

              const SizedBox(height: 14),

              // Boutons Valider / Rejeter
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _valider(d['id'], nom),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('VALIDER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejeter(d['id'], nom),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('REJETER'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF3B3B),
                        side: const BorderSide(
                            color: Color(0xFFFF3B3B), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _valider(String id, String nom) async {
    await SupabaseService.validerCollectrice(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nom validée avec succès !'),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  Future<void> _rejeter(String id, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Rejeter la demande',
            style: TextStyle(color: Colors.white)),
        content: Text('Rejeter l\'inscription de $nom ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B)),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.rejeterCollectrice(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nom rejetée.'),
            backgroundColor: const Color(0xFFFF3B3B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    }
  }

  // ── BOTTOM NAV ────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1628),
        border: Border(
            top: BorderSide(color: Color(0xFF7C4DFF), width: 0.3)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF7C4DFF).withOpacity(0.2),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded,
                  color: Color(0xFF7C4DFF)),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon:
                  Icon(Icons.map_rounded, color: Color(0xFF1BD6FF)),
              label: 'Carte',
            ),
            const NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_rounded,
                  color: Color(0xFFFF3B3B)),
              label: 'Alertes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded,
                  color: Color(0xFF7C4DFF)),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _demandes.isNotEmpty,
                label: Text('${_demandes.length}'),
                child: const Icon(Icons.person_add_outlined),
              ),
              selectedIcon: const Icon(Icons.person_add_rounded,
                  color: Color(0xFFFF9100)),
              label: 'Demandes',
            ),
          ],
        ),
      ),
    );
  }
}

// ── WIDGETS RÉUTILISABLES ─────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SuperKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _SuperKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      letterSpacing: 1)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          Text(trend,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AnomalieCard extends StatelessWidget {
  final Map<String, dynamic> anomalie;
  const _AnomalieCard({required this.anomalie});

  @override
  Widget build(BuildContext context) {
    final severite = anomalie['severite'] ?? 'moyen';
    final color = severite == 'critique'
        ? const Color(0xFFFF3B3B)
        : severite == 'eleve'
            ? const Color(0xFFFF9100)
            : const Color(0xFFFFEB3B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.5), blurRadius: 8)
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    anomalie['description'] ??
                        anomalie['type_anomalie'] ??
                        '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
                Text(severite.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${anomalie['score'] ?? 0}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}