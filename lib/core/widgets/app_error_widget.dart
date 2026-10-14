import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  bool get _isPermissionError {
    final errStr = error.toString().toLowerCase();
    return errStr.contains('permission-denied') ||
        errStr.contains('insufficient-permissions') ||
        errStr.contains('permission denied');
  }

  @override
  Widget build(BuildContext context) {
    final isPerm = _isPermissionError;
    final title = isPerm ? 'Access Restricted' : 'Something went wrong';
    final message = customMessage ??
        (isPerm
            ? 'Your organization role does not have authorization to view or perform this action. Contact an Owner or Admin to adjust permissions.'
            : error.toString());

    final icon = isPerm ? Icons.lock_outline_rounded : Icons.error_outline_rounded;
    final color = isPerm ? AppColors.warning : AppColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (onRetry != null && !isPerm) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
