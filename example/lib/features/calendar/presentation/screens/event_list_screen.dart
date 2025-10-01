import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/calendar_permission_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/event_card.dart';
import '../widgets/loading_widget.dart';
import 'create_edit_event_screen.dart';
import 'event_details_screen.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  String? _selectedCalendarId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => CreateEditEventScreen(
                    initialCalendarId: _selectedCalendarId,
                  ),
                ),
              );
              if (result == true) {
                // Refresh events
                ref.invalidate(eventsProvider);
              }
            },
          ),
        ],
      ),
      body: CalendarPermissionWidget(
        child: _selectedCalendarId == null
            ? _buildCalendarSelector()
            : _buildEventsList(),
      ),
    );
  }

  Widget _buildCalendarSelector() {
    final calendarsAsync = ref.watch(calendarsProvider);

    return calendarsAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.calendar_today,
            title: 'No Calendars',
            message: 'Create a calendar first to view events.',
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Select a calendar to view events',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
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
                      title: Text(calendar.name),
                      subtitle: Text(
                        calendar.accountName ?? 'Local Calendar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Icon(
                        calendar.isReadOnly ? Icons.visibility : Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCalendarId = calendar.id;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => AppErrorWidget(
        error: error,
        onRetry: () => ref.invalidate(calendarsProvider),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedCalendarId == null) return const SizedBox.shrink();

    // Create stable dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 30));
    final endDate = today.add(const Duration(days: 365));

    final eventsAsync = ref.watch(
      eventsProvider(
        EventsParams(
          calendarId: _selectedCalendarId!,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    return Column(
      children: [
        // Calendar selector header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedCalendarId = null;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final calendarsAsync = ref.watch(calendarsProvider);
                    return calendarsAsync.maybeWhen(
                      data: (calendars) {
                        final selectedCalendar = calendars.firstWhere(
                          (cal) => cal.id == _selectedCalendarId,
                          orElse: () => calendars.first,
                        );
                        return Text(
                          selectedCalendar.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.event_busy,
                  title: 'No Events',
                  message: 'Create your first event to get started.',
                );
              }

              // Group events by date
              final Map<String, List<CalendarEvent>> groupedEvents = {};
              for (final event in events) {
                if (event.start != null) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(event.start!);
                  groupedEvents.putIfAbsent(dateKey, () => []).add(event);
                }
              }

              final sortedKeys = groupedEvents.keys.toList()..sort();

              return ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedKeys[index];
                  final dateEvents = groupedEvents[dateKey]!;
                  final date = DateTime.parse(dateKey);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        child: Text(
                          _formatDateHeader(date),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Events for this date
                      ...dateEvents.map(
                        (event) => EventCard(
                          event: event,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    EventDetailsScreen(event: event),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const LoadingWidget(),
            error: (error, stack) => AppErrorWidget(
              error: error,
              onRetry: () => ref.invalidate(
                eventsProvider(
                  EventsParams(
                    calendarId: _selectedCalendarId!,
                    startDate: startDate,
                    endDate: endDate,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today, ${DateFormat('MMMM d').format(date)}';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${DateFormat('MMMM d').format(date)}';
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('MMMM d').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMMM d').format(date);
    } else {
      return DateFormat('EEEE, MMMM d, y').format(date);
    }
  }
}
