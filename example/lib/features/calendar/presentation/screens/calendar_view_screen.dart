import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/calendar_permission_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/event_card.dart';
import '../widgets/loading_widget.dart';
import 'event_details_screen.dart';

class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedCalendarId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: CalendarPermissionWidget(
        child: _selectedCalendarId == null
            ? _buildCalendarSelector()
            : _buildCalendarView(),
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
                'Select a calendar to view',
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

  Widget _buildCalendarView() {
    if (_selectedCalendarId == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, 1);
    final endDate = DateTime(now.year, now.month + 2, 0);

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
              return Column(
                children: [
                  // Calendar widget
                  TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) {
                      return events.where((event) {
                        if (event.start == null) return false;
                        return isSameDay(event.start!, day);
                      }).toList();
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(),
                  // Events for selected day
                  Expanded(child: _buildEventsList(events)),
                ],
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

  Widget _buildEventsList(List<CalendarEvent> allEvents) {
    final selectedDayEvents = allEvents.where((event) {
      if (event.start == null) return false;
      return isSameDay(event.start!, _selectedDay);
    }).toList();

    if (selectedDayEvents.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy,
        title: 'No Events',
        message:
            'No events scheduled for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
      );
    }

    return ListView.builder(
      itemCount: selectedDayEvents.length,
      itemBuilder: (context, index) {
        final event = selectedDayEvents[index];
        return EventCard(
          event: event,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventDetailsScreen(event: event),
              ),
            );
          },
        );
      },
    );
  }
}
