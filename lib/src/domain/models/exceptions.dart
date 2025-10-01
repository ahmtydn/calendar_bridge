import 'package:meta/meta.dart';

/// Base class for all calendar bridge exceptions
@immutable
sealed class CalendarBridgeException implements Exception {
  const CalendarBridgeException(this.message, [this.details]);

  /// The main error message
  final String message;

  /// Additional error details
  final String? details;

  @override
  String toString() => 'CalendarBridgeException: $message'
      '${details != null ? ' - $details' : ''}';
}

/// Thrown when calendar permissions are not granted
final class PermissionDeniedException extends CalendarBridgeException {
  /// Creates a permission denied exception
  const PermissionDeniedException([String? details])
      : super('Calendar permissions not granted', details);
}

/// Thrown when a requested calendar is not found
final class CalendarNotFoundException extends CalendarBridgeException {
  /// Creates a calendar not found exception
  const CalendarNotFoundException(String calendarId)
      : super('Calendar not found', calendarId);
}

/// Thrown when a requested event is not found
final class EventNotFoundException extends CalendarBridgeException {
  /// Creates an event not found exception
  const EventNotFoundException(String eventId)
      : super('Event not found', eventId);
}

/// Thrown when an invalid argument is provided
final class InvalidArgumentException extends CalendarBridgeException {
  /// Creates an invalid argument exception
  const InvalidArgumentException(String argument, [String? details])
      : super('Invalid argument: $argument', details);
}

/// Thrown when a platform-specific error occurs
final class PlatformBridgeException extends CalendarBridgeException {
  /// Creates a platform bridge exception
  const PlatformBridgeException(super.message, [super.details]);
}

/// Thrown when an operation is not supported on the current platform
final class UnsupportedOperationException extends CalendarBridgeException {
  /// Creates an unsupported operation exception
  const UnsupportedOperationException(String operation)
      : super('Operation not supported on this platform', operation);
}
