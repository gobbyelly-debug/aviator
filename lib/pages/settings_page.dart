import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool autoRefreshEnabled = true;
  bool localTimeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tune how the prediction dashboard behaves',
            style: TextStyle(fontSize: 16, color: AppColors.textSoft),
          ),
          const SizedBox(height: 18),
          AppSectionCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Push notifications',
                  subtitle: 'Receive alerts when new prediction windows open.',
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() => notificationsEnabled = value);
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                _buildSwitchTile(
                  title: 'Auto refresh',
                  subtitle: 'Refresh odds automatically after each countdown.',
                  value: autoRefreshEnabled,
                  onChanged: (value) {
                    setState(() => autoRefreshEnabled = value);
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                _buildSwitchTile(
                  title: 'Use local time',
                  subtitle: 'Show all countdown windows in device local time.',
                  value: localTimeEnabled,
                  onChanged: (value) {
                    setState(() => localTimeEnabled = value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.accent,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}
