import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:calendar_bridge/src/domain/models/permission_status.dart';
import 'package:calendar_bridge/src/domain/repositories/calendar_repository.dart';

/// Use cases for calendar operations
/// This class encapsulates all calendar-related business logic
class CalendarUseCases {
  /// Constructor with required repository
  const CalendarUseCases(this._repository);

  final CalendarRepository _repository;

  /// Request permissions to access calendars
  ///
  /// Returns true if permissions are granted
  Future<bool> requestPermissions() async {
    return _repository.requestPermissions();
  }

  /// Check the current status of calendar permissions
  ///
  /// Returns the permission status
  Future<PermissionStatus> hasPermissions() async {
    return _repository.hasPermissions();
  }

  /// Get all available calendars
  ///
  /// Returns a list of calendars
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<List<Calendar>> getAllCalendars() async {
    return _repository.getCalendars();
  }

  /// Get calendars filtered by criteria
  ///
  /// [isReadOnly] - Filter by read-only status (null for no filter)
  /// [accountType] - Filter by account type (null for no filter)
  ///
  /// Returns a filtered list of calendars
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<List<Calendar>> getFilteredCalendars({
    bool? isReadOnly,
    String? accountType,
  }) async {
    final calendars = await _repository.getCalendars();

    return calendars.where((calendar) {
      if (isReadOnly != null && calendar.isReadOnly != isReadOnly) {
        return false;
      }
      if (accountType != null && calendar.accountType != accountType) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Get writable calendars only
  ///
  /// Returns a list of calendars that can be modified
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<List<Calendar>> getWritableCalendars() async {
    return getFilteredCalendars(isReadOnly: false);
  }

  /// Get the default calendar
  ///
  /// Returns the default calendar or the first writable calendar
  /// if no default is set
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if no writable calendar is found
  Future<Calendar> getDefaultCalendar() async {
    final calendars = await _repository.getCalendars();

    // First try to find a calendar marked as default
    final defaultCalendar = calendars.where((c) => c.isDefault).firstOrNull;
    if (defaultCalendar != null && !defaultCalendar.isReadOnly) {
      return defaultCalendar;
    }

    // Fall back to the first writable calendar
    final writableCalendars = calendars.where((c) => !c.isReadOnly);
    if (writableCalendars.isEmpty) {
      throw const CalendarNotFoundException('No writable calendar found');
    }

    return writableCalendars.first;
  }

  /// Create a new calendar
  ///
  /// [params] - Parameters for the new calendar
  ///
  /// Returns the created calendar
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [InvalidArgumentException] if the parameters are invalid
  Future<Calendar> createCalendar(CreateCalendarParams params) async {
    if (params.name.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar name cannot be empty');
    }

    return _repository.createCalendar(params);
  }

  /// Delete a calendar
  ///
  /// [calendarId] - The ID of the calendar to delete
  ///
  /// Returns true if the calendar was successfully deleted
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  /// Throws [InvalidArgumentException] if trying to delete a read-only calendar
  Future<bool> deleteCalendar(String calendarId) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    // Check if the calendar exists and is not read-only
    final calendars = await _repository.getCalendars();
    final calendar = calendars.where((c) => c.id == calendarId).firstOrNull;

    if (calendar == null) {
      throw CalendarNotFoundException(calendarId);
    }

    if (calendar.isReadOnly) {
      throw const InvalidArgumentException('Cannot delete read-only calendar');
    }

    return _repository.deleteCalendar(calendarId);
  }

  /// Get available calendar colors
  ///
  /// Returns a map of color names/keys to color values
  /// Throws [PermissionDeniedException] if permissions are not granted
  Future<Map<String, int>?> getCalendarColors() async {
    return _repository.getCalendarColors();
  }

  /// Get available event colors for a specific calendar
  ///
  /// [calendarId] - The ID of the calendar
  ///
  /// Returns a map of color names/keys to color values
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<Map<String, int>?> getEventColors(String calendarId) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }

    return _repository.getEventColors(calendarId);
  }

  /// Update the color of a calendar
  ///
  /// [calendarId] - The ID of the calendar to update
  /// [colorKey] - The color key to set
  ///
  /// Returns true if the color was successfully updated
  /// Throws [PermissionDeniedException] if permissions are not granted
  /// Throws [CalendarNotFoundException] if the calendar doesn't exist
  Future<bool> updateCalendarColor(String calendarId, String colorKey) async {
    if (calendarId.trim().isEmpty) {
      throw const InvalidArgumentException('Calendar ID cannot be empty');
    }
    if (colorKey.trim().isEmpty) {
      throw const InvalidArgumentException('Color key cannot be empty');
    }

    return _repository.updateCalendarColor(calendarId, colorKey);
  }
}

extension on Iterable<Calendar> {
  Calendar? get firstOrNull => isEmpty ? null : first;
}
