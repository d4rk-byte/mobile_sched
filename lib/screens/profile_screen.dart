import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/staggered_list.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

const _kProfileSectionSpacing = 18.0;
const _kProfileCardPadding = 14.0;
const _kProfilePillVerticalPadding = AppSpacing.sm - 2;
const _kProfileInfoRowSpacing = AppSpacing.md - 2;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final textTheme = Theme.of(context).textTheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final initials = _buildInitials(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          StaggeredItem(
            index: 0,
            child: _ProfileHeader(user: user, initials: initials),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredItem(
            index: 1,
            child: _ProfileCompletionCard(user: user),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredItem(
            index: 2,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cardPrimaryEnd,
                      side: const BorderSide(color: AppColors.cardPrimaryEnd),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Change Password'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cardPrimaryEnd,
                      side: const BorderSide(color: AppColors.cardPrimaryEnd),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredItem(
            index: 3,
            child: _InfoSection(
              title: 'Basic Information',
              entries: [
                _InfoEntry(label: 'Full Name', value: user.fullName),
                _InfoEntry(label: 'Username', value: user.username),
                _InfoEntry(label: 'Email', value: user.email),
                _InfoEntry(label: 'Employee ID', value: user.employeeId),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredItem(
            index: 4,
            child: _InfoSection(
              title: 'Faculty Information',
              entries: [
                _InfoEntry(label: 'Position', value: user.position),
                _InfoEntry(label: 'College', value: user.college?.name),
                _InfoEntry(label: 'Department', value: user.department?.name),
                _InfoEntry(label: 'Address', value: user.address),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredItem(
            index: 5,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => _confirmLogout(context, ref),
                icon: authState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label:
                    Text(authState.isLoading ? 'Signing out...' : 'Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: Color(0xFFFECACA)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                textStyle: textTheme.labelLarge,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  String _buildInitials(UserProfile user) {
    final first = (user.firstName ?? user.fullName).trim();
    final last = (user.lastName ?? '').trim();

    final firstInitial = first.isNotEmpty ? first[0].toUpperCase() : 'F';
    final lastInitial = last.isNotEmpty ? last[0].toUpperCase() : '';

    return '$firstInitial$lastInitial';
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final String initials;

  const _ProfileHeader({required this.user, required this.initials});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_kProfileSectionSpacing),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardPrimaryStart, AppColors.cardPrimaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardPrimaryStart.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: _kProfileCardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE0E7FF),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: _kProfilePillVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    user.position?.trim().isNotEmpty == true
                        ? user.position!
                        : 'Faculty Member',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final UserProfile user;

  const _ProfileCompletionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isComplete = user.profileComplete;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_kProfileCardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete
                    ? Icons.verified_user_outlined
                    : Icons.pending_actions_outlined,
                color: isComplete ? AppColors.success : AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isComplete ? 'Profile Complete' : 'Profile Needs Attention',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isComplete
                      ? const Color(0xFF166534)
                      : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileCompletionBar(user: user),
          if (!isComplete && user.missingProfileFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Missing: ${user.missingProfileFields.join(', ')}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileCompletionBar extends StatelessWidget {
  final UserProfile user;

  const _ProfileCompletionBar({required this.user});

  static const _totalFields = 7;

  int _countFilledFields(UserProfile u) {
    int filled = 0;
    if (u.firstName?.trim().isNotEmpty == true) filled++;
    if (u.lastName?.trim().isNotEmpty == true) filled++;
    if (u.email.trim().isNotEmpty) filled++;
    if (u.employeeId?.trim().isNotEmpty == true) filled++;
    if (u.position?.trim().isNotEmpty == true) filled++;
    if (u.college != null) filled++;
    if (u.department != null) filled++;
    return filled;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filled = _countFilledFields(user);
    final progress = filled / _totalFields;
    final progressColor = user.profileComplete ? AppColors.success : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: progressColor.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$filled/$_totalFields',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoEntry> entries;

  const _InfoSection({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_kProfileCardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _kProfileInfoRowSpacing),
          ...entries.asMap().entries.map(
            (e) => Column(
              children: [
                if (e.key > 0)
                  const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: _kProfileInfoRowSpacing),
                  child: _InfoRow(entry: e.value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final _InfoEntry entry;

  const _InfoRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            entry.label,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: _kProfileInfoRowSpacing),
        Expanded(
          child: Text(
            entry.value?.trim().isNotEmpty == true
                ? entry.value!.trim()
                : 'Not set',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoEntry {
  final String label;
  final String? value;

  const _InfoEntry({required this.label, required this.value});
}
