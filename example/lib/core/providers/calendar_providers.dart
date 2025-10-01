import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the CalendarBridge instance
final calendarBridgeProvider = Provider<CalendarBridge>((ref) {
  return CalendarBridge();
});

/// Provider for calendar permissions status
final permissionsProvider = FutureProvider<bool>((ref) async {
  final api = ref.read(calendarBridgeProvider);
  final status = await api.hasPermissions();
  return status.isGranted;
});

/// Provider to request permissions
final requestPermissionsProvider = FutureProvider.family<bool, void>((
  ref,
  _,
) async {
  final api = ref.read(calendarBridgeProvider);
  return await api.requestPermissions();
});

/// Provider for all calendars
final calendarsProvider = FutureProvider<List<Calendar>>((ref) async {
  final api = ref.read(calendarBridgeProvider);
  return await api.getCalendars();
});

/// Provider for writable calendars only
final writableCalendarsProvider = FutureProvider<List<Calendar>>((ref) async {
  final api = ref.read(calendarBridgeProvider);
  return await api.getWritableCalendars();
});

/// Provider for the default calendar
final defaultCalendarProvider = FutureProvider<Calendar?>((ref) async {
  try {
    final api = ref.read(calendarBridgeProvider);
    return await api.getDefaultCalendar();
  } catch (e) {
    return null;
  }
});

/// Provider for events from a specific calendar
final eventsProvider = FutureProvider.family<List<CalendarEvent>, EventsParams>(
  (ref, params) async {
    final api = ref.read(calendarBridgeProvider);

    // Check permissions first
    final hasPermissions = await api.hasPermissions();
    if (!hasPermissions.isGranted) {
      throw Exception('Calendar permissions not granted');
    }

    return await api.getEvents(
      params.calendarId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);

/// Provider for today's events from a specific calendar
final todaysEventsProvider = FutureProvider.family<List<CalendarEvent>, String>(
  (ref, calendarId) async {
    final api = ref.read(calendarBridgeProvider);
    return await api.getTodaysEvents(calendarId);
  },
);

/// Provider for upcoming events from a specific calendar
final upcomingEventsProvider =
    FutureProvider.family<List<CalendarEvent>, UpcomingEventsParams>((
      ref,
      params,
    ) async {
      final api = ref.read(calendarBridgeProvider);
      return await api.getUpcomingEvents(params.calendarId, days: params.days);
    });

/// Parameters for events provider
class EventsParams {
  final String calendarId;
  final DateTime? startDate;
  final DateTime? endDate;

  const EventsParams({required this.calendarId, this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventsParams &&
          runtimeType == other.runtimeType &&
          calendarId == other.calendarId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      calendarId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

/// Parameters for upcoming events provider
class UpcomingEventsParams {
  final String calendarId;
  final int days;

  const UpcomingEventsParams({required this.calendarId, this.days = 7});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpcomingEventsParams &&
          runtimeType == other.runtimeType &&
          calendarId == other.calendarId &&
          days == other.days;

  @override
  int get hashCode => calendarId.hashCode ^ days.hashCode;
}
