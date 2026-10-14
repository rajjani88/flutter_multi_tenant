import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/invitation_entity.dart';
import 'organization_providers.dart';

class InvitationsBanner extends ConsumerStatefulWidget {
  final List<InvitationEntity> invitations;

  const InvitationsBanner({super.key, required this.invitations});

  @override
  ConsumerState<InvitationsBanner> createState() => _InvitationsBannerState();
}

class _InvitationsBannerState extends ConsumerState<InvitationsBanner> {
  String? _processingInviteId;

  Future<void> _handleAccept(InvitationEntity invitation) async {
    final authUser = ref.read(authStateProvider).value;
    final profile = ref.read(currentUserProfileProvider).value;
    if (authUser == null) return;

    setState(() => _processingInviteId = invitation.id);

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.acceptInvitation(
        invitation: invitation,
        userUid: authUser.uid,
        userEmail: authUser.email ?? '',
        userDisplayName: (profile != null && profile.displayName.isNotEmpty)
            ? profile.displayName
            : (authUser.displayName ?? authUser.email?.split('@').first ?? 'Member'),
      );

      // Invalidate caches and immediately switch context to this organization
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(userOrganizationsProvider);
      ref.invalidate(pendingInvitationsProvider);
      ref.read(activeOrganizationIdProvider.notifier).setOrgId(invitation.organizationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${invitation.organizationName} as ${invitation.role.value}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingInviteId = null);
      }
    }
  }

  Future<void> _handleDecline(InvitationEntity invitation) async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;

    setState(() => _processingInviteId = invitation.id);

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.declineInvitation(
        invitation: invitation,
        userUid: authUser.uid,
      );

      ref.invalidate(pendingInvitationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined invitation to ${invitation.organizationName}.'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingInviteId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invitations.isEmpty) return const SizedBox.shrink();

    return Column(
      children: widget.invitations.map((invitation) {
        final isProcessing = _processingInviteId == invitation.id;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.18),
                AppColors.secondary.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            invitation.organizationName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryLight.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            invitation.role.value,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invited by ${invitation.invitedByEmail}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isProcessing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                TextButton(
                  onPressed: () => _handleDecline(invitation),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMutedDark,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () => _handleAccept(invitation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(100, 34),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Accept & Join', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
