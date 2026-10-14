import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool isSmall;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (priority) {
      case AppConstants.priorityUrgent:
        color = AppColors.priorityUrgent;
        break;
      case AppConstants.priorityHigh:
        color = AppColors.priorityHigh;
        break;
      case AppConstants.priorityMedium:
        color = AppColors.priorityMedium;
        break;
      case AppConstants.priorityLow:
      default:
        color = AppColors.priorityLow;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
