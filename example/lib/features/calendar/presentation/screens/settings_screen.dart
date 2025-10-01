import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/calendar_permission_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: CalendarPermissionWidget(
        child: ListView(
          children: [
            // App Information Section
            _buildSection(
              context,
              title: 'App Information',
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Calendar Bridge Example'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),

            // Calendar Settings Section
            _buildSection(
              context,
              title: 'Calendars',
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final defaultCalendarAsync = ref.watch(
                      defaultCalendarProvider,
                    );
                    return defaultCalendarAsync.when(
                      data: (defaultCalendar) => ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Default Calendar'),
                        subtitle: Text(defaultCalendar?.name ?? 'None'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showDefaultCalendarDialog(context, ref),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.calendar_today),
                        title: Text('Default Calendar'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.calendar_today),
                        title: Text('Default Calendar'),
                        subtitle: Text('Error loading'),
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final calendarsAsync = ref.watch(calendarsProvider);
                    return calendarsAsync.when(
                      data: (calendars) => ListTile(
                        leading: const Icon(Icons.storage),
                        title: const Text('Total Calendars'),
                        subtitle: Text('${calendars.length} calendars'),
                        trailing: Text(
                          '${calendars.where((c) => !c.isReadOnly).length} editable',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.storage),
                        title: Text('Total Calendars'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.storage),
                        title: Text('Total Calendars'),
                        subtitle: Text('Error loading'),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Permissions Section
            _buildSection(
              context,
              title: 'Permissions',
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final permissionsAsync = ref.watch(permissionsProvider);
                    return permissionsAsync.when(
                      data: (hasPermissions) => ListTile(
                        leading: Icon(
                          hasPermissions ? Icons.check_circle : Icons.warning,
                          color: hasPermissions
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: const Text('Calendar Access'),
                        subtitle: Text(
                          hasPermissions
                              ? 'Granted'
                              : 'Not granted - tap to request',
                        ),
                        onTap: hasPermissions
                            ? null
                            : () async {
                                try {
                                  await ref.read(
                                    requestPermissionsProvider(null).future,
                                  );
                                  ref.invalidate(permissionsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to request permissions: $e',
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      loading: () => const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Calendar Access'),
                        subtitle: Text('Checking...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.error, color: Colors.red),
                        title: Text('Calendar Access'),
                        subtitle: Text('Error checking permissions'),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Debug Section (only in debug mode)
            if (kDebugMode) ...[
              _buildSection(
                context,
                title: 'Debug',
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Reset all cached data'),
                    onTap: () => _clearCache(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Refresh All Data'),
                    subtitle: const Text('Reload calendars and events'),
                    onTap: () => _refreshAllData(context, ref),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Calendar Bridge Example',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.calendar_month, size: 48),
      children: [
        const Text(
          'A comprehensive example app demonstrating all features of the Calendar Bridge plugin.',
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'This app showcases modern Flutter development practices including clean architecture, state management with Riverpod, and Material 3 design.',
        ),
      ],
    );
  }

  void _showDefaultCalendarDialog(BuildContext context, WidgetRef ref) {
    final calendarsAsync = ref.read(writableCalendarsProvider);

    calendarsAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No writable calendars available')),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Default Calendar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: calendars
                  .map(
                    (calendar) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(calendar.color ?? 0xFF2196F3),
                        radius: 16,
                        child: Text(
                          calendar.name.isNotEmpty
                              ? calendar.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(calendar.name),
                      subtitle: Text(calendar.accountName ?? 'Local Calendar'),
                      onTap: () {
                        // TODO: Implement setting default calendar
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Default calendar set to ${calendar.name}',
                            ),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loading calendars...')));
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading calendars: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  void _clearCache(BuildContext context, WidgetRef ref) {
    // Invalidate all providers to clear cache
    ref.invalidate(calendarsProvider);
    ref.invalidate(permissionsProvider);
    ref.invalidate(defaultCalendarProvider);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache cleared successfully')));
  }

  void _refreshAllData(BuildContext context, WidgetRef ref) {
    // Refresh all data
    ref.invalidate(calendarsProvider);
    ref.invalidate(permissionsProvider);
    ref.invalidate(defaultCalendarProvider);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refreshing all data...')));
  }
}
