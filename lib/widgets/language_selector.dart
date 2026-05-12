// lib/widgets/language_selector.dart
import 'package:flutter/material.dart';
import '../config/locale_manager.dart';

class LanguageSelector extends StatelessWidget {
  final LocaleManager localeManager;
  final bool compact;

  const LanguageSelector({
    super.key,
    required this.localeManager,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeManager,
      builder: (_, __) => compact
          ? _buildCompact(context)
          : _buildFull(context),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1BD6FF).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1BD6FF).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localeManager.languageLabel,
              style: const TextStyle(
                color: Color(0xFF1BD6FF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              color: Color(0xFF1BD6FF),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGUE / GBƆGBƆ / TƆM',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: AppLanguage.values
              .map((lang) => _LangChip(
                    lang: lang,
                    isSelected: localeManager.current == lang,
                    onTap: () => localeManager.setLanguage(lang),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AnimatedBuilder(
        animation: localeManager,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CHOISIR LA LANGUE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ...AppLanguage.values.map((lang) {
                final isSelected = localeManager.current == lang;
                
                // CORRECTION ICI : Utilisation de 'translations' au lieu de '_translations'
                final translation = LocaleManager.translations[lang]!;
                
                return GestureDetector(
                  onTap: () {
                    localeManager.setLanguage(lang);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1BD6FF).withOpacity(0.1)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1BD6FF).withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _langFlag(lang),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _langName(lang),
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF1BD6FF)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                translation.appTagline, // Utilisation de la traduction chargée
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF1BD6FF), size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _langFlag(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.francais:
        return '🇫🇷';
      case AppLanguage.ewe:
        return '🇹🇬';
      case AppLanguage.kabiye:
        return '🇹🇬';
    }
  }

  String _langName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.francais:
        return 'Français';
      case AppLanguage.ewe:
        return 'Éwé';
      case AppLanguage.kabiye:
        return 'Kabiyè';
    }
  }
}

class _LangChip extends StatelessWidget {
  final AppLanguage lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (lang) {
      case AppLanguage.francais:
        return '🇫🇷 FR';
      case AppLanguage.ewe:
        return '🇹🇬 EWE';
      case AppLanguage.kabiye:
        return '🇹🇬 KAB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1BD6FF).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1BD6FF)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          _label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1BD6FF) : Colors.white54,
            fontSize: 11,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}