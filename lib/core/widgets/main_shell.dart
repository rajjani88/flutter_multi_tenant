import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/connectivity_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/organization/presentation/organization_providers.dart';
import '../../features/organization/presentation/create_org_dialog.dart';
import '../../features/organization/presentation/invitations_banner.dart';
import 'degraded_network_banner.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrg = ref.watch(activeOrganizationProvider).value;
    final userOrgs = ref.watch(userOrganizationsProvider).value ?? [];
    final pendingInvitations = ref.watch(pendingInvitationsProvider).value ?? [];
    final authUser = ref.watch(authStateProvider).value;
    final profile = ref.watch(currentUserProfileProvider).value;
    final isOnline = ref.watch(isOnlineStreamProvider).value ?? true;
    final isDegraded = ref.watch(degradedModeProvider);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/tasks')) currentIndex = 0;
    if (location.startsWith('/team')) currentIndex = 1;
    if (location.startsWith('/audit')) currentIndex = 2;
    if (location.startsWith('/settings')) currentIndex = 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Network degradation / offline alert banner
            DegradedNetworkBanner(
              isOffline: !isOnline,
              isDegradedMode: isDegraded,
              onToggleDegradedMode: () {
                ref.read(degradedModeProvider.notifier).setMode(false);
                ref.read(connectivityServiceProvider).toggleDegradedMode(false);
              },
            ),

            // Top User & Workspace Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nexus SaaS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),

                  // Quick profile & logout
                  if (authUser != null) ...[
                    Text(
                      (profile != null && profile.displayName.isNotEmpty)
                          ? profile.displayName
                          : (authUser.displayName ?? authUser.email ?? 'User'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      tooltip: 'Sign Out',
                      color: AppColors.textMutedDark,
                      onPressed: () => _showLogoutConfirmationDialog(context, ref),
                    ),
                  ],
                ],
              ),
            ),

            // Pending Workspace Invitations Banner
            if (pendingInvitations.isNotEmpty)
              InvitationsBanner(invitations: pendingInvitations),

            // Banner when no organization exists yet
            if (activeOrg == null && userOrgs.isEmpty && pendingInvitations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryLight),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No workspace found. Create an organization to unlock team & task collaboration.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CreateOrgDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Create Org', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Routed page content
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/tasks');
              break;
            case 1:
              context.go('/team');
              break;
            case 2:
              context.go('/audit');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.primaryLight),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primaryLight),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded, color: AppColors.primaryLight),
            label: 'Audit Trail',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primaryLight),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) async {
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
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
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
          style: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
