import 'package:calendar_bridge/calendar_bridge.dart'
    show
        CalendarNotFoundException,
        EventNotFoundException,
        InvalidArgumentException,
        PermissionDeniedException;
import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart'
    show
        CalendarNotFoundException,
        EventNotFoundException,
        InvalidArgumentException,
        PermissionDeniedException;
import 'package:calendar_bridge/src/domain/models/permission_status.dart';
import 'package:calendar_bridge/src/domain/repositories/calendar_repository.dart';
import 'package:calendar_bridge/src/domain/use_cases/calendar_use_cases.dart';
import 'package:calendar_bridge/src/domain/use_cases/event_use_cases.dart';
import 'package:calendar_bridge/src/infrastructure/platform_implementations/calendar_bridge_method_channel.dart';
import 'package:timezone/timezone.dart';

/// Main API class for Calendar Bridge plugin
///
/// This class provides a clean, simple interface for all calendar operations
/// using dependency injection and clean architecture principles.
class CalendarBridge {
  /// Default constructor using method channel implementation
  CalendarBridge() : this._(repository: const CalendarBridgeMethodChannel());

  /// Create a custom instance with a specific repository
  /// This is useful for testing or custom implementations
  factory CalendarBridge.custom({
    required CalendarRepository repository,
  }) {
    return CalendarBridge._(repository: repository);
  }
  CalendarBridge._({
    required CalendarRepository repository,
  })  : _calendarUseCases = CalendarUseCases(repository),
        _eventUseCases = EventUseCases(repository);

  final CalendarUseCases _calendarUseCases;
  final EventUseCases _eventUseCases;

  // Calendar Operations

  /// Request calendar permissions from the user
  /// Returns true if permissions are granted
  Future<bool> requestPermissions() => _calendarUseCases.requestPermissions();

  /// Check the current status of calendar permissions
  /// Returns the permission status
  Future<PermissionStatus> hasPermissions() =>
      _calendarUseCases.hasPermissions();

  /// Get all available calendars
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<List<Calendar>> getCalendars() => _calendarUseCases.getAllCalendars();

  /// Get writable calendars only
  /// Returns a list of calendars that can be modified
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<List<Calendar>> getWritableCalendars() =>
      _calendarUseCases.getWritableCalendars();

  /// Get the default calendar
  /// Returns the default calendar or the first writable calendar
  /// if no default is set
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if no writable calendar is found
  Future<Calendar> getDefaultCalendar() =>
      _calendarUseCases.getDefaultCalendar();

  /// Create a new calendar
  ///
  /// [name] - Name of the new calendar
  /// [color] - Optional color for the calendar
  /// [localAccountName] - Optional local account name
  ///
  /// Returns the created calendar
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [InvalidArgumentException] if the parameters are invalid
  Future<Calendar> createCalendar({
    required String name,
    int? color,
    String? localAccountName,
  }) {
    final params = CreateCalendarParams(
      name: name,
      color: color,
      localAccountName: localAccountName,
    );
    return _calendarUseCases.createCalendar(params);
  }

  /// Delete a calendar
  ///
  /// [calendarId] - The ID of the calendar to delete
  ///
  /// Returns true if the calendar was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  /// Throws [InvalidArgumentException] if trying to delete a read-only calendar
  Future<bool> deleteCalendar(String calendarId) =>
      _calendarUseCases.deleteCalendar(calendarId);

  // Event Operations

