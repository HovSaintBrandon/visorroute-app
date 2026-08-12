import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ZoneLegend extends StatelessWidget {
  const ZoneLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(AppTheme.statusGreen, 'Visited'),
          const SizedBox(width: 12),
          _buildItem(AppTheme.statusAmber, 'In Route'),
          const SizedBox(width: 12),
          _buildItem(AppTheme.statusRed, 'Overdue'),
          const SizedBox(width: 12),
          _buildItem(Colors.grey, 'Pending'),
        ],
      ),
    );
  }

  Widget _buildItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
