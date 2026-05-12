// lib/screens/role_selector_screen.dart
import 'package:flutter/material.dart';
import '../config/locale_manager.dart';
import '../widgets/language_selector.dart';
import 'collectrice/login_screen.dart';
import 'superviseur/supervisor_login_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  final LocaleManager localeManager;
  const RoleSelectorScreen({super.key, required this.localeManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeManager,
      builder: (_, __) {
        final t = localeManager.t;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1628), Color(0xFF05060A)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Sélecteur de langue en haut à droite
                    Align(
                      alignment: Alignment.centerRight,
                      child: LanguageSelector(
                        localeManager: localeManager,
                        compact: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Header
                    Text(
                      t.appName,
                      style: TextStyle(
                        color: const Color(0xFF1BD6FF),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF1BD6FF).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.chooseProfile,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Carte Collectrice
                    _RoleCard(
                      icon: Icons.person_pin_rounded,
                      label: t.collectrice,
                      subtitle: t.collectriceSubtitle,
                      color: const Color(0xFF1BD6FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectriceLoginScreen(
                              localeManager: localeManager),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Carte Superviseur
                    _RoleCard(
                      icon: Icons.dashboard_rounded,
                      label: t.superviseur,
                      subtitle: t.superviseurSubtitle,
                      color: const Color(0xFF7C4DFF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SupervisorLoginScreen(
                              localeManager: localeManager),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Sélecteur langue complet en bas
                    LanguageSelector(localeManager: localeManager),

                    const SizedBox(height: 16),

                    // Footer
                    Text(
                      '© 2026 FU-DICIA ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: widget.color.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.15),
                  border:
                      Border.all(color: widget.color.withOpacity(0.4)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.color.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
