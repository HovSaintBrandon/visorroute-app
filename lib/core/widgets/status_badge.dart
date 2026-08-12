import 'package:flutter/material.dart';
import '../../shared_models/student.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final VisitStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case VisitStatus.visited:
        bg = AppTheme.statusGreen.withOpacity(0.15);
        fg = AppTheme.statusGreen;
        label = 'Visited';
        break;
      case VisitStatus.assessed:
        bg = const Color(0xFF3B82F6).withOpacity(0.15);
        fg = const Color(0xFF3B82F6);
        label = 'Assessed';
        break;
      case VisitStatus.inProgress:
        bg = AppTheme.statusAmber.withOpacity(0.15);
        fg = AppTheme.statusAmber;
        label = 'In Route';
        break;
      case VisitStatus.overdue:
        bg = AppTheme.statusRed.withOpacity(0.15);
        fg = AppTheme.statusRed;
        label = 'Overdue';
        break;
      case VisitStatus.unvisited:
      default:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
