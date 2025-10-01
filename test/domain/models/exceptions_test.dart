import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarBridgeException Tests', () {
    group('Base Exception Tests', () {
      test('should create CalendarBridgeException implementations correctly',
          () {
        // Since CalendarBridgeException is sealed, we test
        //through its implementations
        const permissionException = PermissionDeniedException();
        const calendarNotFoundException = CalendarNotFoundException('cal_123');
        const eventNotFoundException = EventNotFoundException('event_456');
        const invalidArgumentException =
            InvalidArgumentException('invalid_param');
        const platformException = PlatformBridgeException('Platform error');

        expect(permissionException, isA<CalendarBridgeException>());
        expect(calendarNotFoundException, isA<CalendarBridgeException>());
        expect(eventNotFoundException, isA<CalendarBridgeException>());
        expect(invalidArgumentException, isA<CalendarBridgeException>());
        expect(platformException, isA<CalendarBridgeException>());
      });
    });

    group('PermissionDeniedException Tests', () {
      test('should create exception with default message', () {
        const exception = PermissionDeniedException();

        expect(exception.message, equals('Calendar permissions not granted'));
        expect(exception.details, isNull);
      });

      test('should create exception with details', () {
        const details = 'User denied calendar access';
        const exception = PermissionDeniedException(details);

        expect(exception.message, equals('Calendar permissions not granted'));
        expect(exception.details, equals(details));
      });

      test('should provide correct toString representation', () {
        const exception = PermissionDeniedException();
        final stringRep = exception.toString();

        expect(stringRep, contains('CalendarBridgeException'));
        expect(stringRep, contains('Calendar permissions not granted'));
      });

      test('should provide toString with details', () {
        const details = 'User denied access';
        const exception = PermissionDeniedException(details);
        final stringRep = exception.toString();

        expect(stringRep, contains('Calendar permissions not granted'));
        expect(stringRep, contains(details));
      });
    });

    group('CalendarNotFoundException Tests', () {
      test('should create exception with calendar ID', () {
        const calendarId = 'calendar_123';
        const exception = CalendarNotFoundException(calendarId);

        expect(exception.message, equals('Calendar not found'));
        expect(exception.details, equals(calendarId));
      });

      test('should provide correct toString representation', () {
        const calendarId = 'calendar_123';
        const exception = CalendarNotFoundException(calendarId);
        final stringRep = exception.toString();

        expect(stringRep, contains('CalendarBridgeException'));
        expect(stringRep, contains('Calendar not found'));
        expect(stringRep, contains(calendarId));
      });

      test('should handle empty calendar ID', () {
        const exception = CalendarNotFoundException('');

        expect(exception.message, equals('Calendar not found'));
        expect(exception.details, equals(''));
      });

      test('should handle special characters in calendar ID', () {
        const calendarId = 'cal@#\$%^&*(){}[]|\\:";\'<>?,./-_+=`~';
        const exception = CalendarNotFoundException(calendarId);

        expect(exception.details, equals(calendarId));
      });
    });

    group('EventNotFoundException Tests', () {
      test('should create exception with event ID', () {
        const eventId = 'event_456';
        const exception = EventNotFoundException(eventId);

        expect(exception.message, equals('Event not found'));
        expect(exception.details, equals(eventId));
      });

      test('should provide correct toString representation', () {
        const eventId = 'event_456';
        const exception = EventNotFoundException(eventId);
        final stringRep = exception.toString();

        expect(stringRep, contains('CalendarBridgeException'));
        expect(stringRep, contains('Event not found'));
        expect(stringRep, contains(eventId));
      });

      test('should handle empty event ID', () {
        const exception = EventNotFoundException('');

        expect(exception.message, equals('Event not found'));
        expect(exception.details, equals(''));
      });

      test('should handle special characters in event ID', () {
        const eventId = 'event@#\$%^&*(){}[]|\\:";\'<>?,./-_+=`~';
        const exception = EventNotFoundException(eventId);

        expect(exception.details, equals(eventId));
      });
    });

    group('InvalidArgumentException Tests', () {
      test('should create exception with argument name only', () {
        const argument = 'startDate';
        const exception = InvalidArgumentException(argument);

        expect(exception.message, equals('Invalid argument: startDate'));
        expect(exception.details, isNull);
      });

      test('should create exception with argument name and details', () {
        const argument = 'startDate';
        const details = 'Start date cannot be after end date';
        const exception = InvalidArgumentException(argument, details);

        expect(exception.message, equals('Invalid argument: startDate'));
        expect(exception.details, equals(details));
      });

      test('should provide correct toString representation', () {
        const argument = 'calendarId';
        const exception = InvalidArgumentException(argument);
        final stringRep = exception.toString();

        expect(stringRep, contains('CalendarBridgeException'));
        expect(stringRep, contains('Invalid argument: calendarId'));
      });

      test('should provide toString with details', () {
        const argument = 'eventId';
        const details = 'Event ID cannot be empty';
        const exception = InvalidArgumentException(argument, details);
        final stringRep = exception.toString();

        expect(stringRep, contains('Invalid argument: eventId'));
        expect(stringRep, contains(details));
      });

      test('should handle empty argument name', () {
        const exception = InvalidArgumentException('');

        expect(exception.message, equals('Invalid argument: '));
        expect(exception.details, isNull);
      });

      test('should handle special characters in argument name', () {
        const argument = r'param@#$%';
        const exception = InvalidArgumentException(argument);

        expect(exception.message, contains(argument));
      });
    });

    group('PlatformBridgeException Tests', () {
      test('should create exception with message only', () {
        const message = 'Native platform error';
        const exception = PlatformBridgeException(message);

        expect(exception.message, equals(message));
        expect(exception.details, isNull);
      });

      test('should create exception with message and details', () {
        const message = 'Calendar access failed';
        const details = 'iOS calendar permission denied by system';
        const exception = PlatformBridgeException(message, details);

        expect(exception.message, equals(message));
        expect(exception.details, equals(details));
      });

      test('should provide correct toString representation', () {
        const message = 'Platform error occurred';
        const exception = PlatformBridgeException(message);
        final stringRep = exception.toString();

        expect(stringRep, contains('CalendarBridgeException'));
        expect(stringRep, contains(message));
      });

      test('should provide toString with details', () {
        const message = 'Network error';
        const details = 'Failed to sync with calendar service';
        const exception = PlatformBridgeException(message, details);
        final stringRep = exception.toString();

        expect(stringRep, contains(message));
        expect(stringRep, contains(details));
      });

      test('should handle empty message', () {
        const exception = PlatformBridgeException('');

        expect(exception.message, equals(''));
        expect(exception.details, isNull);
      });
    });

    group('Exception Hierarchy Tests', () {
      test('all exceptions should implement Exception', () {
        const permissionException = PermissionDeniedException();
        const calendarNotFoundException = CalendarNotFoundException('cal_123');
        const eventNotFoundException = EventNotFoundException('event_456');
        const invalidArgumentException = InvalidArgumentException('param');
        const platformException = PlatformBridgeException('error');

        expect(permissionException, isA<Exception>());
        expect(calendarNotFoundException, isA<Exception>());
        expect(eventNotFoundException, isA<Exception>());
        expect(invalidArgumentException, isA<Exception>());
        expect(platformException, isA<Exception>());
      });

      test('all exceptions should be immutable', () {
        const permissionException = PermissionDeniedException('details');
        const calendarNotFoundException = CalendarNotFoundException('cal_123');
        const eventNotFoundException = EventNotFoundException('event_456');
        const invalidArgumentException =
            InvalidArgumentException('param', 'details');
        const platformException = PlatformBridgeException('error', 'details');

        // Test that fields are final (immutable)
        expect(
          permissionException.message,
          equals('Calendar permissions not granted'),
        );
        expect(permissionException.details, equals('details'));

        expect(calendarNotFoundException.message, equals('Calendar not found'));
        expect(calendarNotFoundException.details, equals('cal_123'));

        expect(eventNotFoundException.message, equals('Event not found'));
        expect(eventNotFoundException.details, equals('event_456'));

        expect(
          invalidArgumentException.message,
          equals('Invalid argument: param'),
        );
        expect(invalidArgumentException.details, equals('details'));

        expect(platformException.message, equals('error'));
        expect(platformException.details, equals('details'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long messages and details', () {
        final longMessage = 'A' * 1000;
        final longDetails = 'B' * 1000;
        final exception = PlatformBridgeException(longMessage, longDetails);

        expect(exception.message, equals(longMessage));
        expect(exception.details, equals(longDetails));
      });

      test('should handle unicode characters', () {
        const message = 'Erreur de calendrier 📅';
        const details = "Échec de l'accès au calendrier";
        const exception = PlatformBridgeException(message, details);

        expect(exception.message, equals(message));
        expect(exception.details, equals(details));
      });

      test('should handle null details gracefully', () {
        const exception1 = PermissionDeniedException();
        const exception2 = InvalidArgumentException('param');
        const exception3 = PlatformBridgeException('error');

        expect(exception1.details, isNull);
        expect(exception2.details, isNull);
        expect(exception3.details, isNull);

        // toString should not throw with null details
        expect(() => exception1.toString(), returnsNormally);
        expect(() => exception2.toString(), returnsNormally);
        expect(() => exception3.toString(), returnsNormally);
      });
    });
  });
}
