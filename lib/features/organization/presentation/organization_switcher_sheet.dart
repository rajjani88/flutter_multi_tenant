import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'create_org_dialog.dart';
import 'invitations_banner.dart';
import 'organization_providers.dart';

class OrganizationSwitcherSheet extends ConsumerWidget {
  const OrganizationSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userOrgsAsync = ref.watch(userOrganizationsProvider);
    final activeOrgId = ref.watch(activeOrganizationIdProvider);
    final pendingInvites = ref.watch(pendingInvitationsProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Switch Organization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a workspace to switch tenant isolation boundary',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 16),

          if (pendingInvites.isNotEmpty) ...[
            InvitationsBanner(invitations: pendingInvites),
            const SizedBox(height: 12),
          ],

          userOrgsAsync.when(
            data: (orgs) {
              if (orgs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No organizations found. Create one below!',
                      style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final org = orgs[index];
                  final isSelected = org.id == activeOrgId;

                  return InkWell(
                    onTap: () {
                      ref.read(activeOrganizationIdProvider.notifier).setOrgId(org.id);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.darkBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkSurfaceHover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                org.name.isNotEmpty
                                    ? org.name.substring(0, 1).toUpperCase()
                                    : 'O',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  org.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: AppColors.textPrimaryDark,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${org.id.substring(0, 8)}...',
                                  style: const TextStyle(
                                    color: AppColors.textMutedDark,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading organizations: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => const CreateOrgDialog(),
              );
            },
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text('Create New Organization'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
