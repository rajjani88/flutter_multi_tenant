import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/organization/domain/role_matrix.dart';

class RoleBadge extends StatelessWidget {
  final AppRole role;
  final bool isSmall;

  const RoleBadge({
    super.key,
    required this.role,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (role) {
      case AppRole.owner:
        color = AppColors.roleOwner;
        icon = Icons.workspace_premium_rounded;
        break;
      case AppRole.admin:
        color = AppColors.roleAdmin;
        icon = Icons.admin_panel_settings_rounded;
        break;
      case AppRole.manager:
        color = AppColors.roleManager;
        icon = Icons.manage_accounts_rounded;
        break;
      case AppRole.member:
        color = AppColors.roleMember;
        icon = Icons.person_rounded;
        break;
      case AppRole.viewer:
        color = AppColors.roleViewer;
        icon = Icons.visibility_rounded;
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
            role.value,
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
