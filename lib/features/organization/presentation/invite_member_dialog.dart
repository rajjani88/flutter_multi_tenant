import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/role_matrix.dart';
import 'organization_providers.dart';

class InviteMemberDialog extends ConsumerStatefulWidget {
  const InviteMemberDialog({super.key});

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  AppRole _selectedRole = AppRole.member;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final activeOrgId = ref.read(activeOrganizationIdProvider);
    final authUser = ref.read(authStateProvider).value;
    final currentRole = ref.read(currentRoleProvider);

    if (activeOrgId == null || authUser == null) return;

    // Check if user has permission to invite
    if (!RoleMatrix.canInviteOrRemoveMembers(currentRole)) {
      setState(() => _errorMessage = 'You lack permissions to invite members.');
      return;
    }

    // Admin cannot assign Owner role
    if (currentRole == AppRole.admin && _selectedRole == AppRole.owner) {
      setState(() => _errorMessage = 'Admins are restricted from assigning the Owner role.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(organizationRepositoryProvider);
      // For demo & invitation, generate or hash user id from email
      final simulatedUid = 'user_${_emailController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      final activeOrg = ref.read(activeOrganizationProvider).value;
      await repo.addMember(
        orgId: activeOrgId,
        orgName: activeOrg?.name ?? 'Workspace',
        targetUid: simulatedUid,
        targetEmail: _emailController.text.trim(),
        targetDisplayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : _emailController.text.trim(),
        role: _selectedRole,
        actorUid: authUser.uid,
        actorEmail: authUser.email ?? 'actor@nexus.com',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invited ${_emailController.text.trim()} as ${_selectedRole.value}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'\[.*?\]'), '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentRoleProvider);
    // Determine which roles this user can assign
    final availableRoles = currentRole == AppRole.owner
        ? [AppRole.admin, AppRole.manager, AppRole.member, AppRole.viewer]
        : [AppRole.manager, AppRole.member, AppRole.viewer]; // Admins cannot assign Owner!

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite Team Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          'Grant role-based access control to workspace',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email
              const Text('Member Email',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  hintText: 'teammate@company.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),

              // Name
              const Text('Display Name (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Alex Morgan',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Role Selector
              const Text('Assigned Role',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<AppRole>(
                value: availableRoles.contains(_selectedRole)
                    ? _selectedRole
                    : availableRoles.first,
                dropdownColor: AppColors.darkSurface,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.security_rounded, size: 20),
                ),
                items: availableRoles.map((role) {
                  return DropdownMenuItem<AppRole>(
                    value: role,
                    child: Text('${role.value} - ${_getRoleDescription(role)}',
                        style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleInvite,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Send Invitation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDescription(AppRole role) {
    switch (role) {
      case AppRole.owner:
        return 'Full workspace authority';
      case AppRole.admin:
        return 'Settings & team management';
      case AppRole.manager:
        return 'Task & audit management';
      case AppRole.member:
        return 'Create & edit own tasks';
      case AppRole.viewer:
        return 'Read-only access';
    }
  }
}
