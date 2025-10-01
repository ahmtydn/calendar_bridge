import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';
import 'create_edit_event_screen.dart';

class EventDetailsScreen extends ConsumerWidget {
  final CalendarEvent event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title ?? 'Event Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => CreateEditEventScreen(event: event),
                    ),
                  );
                  if (result == true) {
                    // Event was updated, refresh data
                    ref.invalidate(eventsProvider);
                  }
                  break;
                case 'delete':
                  await _showDeleteConfirmDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: AppSpacing.sm),
                    Text('Edit'),
                  ],
                ),
              ),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            _buildEventHeader(context),
            const SizedBox(height: AppSpacing.lg),

            // Date and Time
            _buildDateTimeCard(context),
            const SizedBox(height: AppSpacing.md),

            // Description
            if (event.description?.isNotEmpty == true) ...[
              _buildDescriptionCard(context),
              const SizedBox(height: AppSpacing.md),
            ],

            // Location
            if (event.location?.isNotEmpty == true) ...[
              _buildLocationCard(context),
              const SizedBox(height: AppSpacing.md),
            ],

            // URL
            if (event.url?.isNotEmpty == true) ...[
              _buildUrlCard(context),
              const SizedBox(height: AppSpacing.md),
            ],

            // Attendees
            if (event.attendees.isNotEmpty) ...[
              _buildAttendeesCard(context),
              const SizedBox(height: AppSpacing.md),
            ],

            // Reminders
            if (event.reminders.isNotEmpty) ...[
              _buildRemindersCard(context),
              const SizedBox(height: AppSpacing.md),
            ],

            // Recurrence
            if (event.recurrenceRule != null) ...[
              _buildRecurrenceCard(context),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => CreateEditEventScreen(event: event),
            ),
          );
          if (result == true) {
            // Event was updated, refresh data
            ref.invalidate(eventsProvider);
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.allDay ? Icons.today : Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title ?? 'Untitled Event',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Date & Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (event.allDay) ...[
              if (event.start != null) ...[
                Row(
                  children: [
                    const Icon(Icons.today, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(event.start!),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const SizedBox(width: 28),
                    Text(
                      'All day event',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              if (event.start != null) ...[
                Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Start: ${DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(event.start!)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (event.end != null) ...[
                Row(
                  children: [
                    const Icon(Icons.stop, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'End: ${DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(event.end!)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
              if (event.start != null && event.end != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Duration: ${_formatDuration(event.end!.difference(event.start!))}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // Original start date for recurring events
            if (event.recurrenceRule != null &&
                event.originalStart != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.event_repeat,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Recurring Event',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Series started: ${DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(event.originalStart!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              event.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _launchMaps(event.location!),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.location!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _launchUrl(event.url!),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Link',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.url!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Attendees (${event.attendees.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...event.attendees.map(
              (attendee) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        (attendee.name?.isNotEmpty == true
                                ? attendee.name![0]
                                : attendee.email[0])
                            .toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attendee.name ?? attendee.email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (attendee.name != null)
                            Text(
                              attendee.email,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    _buildAttendeeStatusChip(context, attendee.status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeStatusChip(BuildContext context, AttendeeStatus status) {
    Color color;
    String text;

    switch (status) {
      case AttendeeStatus.accepted:
        color = Colors.green;
        text = 'Accepted';
        break;
      case AttendeeStatus.declined:
        color = Colors.red;
        text = 'Declined';
        break;
      case AttendeeStatus.tentative:
        color = Colors.orange;
        text = 'Tentative';
        break;
      case AttendeeStatus.pending:
        color = Colors.blue;
        text = 'Pending';
        break;
      case AttendeeStatus.unknown:
        color = Colors.grey;
        text = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...event.reminders.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text(reminder.description),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Recurrence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              event.recurrenceRule!.toString(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
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
        await api.deleteEvent(event.calendarId, event.eventId!);
        ref.invalidate(eventsProvider);

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete event: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedLocation',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'} $minutes minute${minutes == 1 ? '' : 's'}';
      }
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
  }
}
