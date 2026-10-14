import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/role_matrix.dart';
import 'organization_providers.dart';

class OrgSettingsScreen extends ConsumerStatefulWidget {
  const OrgSettingsScreen({super.key});

  @override
  ConsumerState<OrgSettingsScreen> createState() => _OrgSettingsScreenState();
}

class _OrgSettingsScreenState extends ConsumerState<OrgSettingsScreen> {
  final _nameController = TextEditingController();
  final _userNameController = TextEditingController();
  bool _allowInvites = true;
  bool _isLoading = false;
  bool _isProfileLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final org = ref.read(activeOrganizationProvider).value;
    if (org != null) {
      _nameController.text = org.name;
      _allowInvites = org.settings['allowMemberInvites'] ?? true;
    }
    final profile = ref.read(currentUserProfileProvider).value;
    final authUser = ref.read(authStateProvider).value;
    _userNameController.text = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : (authUser?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final authUser = ref.read(authStateProvider).value;
    final activeOrg = ref.read(activeOrganizationProvider).value;
    if (authUser == null) return;

    final newName = _userNameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isProfileLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .updateDisplayName(
            uid: authUser.uid,
            newDisplayName: newName,
            activeOrgId: activeOrg?.id,
          );

      ref.invalidate(currentUserProfileProvider);
      if (activeOrg != null) {
        ref.invalidate(organizationMembersProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display name updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update name: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final activeOrg = ref.read(activeOrganizationProvider).value;
    final authUser = ref.read(authStateProvider).value;
    final currentRole = ref.read(currentRoleProvider);

    if (activeOrg == null || authUser == null) return;

    if (!RoleMatrix.canManageOrganizationSettings(currentRole)) {
      setState(
        () => _errorMessage =
            'Access restricted: Only Owners and Admins can modify settings.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate network latency if degraded mode is active
      await ref.read(connectivityServiceProvider).simulateLatencyIfNeeded();

      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateSettings(
        orgId: activeOrg.id,
        newName: _nameController.text.trim(),
        settings: {
          'allowMemberInvites': _allowInvites,
          'updatedBy': authUser.email,
        },
        actorUid: authUser.uid,
        actorEmail: authUser.email ?? 'user@nexus.com',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization settings updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst(RegExp(r'\[.*?\]'), '')
            .trim();
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
    final canManage = RoleMatrix.canManageOrganizationSettings(currentRole);

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workspace Settings')),
        body: const AppErrorWidget(
          error: 'permission-denied',
          customMessage: 'Organization settings are restricted to Owners and Admins. Managers, Members, and Viewers cannot manage settings.',
        ),
      );
    }

    final activeOrg = ref.watch(activeOrganizationProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workspace Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // User Profile Identity Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'My Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your Display Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _userNameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Raj Test',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isProfileLoading
                              ? null
                              : _handleSaveProfile,
                          icon: _isProfileLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Update Display Name'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Organization Identity Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Organization Identity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Workspace Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Company or Project Name',
                            prefixIcon: Icon(
                              Icons.corporate_fare_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Allow Member Invitations',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Permit Admins to invite new teammates',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          value: _allowInvites,
                          activeColor: AppColors.primary,
                          onChanged: (val) =>
                              setState(() => _allowInvites = val),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSave,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tenant Isolation Metadata Card
                if (activeOrg != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tenant Isolation Metadata',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _MetadataRow(label: 'Tenant ID', value: activeOrg.id),
                          _MetadataRow(
                            label: 'Owner UID',
                            value: activeOrg.ownerId,
                          ),
                          _MetadataRow(
                            label: 'Created At',
                            value: DateFormat.yMMMd().add_jm().format(
                              activeOrg.createdAt,
                            ),
                          ),
                          _MetadataRow(
                            label: 'Last Updated',
                            value: DateFormat.yMMMd().add_jm().format(
                              activeOrg.updatedAt,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Live Modification & Resilience Simulator Card
                // Card(
                //   child: Padding(
                //     padding: const EdgeInsets.all(20),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Row(
                //           children: [
                //             const Icon(Icons.science_rounded, color: AppColors.secondary, size: 20),
                //             const SizedBox(width: 8),
                //             const Text(
                //               'Resilience & Failure Simulator',
                //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                //             ),
                //           ],
                //         ),
                //         const SizedBox(height: 8),
                //         const Text(
                //           'Evaluator live modification utility: Simulate network degradation and slow responses to test graceful failure handling.',
                //           style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                //         ),
                //         const SizedBox(height: 16),
                //         SwitchListTile(
                //           contentPadding: EdgeInsets.zero,
                //           title: const Text('Simulate Degraded Network (Slow API)', style: TextStyle(fontSize: 14)),
                //           subtitle: const Text(
                //             'Adds +2000ms delay to transactions to verify loading and retry state UX.',
                //             style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                //           ),
                //           value: isDegraded,
                //           activeColor: AppColors.warning,
                //           onChanged: (val) {
                //             ref.read(degradedModeProvider.notifier).setMode(val);
                //             ref.read(connectivityServiceProvider).toggleDegradedMode(val);
                //           },
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out of Account'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0x26EF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your workspace session?',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(activeOrganizationIdProvider.notifier).setOrgId(null);
    }
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMutedDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
