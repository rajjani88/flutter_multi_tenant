import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case AppConstants.statusDone:
        color = AppColors.statusDone;
        icon = Icons.check_circle_rounded;
        break;
      case AppConstants.statusInProgress:
        color = AppColors.statusInProgress;
        icon = Icons.timelapse_rounded;
        break;
      case AppConstants.statusToDo:
      default:
        color = AppColors.statusToDo;
        icon = Icons.radio_button_unchecked_rounded;
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
          Icon(icon, size: isSmall ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
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
