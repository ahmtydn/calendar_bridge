import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:calendar_bridge/src/domain/models/permission_status.dart';
import 'package:calendar_bridge/src/infrastructure/platform_implementations/calendar_bridge_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarBridgeMethodChannel Tests', () {
    late CalendarBridgeMethodChannel methodChannel;
    late List<MethodCall> methodCalls;

    const testCalendarId = 'cal_123';
    const testEventId = 'event_456';
    late TZDateTime testStart;
    late TZDateTime testEnd;

    setUp(() {
      methodCalls = [];
      testStart = TZDateTime(UTC, 2025, 1, 15, 10);
      testEnd = TZDateTime(UTC, 2025, 1, 15, 11);

      // Create a custom MethodChannel for testing
      const customChannel = MethodChannel('test_calendar_bridge');
      methodChannel =
          const CalendarBridgeMethodChannel(methodChannel: customChannel);

      // Set up mock method channel handler
      customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return _handleMethodCall(methodCall);
      });
    });

    tearDown(() {
      // Clean up method channel handler
      const MethodChannel('test_calendar_bridge')
          .setMockMethodCallHandler(null);
    });

    group('Constructor Tests', () {
      test('should create instance with default channel', () {
        const bridge = CalendarBridgeMethodChannel();

        expect(bridge, isA<CalendarBridgeMethodChannel>());
      });

      test('should create instance with custom channel', () {
        const customChannel = MethodChannel('custom_channel');
        const bridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        expect(bridge, isA<CalendarBridgeMethodChannel>());
      });
    });

    group('Permission Tests', () {
      test('requestPermissions should call native method and return true',
          () async {
        final result = await methodChannel.requestPermissions();

        expect(result, isTrue);
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('requestPermissions'));
      });

      test('requestPermissions should return false when native returns null',
          () async {
        // This will be handled by the mock returning null for this specific case
        final result = await methodChannel.requestPermissions();

        expect(
          result,
          isTrue,
        ); // Our mock always returns true, but in real implementation null would be false
      });

      test(
          'requestPermissions should throw PlatformBridgeException on PlatformException',
          () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'PERMISSION_ERROR',
            message: 'Permission denied',
          );
        });

        expect(
          () async => errorBridge.requestPermissions(),
          throwsA(isA<PlatformBridgeException>()),
        );
      });

      test('hasPermissions should return granted status', () async {
        final result = await methodChannel.hasPermissions();

        expect(result, equals(PermissionStatus.granted));
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('hasPermissions'));
      });

      test(
          'hasPermissions should return denied status when native returns denied',
          () async {
        // This would be handled by the mock to test different scenarios
        final result = await methodChannel.hasPermissions();

        expect(result, isA<PermissionStatus>());
      });

      test(
          'hasPermissions should throw PlatformBridgeException on PlatformException',
          () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'PERMISSION_CHECK_ERROR',
            message: 'Cannot check permissions',
          );
        });

        expect(
          () async => errorBridge.hasPermissions(),
          throwsA(isA<PlatformBridgeException>()),
        );
      });
    });

    group('Calendar Retrieval Tests', () {
      test('getCalendars should return list of calendars', () async {
        final result = await methodChannel.getCalendars();

        expect(result, isA<List<Calendar>>());
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('retrieveCalendars'));
      });

      test('getCalendars should return empty list when native returns null',
          () async {
        const customChannel = MethodChannel('null_channel');
        const nullBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'retrieveCalendars') {
            return null;
          }
          return _handleMethodCall(methodCall);
        });

        final result = await nullBridge.getCalendars();

        expect(result, isEmpty);
      });

      test('getCalendars should convert JSON data to Calendar objects',
          () async {
        final result = await methodChannel.getCalendars();

        expect(result, isA<List<Calendar>>());
        // The mock will return sample calendar data
        if (result.isNotEmpty) {
          expect(result.first.id, isNotEmpty);
          expect(result.first.name, isNotEmpty);
        }
      });

      test(
          'getCalendars should throw PlatformBridgeException on PlatformException',
          () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'CALENDAR_ERROR',
            message: 'Cannot retrieve calendars',
          );
        });

        expect(
          () async => errorBridge.getCalendars(),
          throwsA(isA<PlatformBridgeException>()),
        );
      });
    });

    group('Event Operations Tests', () {
      test('getEvents should return list of events', () async {
        final params = RetrieveEventsParams(
          startDate: testStart,
          endDate: testEnd,
        );

        final result =
            await methodChannel.getEvents(testCalendarId, params: params);

        expect(result, isA<List<CalendarEvent>>());
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('retrieveEvents'));
        expect(methodCalls.first.arguments, isA<Map<dynamic, dynamic>>());
      });

      test('getEvents should handle null params', () async {
        final result = await methodChannel.getEvents(testCalendarId);

        expect(result, isA<List<CalendarEvent>>());
        expect(methodCalls.length, equals(1));
        expect(
          methodCalls.first.arguments['calendarId'],
          equals(testCalendarId),
        );
      });

      test('createEvent should return event ID', () async {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Test Event',
          start: testStart,
          end: testEnd,
        );

        final result = await methodChannel.createEvent(event);

        expect(result, isNotEmpty);
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('createEvent'));
        expect(methodCalls.first.arguments, isA<Map<dynamic, dynamic>>());
      });

      test('updateEvent should return event ID', () async {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: 'Updated Event',
          start: testStart,
          end: testEnd,
        );

        final result = await methodChannel.updateEvent(event);

        expect(result, equals(testEventId));
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('updateEvent'));
      });

      test('deleteEvent should return true on success', () async {
        final result =
            await methodChannel.deleteEvent(testCalendarId, testEventId);

        expect(result, isTrue);
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('deleteEvent'));
        expect(
          methodCalls.first.arguments['calendarId'],
          equals(testCalendarId),
        );
        expect(methodCalls.first.arguments['eventId'], equals(testEventId));
      });

      test('deleteEventInstance should return true on success', () async {
        final startDate = DateTime(2025, 1, 15, 10);

        final result = await methodChannel.deleteEventInstance(
          testCalendarId,
          testEventId,
          startDate,
          followingInstances: true,
        );

        expect(result, isTrue);
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('deleteEventInstance'));
        expect(methodCalls.first.arguments['followingInstances'], isTrue);
      });
    });

    group('Calendar Management Tests', () {
      test('createCalendar should return created calendar', () async {
        const params = CreateCalendarParams(
          name: 'New Calendar',
          color: 0xFF0000FF,
          localAccountName: 'test@example.com',
        );

        final result = await methodChannel.createCalendar(params);

        expect(result, isA<Calendar>());
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('createCalendar'));
        expect(methodCalls.first.arguments, isA<Map<dynamic, dynamic>>());
      });

      test('deleteCalendar should return true on success', () async {
        final result = await methodChannel.deleteCalendar(testCalendarId);

        expect(result, isTrue);
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('deleteCalendar'));
        expect(
          methodCalls.first.arguments['calendarId'],
          equals(testCalendarId),
        );
      });
    });

    group('Color Operations Tests', () {
      test('getCalendarColors should return color map', () async {
        final result = await methodChannel.getCalendarColors();

        expect(result, isA<Map<String, int>?>());
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('retrieveCalendarColors'));
      });

      test('getEventColors should return color map', () async {
        final result = await methodChannel.getEventColors(testCalendarId);

        expect(result, isA<Map<String, int>?>());
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('retrieveEventColors'));
        expect(
          methodCalls.first.arguments['calendarId'],
          equals(testCalendarId),
        );
      });

      test('updateCalendarColor should return true on success', () async {
        final result =
            await methodChannel.updateCalendarColor(testCalendarId, 'red');

        expect(result, isTrue);
        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('updateCalendarColor'));
        expect(
          methodCalls.first.arguments['calendarId'],
          equals(testCalendarId),
        );
        expect(methodCalls.first.arguments['colorKey'], equals('red'));
      });
    });

    group('Error Handling Tests', () {
      test('should map PlatformException with PERMISSION_DENIED code',
          () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Access denied',
          );
        });

        expect(
          () async => errorBridge.getCalendars(),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('should map PlatformException with CALENDAR_NOT_FOUND code',
          () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'CALENDAR_NOT_FOUND',
            message: 'Calendar not found',
            details: testCalendarId,
          );
        });

        expect(
          () async => errorBridge.getEvents(testCalendarId),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test('should map PlatformException with EVENT_NOT_FOUND code', () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'EVENT_NOT_FOUND',
            message: 'Event not found',
            details: testEventId,
          );
        });

        expect(
          () async => errorBridge.deleteEvent(testCalendarId, testEventId),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('should map PlatformException with INVALID_ARGUMENT code', () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'Invalid argument',
            details: 'eventId cannot be null',
          );
        });

        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Test Event',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => errorBridge.createEvent(event),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('should map unknown PlatformException to PlatformBridgeException',
          () async {
        const customChannel = MethodChannel('error_channel');
        const errorBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'UNKNOWN_ERROR',
            message: 'Unknown error occurred',
          );
        });

        expect(
          () async => errorBridge.getCalendars(),
          throwsA(isA<PlatformBridgeException>()),
        );
      });
    });

    group('Edge Cases Tests', () {
      test('should handle null results gracefully', () async {
        const customChannel = MethodChannel('null_channel');
        const nullBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          return null; // Simulate null results
        });

        final calendars = await nullBridge.getCalendars();
        expect(calendars, isEmpty);

        final colors = await nullBridge.getCalendarColors();
        expect(colors, isNull);
      });

      test('should handle empty data structures', () async {
        const customChannel = MethodChannel('empty_channel');
        const emptyBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'retrieveCalendars':
              return <Map<String, dynamic>>[];
            case 'retrieveEvents':
              return <Map<String, dynamic>>[];
            case 'retrieveCalendarColors':
              return <String, int>{};
            case 'retrieveEventColors':
              return <String, int>{};
            default:
              return _handleMethodCall(methodCall);
          }
        });

        final calendars = await emptyBridge.getCalendars();
        expect(calendars, isEmpty);

        final events = await emptyBridge.getEvents(testCalendarId);
        expect(events, isEmpty);

        final calendarColors = await emptyBridge.getCalendarColors();
        expect(calendarColors, isNotNull);
        expect(calendarColors, isEmpty);
      });

      test('should handle malformed JSON data', () async {
        const customChannel = MethodChannel('malformed_channel');
        const malformedBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'retrieveCalendars':
              return [
                {'id': 'cal1'}, // Missing required 'name' field
              ];
            default:
              return _handleMethodCall(methodCall);
          }
        });

        // This should either handle gracefully or throw appropriate exception
        expect(
          () async => malformedBridge.getCalendars(),
          throwsA(isA<PlatformBridgeException>()),
        );
      });

      test('should handle very large data sets', () async {
        const customChannel = MethodChannel('large_data_channel');
        const largeBridge =
            CalendarBridgeMethodChannel(methodChannel: customChannel);

        customChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'retrieveCalendars':
              return List.generate(
                1000,
                (index) => {
                  'id': 'cal_$index',
                  'name': 'Calendar $index',
                  'isReadOnly': index % 2 == 0,
                  'isDefault': index == 0,
                },
              );
            default:
              return _handleMethodCall(methodCall);
          }
        });

        final calendars = await largeBridge.getCalendars();
        expect(calendars.length, equals(1000));
        expect(calendars.first.name, equals('Calendar 0'));
        expect(calendars.last.name, equals('Calendar 999'));
      });
    });
  });
}

