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

/// Repository interface for calendar operations
/// This defines the contract for all calendar-related data operations
abstract interface class CalendarRepository {
  /// Request calendar permissions from the user
  /// Returns true if permissions are granted
  Future<bool> requestPermissions();

  /// Check the current status of calendar permissions
  /// Returns the permission status enum
  Future<PermissionStatus> hasPermissions();

  /// Retrieve all calendars available on the device
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<List<Calendar>> getCalendars();

  /// Retrieve events from a specific calendar
  ///
  /// [calendarId] - The ID of the calendar to retrieve events from
  /// [params] - Optional parameters to filter events
  ///
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<List<CalendarEvent>> getEvents(
    String calendarId, {
    RetrieveEventsParams? params,
  });

  /// Create a new event in the specified calendar
  ///
  /// [event] - The event to create
  ///
  /// Returns the ID of the created event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  /// Throws [InvalidArgumentException] if the event is invalid
  Future<String> createEvent(CalendarEvent event);

  /// Update an existing event
  ///
  /// [event] - The event to update (must have eventId)
  ///
  /// Returns the ID of the updated event
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  /// Throws [InvalidArgumentException] if the event is invalid
  Future<String> updateEvent(CalendarEvent event);

  /// Delete an event from a calendar
  ///
  /// [calendarId] - The ID of the calendar
  /// [eventId] - The ID of the event to delete
  ///
  /// Returns true if the event was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [EventNotFoundException] if the event doesn't exist
  Future<bool> deleteEvent(String calendarId, String eventId);

  /// Create a new calendar
  ///
  /// [params] - Parameters for the new calendar
  ///
  /// Returns the created calendar
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [InvalidArgumentException] if the parameters are invalid
  Future<Calendar> createCalendar(CreateCalendarParams params);

  /// Delete a calendar
  ///
  /// [calendarId] - The ID of the calendar to delete
  ///
  /// Returns true if the calendar was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<bool> deleteCalendar(String calendarId);

  /// Retrieve available calendar colors
  /// Returns a map of color keys to color values
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<Map<String, int>?> getCalendarColors();

  /// Retrieve available event colors for a specific calendar
  /// Returns a map of color keys to color values
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<Map<String, int>?> getEventColors(String calendarId);

  /// Update calendar color
  ///
  /// [calendarId] - The ID of the calendar to update
  /// [colorKey] - The color key to set
  ///
  /// Returns true if the color was successfully updated
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<bool> updateCalendarColor(String calendarId, String colorKey);

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
  });
}
