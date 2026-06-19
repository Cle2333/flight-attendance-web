import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class StatCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String value;
  final String label;
  const StatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: r.padAll(1.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(r.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r.touchTarget * 1.05,
            height: r.touchTarget * 1.05,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(r.radiusSm * 0.85),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: r.textLg)),
          ),
          SizedBox(height: r.gapSm),
          Text(
            value,
            style: TextStyle(
              fontSize: r.text2xl,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: r.gap2xs),
          Text(
            label,
            style: TextStyle(
              fontSize: r.textXs,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}