import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import 'organization_providers.dart';

class CreateOrgDialog extends ConsumerStatefulWidget {
  const CreateOrgDialog({super.key});

  @override
  ConsumerState<CreateOrgDialog> createState() => _CreateOrgDialogState();
}

class _CreateOrgDialogState extends ConsumerState<CreateOrgDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(organizationRepositoryProvider);
      final profile = ref.read(currentUserProfileProvider).value;
      final ownerDisplayName = (profile != null && profile.displayName.isNotEmpty)
          ? profile.displayName
          : ((user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName!
              : (user.email?.split('@').first ?? 'Owner'));

      final orgId = await repo.createOrganization(
        name: _nameController.text.trim(),
        ownerUid: user.uid,
        ownerEmail: user.email ?? 'owner@nexus.com',
        ownerDisplayName: ownerDisplayName,
      );

      // Invalidate caches and set as active tenant
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(userOrganizationsProvider);
      ref.read(activeOrganizationIdProvider.notifier).setOrgId(orgId);

      if (mounted) {
        Navigator.of(context).pop(orgId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created organization "${_nameController.text.trim()}"'),
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
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
                    child: const Icon(Icons.business_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Organization',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          'You will be designated as the Owner',
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

              const Text('Organization Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Acme Innovations, Stark Labs',
                  prefixIcon: Icon(Icons.corporate_fare_rounded, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Organization name is required';
                  }
                  if (val.trim().length > 100) {
                    return 'Name cannot exceed 100 characters';
                  }
                  return null;
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
                    onPressed: _isLoading ? null : _handleCreate,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Workspace'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
