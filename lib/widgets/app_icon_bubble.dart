import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppIconBubble extends StatelessWidget {
  const AppIconBubble({super.key, required this.icon, this.size = 54});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2.3),
      ),
      child: Icon(icon, color: AppColors.accent, size: size * 0.48),
    );
  }
}
