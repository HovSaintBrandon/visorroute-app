import 'package:flutter/material.dart';
import '../../../../shared_models/student.dart';
import '../../../../core/theme/app_theme.dart';

class StudentPin extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const StudentPin({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color pinColor;
    switch (student.status) {
      case VisitStatus.visited:
      case VisitStatus.assessed:
        pinColor = AppTheme.statusGreen;
        break;
      case VisitStatus.inProgress:
        pinColor = AppTheme.statusAmber;
        break;
      case VisitStatus.overdue:
        pinColor = AppTheme.statusRed;
        break;
      case VisitStatus.unvisited:
      default:
        pinColor = Colors.grey;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              student.fullName,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Icon(
            Icons.location_on_sharp,
            color: pinColor,
            size: 36,
          ),
        ],
      ),
    );
  }
}
