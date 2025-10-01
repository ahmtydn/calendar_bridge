import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';

class CalendarPermissionWidget extends ConsumerWidget {
  final Widget child;

  const CalendarPermissionWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(permissionsProvider);

    return permissionsAsync.when(
      data: (hasPermissions) {
        if (hasPermissions) {
          return child;
        }

        return _buildPermissionRequest(context, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error checking permissions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Calendar Access Required',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This app needs access to your calendars to display and manage your events.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                ref.invalidate(requestPermissionsProvider);
                await ref.read(requestPermissionsProvider(null).future);
                ref.invalidate(permissionsProvider);
              },
              icon: const Icon(Icons.security),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
