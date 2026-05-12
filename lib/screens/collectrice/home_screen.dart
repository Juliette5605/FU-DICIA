// lib/screens/collectrice/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/locale_manager.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/gps_service.dart';
import '../../services/supabase_service.dart';
import 'scan_flow_screen.dart';
import 'historique_screen.dart';
import 'sos_screen.dart';

class CollectriceHomeScreen extends StatefulWidget {
  final Collectrice collectrice;
  final LocaleManager localeManager;

  const CollectriceHomeScreen({
    super.key,
    required this.collectrice,
    required this.localeManager,
  });

  @override
  State<CollectriceHomeScreen> createState() =>
      _CollectriceHomeScreenState();
}

class _CollectriceHomeScreenState extends State<CollectriceHomeScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  int _totalCollectes = 0;
  double _totalMontant = 0;
  bool _isOnline = true;
  bool _syncing = false;

  static const double objectifJournalier = 50000;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final count =
        await DatabaseService.countCollectesToday(widget.collectrice.id);
    final total =
        await DatabaseService.totalCollectesToday(widget.collectrice.id);

    // Tester connexion
    try {
      await SupabaseService.getDashboardStats();
      setState(() => _isOnline = true);
    } catch (_) {
      setState(() => _isOnline = false);
    }

    if (mounted) {
      setState(() {
        _totalCollectes = count;
        _totalMontant = total;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() => _syncing = true);
    final synced = await SupabaseService.syncPendingCollectes();
    setState(() => _syncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$synced collecte(s) synchronisée(s)'),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: _currentTab == 0
          ? _buildDashboard()
          : _currentTab == 1
              ? ScanFlowScreen(
                  collectrice: widget.collectrice,
                  onCollecteComplete: _loadStats,
                )
              : HistoriqueScreen(collectrice: widget.collectrice),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentTab == 0 ? _buildSosFab() : null,
    );
  }

  Widget _buildDashboard() {
    final progress = (_totalMontant / objectifJournalier).clamp(0.0, 1.0);
    final formatter = NumberFormat('#,###', 'fr_FR');

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xFF0A1628),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1628), Color(0xFF05060A)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1BD6FF), Color(0xFF0A6EFF)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.collectrice.prenom[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bonjour, ${widget.collectrice.prenom} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.collectrice.zone,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge online/offline
                      GestureDetector(
                        onTap: _syncing ? null : _syncData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? const Color(0xFF00E676).withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isOnline
                                  ? const Color(0xFF00E676).withOpacity(0.5)
                                  : Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _syncing
                                  ? const SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFF00E676)))
                                  : Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: _isOnline
                                          ? const Color(0xFF00E676)
                                          : Colors.orange,
                                    ),
                              const SizedBox(width: 5),
                              Text(
                                _isOnline ? 'EN LIGNE' : 'HORS LIGNE',
                                style: TextStyle(
                                  color: _isOnline
                                      ? const Color(0xFF00E676)
                                      : Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Objectif journalier
              _buildObjectifCard(progress, formatter),
              const SizedBox(height: 16),

              // KPIs row
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'COLLECTES',
                      value: '$_totalCollectes',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF1BD6FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'MONTANT',
                      value: '${formatter.format(_totalMontant)} F',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF00E676),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'OBJECTIF',
                      value: '${(progress * 100).toStringAsFixed(0)}%',
                      icon: Icons.flag_rounded,
                      color: progress >= 1.0
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF9100),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'ZONE',
                      value: widget.collectrice.zone.replaceAll('Marché ', ''),
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFF7C4DFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bouton Scanner principal
              _buildScanButton(context),
              const SizedBox(height: 16),

              // Infos du jour
              _buildInfoSection(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectifCard(double progress, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1BD6FF).withOpacity(0.15),
            const Color(0xFF0A6EFF).withOpacity(0.08),
          ],
        ),
        border: Border.all(
            color: const Color(0xFF1BD6FF).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OBJECTIF JOURNALIER',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${formatter.format(_totalMontant)} / ${formatter.format(objectifJournalier)} F',
                style: const TextStyle(
                  color: Color(0xFF1BD6FF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFF1BD6FF).withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? const Color(0xFF00E676) : const Color(0xFF1BD6FF),
                ),
                minHeight: 8,
              ),
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                SizedBox(width: 6),
                Text(
                  'Objectif atteint ! Excellent travail 🎉',
                  style: TextStyle(color: Color(0xFF00E676), fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _currentTab = 1),
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1BD6FF), Color(0xFF0A6EFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1BD6FF).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOUVELLE COLLECTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Scanner le carnet client',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()).toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.access_time,
              label: 'Heure actuelle',
              value: DateFormat('HH:mm').format(DateTime.now())),
          _InfoRow(
              icon: Icons.location_on,
              label: 'Zone assignée',
              value: widget.collectrice.zone),
          _InfoRow(
              icon: Icons.gps_fixed,
              label: 'Tracking GPS',
              value: 'Actif — toutes les 5 min',
              color: const Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _buildSosFab() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SosScreen(collectrice: widget.collectrice)),
      ),
      backgroundColor: const Color(0xFFFF3B3B),
      icon: const Icon(Icons.emergency_rounded, color: Colors.white),
      label: const Text(
        'SOS',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1628),
        border: Border(
          top: BorderSide(color: Color(0xFF1BD6FF), width: 0.3),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF1BD6FF).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 11, letterSpacing: 0.5),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _currentTab,
          onDestinationSelected: (i) => setState(() => _currentTab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF1BD6FF)),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded,
                  color: Color(0xFF1BD6FF)),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon:
                  Icon(Icons.history_rounded, color: Color(0xFF1BD6FF)),
              label: 'Historique',
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white38, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
