import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DegradedNetworkBanner extends StatelessWidget {
  final bool isOffline;
  final bool isDegradedMode;
  final VoidCallback? onRetry;
  final VoidCallback? onToggleDegradedMode;

  const DegradedNetworkBanner({
    super.key,
    required this.isOffline,
    required this.isDegradedMode,
    this.onRetry,
    this.onToggleDegradedMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !isDegradedMode) {
      return const SizedBox.shrink();
    }

    final color = isOffline ? AppColors.error : AppColors.warning;
    final icon = isOffline ? Icons.wifi_off_rounded : Icons.speed_rounded;
    final message = isOffline
        ? 'Operating in offline mode. Changes will sync when connection is restored.'
        : 'Degraded Network Simulation active (+2000ms latency).';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onToggleDegradedMode != null && isDegradedMode)
            TextButton(
              onPressed: onToggleDegradedMode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 26),
              ),
              child: const Text('Turn Off', style: TextStyle(fontSize: 11)),
            ),
          if (onRetry != null && isOffline)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 26),
              ),
              child: const Text('Reconnect', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
