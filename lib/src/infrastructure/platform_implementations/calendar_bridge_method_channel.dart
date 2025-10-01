import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Method channel implementation of the CalendarRepository
/// This class handles communication with the native platform code
@immutable
final class CalendarBridgeMethodChannel implements CalendarRepository {
  /// Constructor with optional custom MethodChanne
  const CalendarBridgeMethodChannel({MethodChannel? methodChannel})
      : _methodChannel = methodChannel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.ahmtydn/calendar_bridge';
  final MethodChannel _methodChannel;

  @override
  Future<bool> requestPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestPermissions',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<PermissionStatus> hasPermissions() async {
    try {
      final result =
          await _methodChannel.invokeMethod<String>('hasPermissions');
      return PermissionStatus.fromPlatformValue(result ?? 'notDetermined');
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<List<Calendar>> getCalendars() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'retrieveCalendars',
      );

      if (result == null) return [];

      return result
          .cast<Map<dynamic, dynamic>>()
          .map((json) => Calendar.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw PlatformBridgeException('Failed to parse calendars: $e');
    }
  }

  @override
  Future<List<CalendarEvent>> getEvents(
    String calendarId, {
    RetrieveEventsParams? params,
  }) async {
    try {
      final arguments = <String, dynamic>{
        'calendarId': calendarId,
        if (params != null) ...params.toJson(),
      };

      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'retrieveEvents',
        arguments,
      );

      if (result == null) return [];

      return result
          .cast<Map<dynamic, dynamic>>()
          .map(
            (json) => CalendarEvent.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw PlatformBridgeException('Failed to parse events: $e');
    }
  }

  @override
  Future<String> createEvent(CalendarEvent event) async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'createEvent',
        event.toJson(),
      );

      if (result == null || result.isEmpty) {
        throw const PlatformBridgeException(
          'Failed to create event: No ID returned',
        );
      }

      return result;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<String> updateEvent(CalendarEvent event) async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'updateEvent',
        event.toJson(),
      );

      if (result == null || result.isEmpty) {
        throw const PlatformBridgeException(
          'Failed to update event: No ID returned',
        );
      }

      return result;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('deleteEvent', {
        'calendarId': calendarId,
        'eventId': eventId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<Calendar> createCalendar(CreateCalendarParams params) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'createCalendar',
        params.toJson(),
      );

      if (result == null) {
        throw const PlatformBridgeException(
          'Failed to create calendar: No data returned',
        );
      }

      return Calendar.fromJson(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw PlatformBridgeException('Failed to parse calendar: $e');
    }
  }

  @override
  Future<bool> deleteCalendar(String calendarId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('deleteCalendar', {
        'calendarId': calendarId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<Map<String, int>?> getCalendarColors() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'retrieveCalendarColors',
      );

      if (result == null) return null;

      return Map<String, int>.from(result);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw PlatformBridgeException('Failed to parse calendar colors: $e');
    }
  }

  @override
  Future<Map<String, int>?> getEventColors(String calendarId) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'retrieveEventColors',
        {'calendarId': calendarId},
      );

      if (result == null) return null;

      return Map<String, int>.from(result);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw PlatformBridgeException('Failed to parse event colors: $e');
    }
  }

  @override
  Future<bool> updateCalendarColor(String calendarId, String colorKey) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'updateCalendarColor',
        {
          'calendarId': calendarId,
          'colorKey': colorKey,
        },
      );

      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> deleteEventInstance(
    String calendarId,
    String eventId,
    DateTime startDate, {
    bool followingInstances = false,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'deleteEventInstance',
        {
          'calendarId': calendarId,
          'eventId': eventId,
          'startDate': startDate.millisecondsSinceEpoch,
          'followingInstances': followingInstances,
        },
      );

      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Map platform exceptions to domain-specific exceptions
  CalendarBridgeException _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
        return PermissionDeniedException(e.message);
      case 'CALENDAR_NOT_FOUND':
        return CalendarNotFoundException(
          e.details?.toString() ?? 'Unknown calendar',
        );
      case 'EVENT_NOT_FOUND':
        return EventNotFoundException(e.details?.toString() ?? 'Unknown event');
      case 'INVALID_ARGUMENT':
        return InvalidArgumentException(
          e.message ?? 'Invalid argument',
          e.details?.toString(),
        );
      case 'UNSUPPORTED_OPERATION':
        return UnsupportedOperationException(
          e.message ?? 'Unsupported operation',
        );
      default:
        return PlatformBridgeException(
          e.message ?? 'Platform error',
          e.details?.toString(),
        );
    }
  }
}
