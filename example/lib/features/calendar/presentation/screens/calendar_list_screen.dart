import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/calendar_permission_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

class CalendarListScreen extends ConsumerWidget {
  const CalendarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create calendar screen
              _showCreateCalendarDialog(context, ref);
            },
          ),
        ],
      ),
      body: CalendarPermissionWidget(child: _buildCalendarsList(context, ref)),
    );
  }

  Widget _buildCalendarsList(BuildContext context, WidgetRef ref) {
    final calendarsAsync = ref.watch(calendarsProvider);

    return calendarsAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.calendar_today,
            title: 'No Calendars',
            message: 'Create your first calendar to get started.',
            action: FilledButton.icon(
              onPressed: () => _showCreateCalendarDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Calendar'),
            ),
          );
        }

        return ListView.builder(
          itemCount: calendars.length,
          itemBuilder: (context, index) {
            final calendar = calendars[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(calendar.color ?? 0xFF2196F3),
                  child: Text(
                    calendar.name.isNotEmpty
                        ? calendar.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  calendar.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      calendar.accountName ?? 'Local Calendar',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          calendar.isReadOnly ? Icons.visibility : Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          calendar.isReadOnly ? 'Read-only' : 'Editable',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'delete':
                        if (!calendar.isReadOnly) {
                          await _showDeleteConfirmDialog(
                            context,
                            ref,
                            calendar,
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!calendar.isReadOnly)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: AppSpacing.sm),
                            Text('Delete'),
                          ],
                        ),
                      ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => AppErrorWidget(
        error: error,
        onRetry: () => ref.invalidate(calendarsProvider),
      ),
    );
  }

  void _showCreateCalendarDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Calendar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Calendar Name',
                  hintText: 'Enter calendar name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Text('Color:'),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: () =>
                        _showColorPicker(context, selectedColor, (color) {
                          setState(() {
                            selectedColor = color;
                          });
                        }),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: nameController.text.isEmpty
                  ? null
                  : () async {
                      try {
                        final api = ref.read(calendarBridgeProvider);
                        await api.createCalendar(
                          name: nameController.text,
                          color: selectedColor.toARGB32(),
                        );
                        ref.invalidate(calendarsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Calendar created successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create calendar: $e'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: colors
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    onColorChanged(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentColor == color
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: currentColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Calendar calendar,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calendar'),
        content: Text(
          'Are you sure you want to delete "${calendar.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(calendarBridgeProvider);
        await api.deleteCalendar(calendar.id);
        ref.invalidate(calendarsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calendar deleted successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete calendar: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
