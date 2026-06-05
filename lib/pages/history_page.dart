import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_section_card.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const _historyItems = [
    ('09:15 PM', 'Safe Rule', '6.84x', 'Won'),
    ('08:42 PM', 'Default Rule', '7.61x', 'Won'),
    ('07:58 PM', 'Aggressive Rule', '9.03x', 'High Risk'),
    ('07:11 PM', 'Custom Rule', '5.92x', 'Hold'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text(
            'RECENT PREDICTIONS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review previous prediction windows and outcomes',
            style: TextStyle(fontSize: 16, color: AppColors.textSoft),
          ),
          const SizedBox(height: 18),
          const AppSectionCard(
            child: Row(
              children: [
                AppIconBubble(icon: Icons.history),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your recent play windows are saved here so you can compare rule performance over time.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ..._historyItems.map(_buildHistoryCard),
        ],
      ),
    );
  }

  Widget _buildHistoryCard((String, String, String, String) item) {
    final (time, rule, odds, status) = item;
    final isPositive = status == 'Won';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppSectionCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.panelAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        odds,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$rule • $time',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF13251C)
                        : const Color(0xFF2A1D11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isPositive
                          ? AppColors.success
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Window quality',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                Text(
                  'Stable trend detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
