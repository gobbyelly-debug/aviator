import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_section_card.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  static const _rules = [
    (
      'Default Rule',
      'Balanced timing model for everyday play sessions.',
      Icons.balance_rounded,
    ),
    (
      'Safe Rule',
      'Prefers steadier entries with lower risk and calmer odds movement.',
      Icons.shield_outlined,
    ),
    (
      'Aggressive Rule',
      'Targets higher multipliers and faster entry windows.',
      Icons.local_fire_department_outlined,
    ),
    (
      'Custom Rule',
      'A flexible slot for experimenting with your own strategy.',
      Icons.tune_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text(
            'RULES LIBRARY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a rule that matches your play style',
            style: TextStyle(fontSize: 16, color: AppColors.textSoft),
          ),
          const SizedBox(height: 18),
          ..._rules.map(_buildRuleCard),
        ],
      ),
    );
  }

  Widget _buildRuleCard((String, String, IconData) rule) {
    final (title, description, icon) = rule;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppSectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBubble(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