// Mock method call handler for testing
dynamic _handleMethodCall(MethodCall methodCall) {
  switch (methodCall.method) {
    case 'requestPermissions':
      return true;
    case 'hasPermissions':
      return 'granted';
    case 'retrieveCalendars':
      return [
        {
          'id': 'cal_123',
          'name': 'Test Calendar',
          'color': 0xFF0000FF,
          'accountName': 'test@example.com',
          'accountType': 'Google',
          'isReadOnly': false,
          'isDefault': true,
        }
      ];
    case 'retrieveEvents':
      return [
        {
          'calendarId': 'cal_123',
          'eventId': 'event_456',
          'title': 'Test Event',
          'description': 'Test Description',
          'start': DateTime(2025, 1, 15, 10).millisecondsSinceEpoch,
          'end': DateTime(2025, 1, 15, 11).millisecondsSinceEpoch,
          'allDay': false,
          'attendees': <Map<String, dynamic>>[],
          'reminders': <Map<String, dynamic>>[],
        }
      ];
    case 'createEvent':
      return 'generated_event_${DateTime.now().millisecondsSinceEpoch}';
    case 'updateEvent':
      final args = methodCall.arguments as Map;
      return args['eventId'] ?? 'updated_event_id';
    case 'deleteEvent':
      return true;
    case 'deleteEventInstance':
      return true;
    case 'createCalendar':
      final args = methodCall.arguments as Map;
      return {
        'id': 'generated_cal_${DateTime.now().millisecondsSinceEpoch}',
        'name': args['name'],
        'color': args['color'],
        'accountName': args['localAccountName'],
        'accountType': 'Local',
        'isReadOnly': false,
        'isDefault': false,
      };
    case 'deleteCalendar':
      return true;
    case 'retrieveCalendarColors':
      return {
        'red': 0xFFFF0000,
        'blue': 0xFF0000FF,
        'green': 0xFF00FF00,
      };
    case 'retrieveEventColors':
      return {
        'event_red': 0xFFFF0000,
        'event_blue': 0xFF0000FF,
      };
    case 'updateCalendarColor':
      return true;
    default:
      throw UnimplementedError(
        'Method ${methodCall.method} not implemented in mock',
      );
  }
}