  /// Get events from a calendar within a date range
  ///
  /// [calendarId] - The ID of the calendar
  /// [startDate] - Start of the date range (optional)
  /// [endDate] - End of the date range (optional)
  ///
  /// Returns a list of events
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<List<CalendarEvent>> getEvents(
    String calendarId, {
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _eventUseCases.getEvents(
        calendarId,
        startDate: startDate != null ? TZDateTime.from(startDate, UTC) : null,
        endDate: endDate != null ? TZDateTime.from(endDate, UTC) : null,
      );

  /// Get specific events by their IDs
  ///
  /// [calendarId] - The ID of the calendar
  /// [eventIds] - List of event IDs to retrieve
  ///
  /// Returns a list of events
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<List<CalendarEvent>> getEventsByIds(
    String calendarId,
    List<String> eventIds,
  ) =>
      _eventUseCases.getEventsByIds(calendarId, eventIds);

  /// Get events for today
  ///
  /// [calendarId] - The ID of the calendar
  ///
  /// Returns a list of today's events
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<List<CalendarEvent>> getTodaysEvents(String calendarId) =>
      _eventUseCases.getTodaysEvents(calendarId);

  /// Get upcoming events within a specified number of days
  ///
  /// [calendarId] - The ID of the calendar
  /// [days] - Number of days to look ahead (default: 7)
  ///
  /// Returns a list of upcoming events
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<List<CalendarEvent>> getUpcomingEvents(
    String calendarId, {
    int days = 7,
  }) =>
      _eventUseCases.getUpcomingEvents(calendarId, days: days);

  /// Create a new event
  ///
  /// [event] - The event to create
  ///
  /// Returns the ID of the created event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  /// Throws [InvalidArgumentException] if the event is invalid
  Future<String> createEvent(CalendarEvent event) =>
      _eventUseCases.createEvent(event);

  /// Create a simple event with just the basics
  ///
  /// [calendarId] - The ID of the calendar
  /// [title] - Title of the event
  /// [start] - Start time
  /// [end] - End time
  /// [description] - Optional description
  /// [location] - Optional location
  ///
  /// Returns the ID of the created event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  /// Throws [InvalidArgumentException] if the parameters are invalid
  Future<String> createSimpleEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) =>
      _eventUseCases.createSimpleEvent(
        calendarId: calendarId,
        title: title,
        start: TZDateTime.from(start, UTC),
        end: TZDateTime.from(end, UTC),
        description: description,
        location: location,
      );

  /// Update an existing event
  ///
  /// [event] - The event to update (must have eventId)
  ///
  /// Returns the ID of the updated event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  /// Throws [InvalidArgumentException] if the event is invalid
  Future<String> updateEvent(CalendarEvent event) =>
      _eventUseCases.updateEvent(event);

  /// Delete an event
  ///
  /// [calendarId] - The ID of the calendar
  /// [eventId] - The ID of the event to delete
  ///
  /// Returns true if the event was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  Future<bool> deleteEvent(String calendarId, String eventId) =>
      _eventUseCases.deleteEvent(calendarId, eventId);

  /// Delete a specific instance of a recurring event
  ///
  /// [calendarId] - The ID of the calendar
  /// [eventId] - The ID of the event
  /// [startDate] - The start date of the specific instance to delete
  /// [followingInstances] - Whether to delete following instances as well
  ///
  /// Returns true if the event instance was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  Future<bool> deleteEventInstance(
    String calendarId,
    String eventId,
    DateTime startDate, {
    bool followingInstances = false,
  }) =>
      _eventUseCases.deleteEventInstance(
        calendarId,
        eventId,
        startDate,
        followingInstances: followingInstances,
      );

  // Calendar Color Operations

  /// Get available calendar colors
  /// Returns a map of color names/keys to color values
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<Map<String, int>?> getCalendarColors() =>
      _calendarUseCases.getCalendarColors();

  /// Get available event colors for a specific calendar
  /// Returns a map of color names/keys to color values
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<Map<String, int>?> getEventColors(String calendarId) =>
      _calendarUseCases.getEventColors(calendarId);

  /// Update the color of a calendar
  ///
  /// [calendarId] - The ID of the calendar to update
  /// [colorKey] - The color key to set
  ///
  /// Returns true if the color was successfully updated
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<bool> updateCalendarColor(String calendarId, String colorKey) =>
      _calendarUseCases.updateCalendarColor(calendarId, colorKey);
}
