import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:calendar_bridge/src/domain/repositories/calendar_repository.dart';
import 'package:timezone/timezone.dart';

/// Use cases for event operations
/// This class encapsulates all event-related business logic
class EventUseCases {
  /// Constructor with required repository
  const EventUseCases(this._repository);

  final CalendarRepository _repository;

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
    TZDateTime? startDate,
    TZDateTime? endDate,
  }) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    final params = RetrieveEventsParams(
      startDate: startDate,
      endDate: endDate,
    );

    return _repository.getEvents(calendarId, params: params);
  }

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
  ) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    if (eventIds.isEmpty) {
      throw const InvalidArgumentException('Event IDs list cannot be empty');
    }

    // Check for empty strings in event IDs
    if (eventIds.any((id) => id.trim().isEmpty)) {
      throw const InvalidArgumentException(
        'Event IDs cannot contain empty strings',
      );
    }

    final params = RetrieveEventsParams(eventIds: eventIds);
    return _repository.getEvents(calendarId, params: params);
  }

  /// Get events for today
  ///
  /// [calendarId] - The ID of the calendar
  ///
  /// Returns a list of today's events
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<List<CalendarEvent>> getTodaysEvents(String calendarId) async {
    final now = TZDateTime.now(UTC);
    final startOfDay = TZDateTime(UTC, now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getEvents(
      calendarId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

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
  }) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    if (days <= 0) {
      throw const InvalidArgumentException('Days must be positive');
    }

    final now = TZDateTime.now(UTC);
    final endDate = now.add(Duration(days: days));

    final events = await getEvents(
      calendarId,
      startDate: now,
      endDate: endDate,
    );

    // Sort events by start time
    events.sort((a, b) {
      if (a.start == null && b.start == null) return 0;
      if (a.start == null) return 1;
      if (b.start == null) return -1;
      return a.start!.compareTo(b.start!);
    });

    return events;
  }

  /// Create a new event
  ///
  /// [event] - The event to create
  ///
  /// Returns the ID of the created event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  /// Throws [InvalidArgumentException] if the event is invalid
  Future<String> createEvent(CalendarEvent event) async {
    _validateEvent(event);
    return _repository.createEvent(event);
  }

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
    required TZDateTime start,
    required TZDateTime end,
    String? description,
    String? location,
  }) async {
    final event = CalendarEvent.create(
      calendarId: calendarId,
      title: title,
      start: start,
      end: end,
    ).copyWith(
      description: description,
      location: location,
    );

    return createEvent(event);
  }

  /// Update an existing event
  ///
  /// [event] - The event to update (must have eventId)
  ///
  /// Returns the ID of the updated event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  /// Throws [InvalidArgumentException] if the event is invalid
  Future<String> updateEvent(CalendarEvent event) async {
    if (event.eventId == null || event.eventId!.trim().isEmpty) {
      throw const InvalidArgumentException('Event ID is required for updates');
    }

    _validateEvent(event);
    return _repository.updateEvent(event);
  }

  /// Delete an event
  ///
  /// [calendarId] - The ID of the calendar
  /// [eventId] - The ID of the event to delete
  ///
  /// Returns true if the event was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    if (eventId.trim().isEmpty) {
      throw const InvalidArgumentException('Event ID cannot be empty');
    }

    return _repository.deleteEvent(calendarId, eventId);
  }

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
  }) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    if (eventId.trim().isEmpty) {
      throw const InvalidArgumentException('Event ID cannot be empty');
    }

    return _repository.deleteEventInstance(
      calendarId,
      eventId,
      startDate,
      followingInstances: followingInstances,
    );
  }

  /// Validate an event before creating or updating
  void _validateEvent(CalendarEvent event) {
    if (!event.isValid) {
      throw const InvalidArgumentException('Invalid event data');
    }

    if (event.calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    if (event.title?.trim().isEmpty ?? true) {
      throw const InvalidArgumentException('Event title cannot be empty');
    }

    if (event.start != null &&
        event.end != null &&
        event.start!.isAfter(event.end!)) {
      throw const InvalidArgumentException(
        'Event start time must be before end time',
      );
    }
  }
}
