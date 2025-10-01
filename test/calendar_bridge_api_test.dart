import 'package:calendar_bridge/src/calendar_bridge_api.dart';
import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:calendar_bridge/src/domain/models/permission_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'domain/use_cases/calendar_use_cases_test.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  group('CalendarBridge API Tests', () {
    late MockCalendarRepository mockRepository;
    late CalendarBridge calendarBridge;

    const testCalendarId = 'cal_123';
    const testEventId = 'event_456';
    late TZDateTime testStart;
    late TZDateTime testEnd;

    setUp(() {
      mockRepository = MockCalendarRepository();
      calendarBridge = CalendarBridge.custom(repository: mockRepository);

      testStart = TZDateTime(UTC, 2025, 1, 15, 10);
      testEnd = TZDateTime(UTC, 2025, 1, 15, 11);
    });

    tearDown(() {
      mockRepository.reset();
    });

    group('Constructor Tests', () {
      test('default constructor should create instance', () {
        final bridge = CalendarBridge();

        expect(bridge, isA<CalendarBridge>());
      });

      test('custom constructor should create instance with custom repository',
          () {
        final bridge = CalendarBridge.custom(repository: mockRepository);

        expect(bridge, isA<CalendarBridge>());
      });
    });

    group('Permission Tests', () {
      test('requestPermissions should return true when permissions granted',
          () async {
        final result = await calendarBridge.requestPermissions();

        expect(result, isTrue);
      });

      test('hasPermissions should return permission status', () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarBridge.hasPermissions();

        expect(result, equals(PermissionStatus.granted));
      });

      test('hasPermissions should return denied status', () async {
        mockRepository.setPermissionsGranted(false);

        final result = await calendarBridge.hasPermissions();

        expect(result, equals(PermissionStatus.denied));
      });
    });

    group('Calendar Operations Tests', () {
      test('getCalendars should return all calendars', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await calendarBridge.getCalendars();

        expect(result.length, equals(1));
        expect(result.first.id, equals(testCalendarId));
      });

      test(
          'getCalendars should throw '
          'PermissionDeniedException when permissions denied', () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => calendarBridge.getCalendars(),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('getWritableCalendars should return only writable calendars',
          () async {
        mockRepository.setPermissionsGranted(true);
        const readOnlyCalendar = Calendar(
          id: 'readonly_cal',
          name: 'Read Only',
          isReadOnly: true,
        );
        const writableCalendar = Calendar(
          id: testCalendarId,
          name: 'Writable',
        );
        mockRepository
          ..addCalendar(readOnlyCalendar)
          ..addCalendar(writableCalendar);

        final result = await calendarBridge.getWritableCalendars();

        expect(result.length, equals(1));
        expect(result.first.isReadOnly, isFalse);
      });

      test('getDefaultCalendar should return default calendar', () async {
        mockRepository.setPermissionsGranted(true);
        const defaultCalendar = Calendar(
          id: testCalendarId,
          name: 'Default Calendar',
          isDefault: true,
        );
        mockRepository.addCalendar(defaultCalendar);

        final result = await calendarBridge.getDefaultCalendar();

        expect(result.isDefault, isTrue);
        expect(result.id, equals(testCalendarId));
      });

      test('createCalendar should create calendar with all parameters',
          () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarBridge.createCalendar(
          name: 'New Calendar',
          color: 0xFF0000FF,
          localAccountName: 'test@example.com',
        );

        expect(result.name, equals('New Calendar'));
        expect(result.color, equals(0xFF0000FF));
        expect(result.accountName, equals('test@example.com'));
      });

      test('createCalendar should create calendar with minimal parameters',
          () async {
        mockRepository.setPermissionsGranted(true);

        final result =
            await calendarBridge.createCalendar(name: 'Simple Calendar');

        expect(result.name, equals('Simple Calendar'));
        expect(result.color, isNull);
        expect(result.accountName, isNull);
      });

      test(
          'createCalendar should throw '
          'PermissionDeniedException when permissions denied', () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => calendarBridge.createCalendar(name: 'New Calendar'),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('deleteCalendar should delete calendar successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar =
            Calendar(id: testCalendarId, name: 'Calendar to Delete');
        mockRepository.addCalendar(calendar);

        final result = await calendarBridge.deleteCalendar(testCalendarId);

        expect(result, isTrue);
      });

      test(
          'deleteCalendar should throw '
          'CalendarNotFoundException when calendar not found', () async {
        mockRepository
          ..setPermissionsGranted(true)
          ..shouldThrowCalendarNotFound = true;

        expect(
          () async => calendarBridge.deleteCalendar('nonexistent'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });
    });

    group('Event Operations Tests', () {
      setUp(() {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);
      });

      test('getEvents should return events from calendar', () async {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: 'Test Event',
          start: testStart,
          end: testEnd,
        );
        mockRepository.addEvent(testCalendarId, event);

        final result = await calendarBridge.getEvents(testCalendarId);

        expect(result.length, equals(1));
        expect(result.first.title, equals('Test Event'));
      });

      test('getEvents should accept date range parameters', () async {
        final startDate = DateTime(2025);
        final endDate = DateTime(2025, 1, 31);

        final result = await calendarBridge.getEvents(
          testCalendarId,
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isA<List<CalendarEvent>>());
      });

      test('getEventsByIds should return specific events', () async {
        final eventIds = [testEventId, 'event2'];

        final result =
            await calendarBridge.getEventsByIds(testCalendarId, eventIds);

        expect(result, isA<List<CalendarEvent>>());
      });

      test("getTodaysEvents should return today's events", () async {
        final result = await calendarBridge.getTodaysEvents(testCalendarId);

        expect(result, isA<List<CalendarEvent>>());
      });

      test('getUpcomingEvents should return upcoming events', () async {
        final result = await calendarBridge.getUpcomingEvents(testCalendarId);

        expect(result, isA<List<CalendarEvent>>());
      });

      test('getUpcomingEvents should accept custom days parameter', () async {
        final result =
            await calendarBridge.getUpcomingEvents(testCalendarId, days: 14);

        expect(result, isA<List<CalendarEvent>>());
      });

      test('createEvent should create event successfully', () async {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'New Event',
          start: testStart,
          end: testEnd,
        );

        final result = await calendarBridge.createEvent(event);

        expect(result, isNotEmpty);
        expect(result, startsWith('generated_event_'));
      });

      test('createSimpleEvent should create event with all parameters',
          () async {
        final result = await calendarBridge.createSimpleEvent(
          calendarId: testCalendarId,
          title: 'Simple Event',
          start: testStart.toLocal(),
          end: testEnd.toLocal(),
          description: 'Simple Description',
          location: 'Simple Location',
        );

        expect(result, isNotEmpty);
        expect(result, startsWith('generated_event_'));
      });

      test('createSimpleEvent should create event with minimal parameters',
          () async {
        final result = await calendarBridge.createSimpleEvent(
          calendarId: testCalendarId,
          title: 'Simple Event',
          start: testStart.toLocal(),
          end: testEnd.toLocal(),
        );

        expect(result, isNotEmpty);
        expect(result, startsWith('generated_event_'));
      });

      test('updateEvent should update event successfully', () async {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: 'Updated Event',
          start: testStart,
          end: testEnd,
        );

        final result = await calendarBridge.updateEvent(event);

        expect(result, equals(testEventId));
      });

      test(
          'updateEvent should throw '
          'EventNotFoundException when event not found', () async {
        mockRepository.shouldThrowEventNotFound = true;
        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: 'nonexistent_event',
          title: 'Updated Event',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => calendarBridge.updateEvent(event),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('deleteEvent should delete event successfully', () async {
        final result =
            await calendarBridge.deleteEvent(testCalendarId, testEventId);

        expect(result, isTrue);
      });

      test(
          'deleteEvent should throw '
          'EventNotFoundException when event not found', () async {
        mockRepository.shouldThrowEventNotFound = true;

        expect(
          () async => calendarBridge.deleteEvent(testCalendarId, 'nonexistent'),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('deleteEventInstance should delete event instance successfully',
          () async {
        final result = await calendarBridge.deleteEventInstance(
          testCalendarId,
          testEventId,
          testStart.toLocal(),
        );

        expect(result, isTrue);
      });

      test(
          'deleteEventInstance should delete '
          'following instances when specified', () async {
        final result = await calendarBridge.deleteEventInstance(
          testCalendarId,
          testEventId,
          testStart.toLocal(),
          followingInstances: true,
        );

        expect(result, isTrue);
      });
    });

    group('Calendar Color Operations Tests', () {
      setUp(() {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);
      });

      test('getCalendarColors should return available colors', () async {
        final result = await calendarBridge.getCalendarColors();

        expect(result, isNotNull);
        expect(result!.containsKey('red'), isTrue);
        expect(result.containsKey('blue'), isTrue);
      });

      test(
          'getCalendarColors should throw '
          'PermissionDeniedException when permissions denied', () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => calendarBridge.getCalendarColors(),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('getEventColors should return available event colors', () async {
        final result = await calendarBridge.getEventColors(testCalendarId);

        expect(result, isNotNull);
        expect(result!.containsKey('event_red'), isTrue);
        expect(result.containsKey('event_blue'), isTrue);
      });

      test(
          'getEventColors should throw CalendarNotFoundException '
          'when calendar not found', () async {
        mockRepository.shouldThrowCalendarNotFound = true;

        expect(
          () async => calendarBridge.getEventColors('nonexistent'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test('updateCalendarColor should update color successfully', () async {
        final result =
            await calendarBridge.updateCalendarColor(testCalendarId, 'red');

        expect(result, isTrue);
      });

      test(
          'updateCalendarColor should throw '
          'CalendarNotFoundException when calendar not found', () async {
        mockRepository.shouldThrowCalendarNotFound = true;

        expect(
          () async => calendarBridge.updateCalendarColor('nonexistent', 'red'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });
    });

    group('Error Handling Tests', () {
      test('should propagate PermissionDeniedException from repository',
          () async {
        mockRepository.shouldThrowPermissionDenied = true;

        expect(
          () async => calendarBridge.getCalendars(),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('should propagate CalendarNotFoundException from repository',
          () async {
        mockRepository
          ..setPermissionsGranted(true)
          ..shouldThrowCalendarNotFound = true;

        expect(
          () async => calendarBridge.getEvents('nonexistent'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test('should propagate EventNotFoundException from repository', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository
          ..addCalendar(calendar)
          ..shouldThrowEventNotFound = true;

        expect(
          () async => calendarBridge.deleteEvent(testCalendarId, 'nonexistent'),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('should propagate InvalidArgumentException from repository',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository
          ..addCalendar(calendar)
          ..shouldThrowInvalidArgument = true
          ..invalidArgumentMessage = 'Invalid event data';

        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Test Event',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => calendarBridge.createEvent(event),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('Edge Cases Tests', () {
      test('should handle empty calendar list', () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarBridge.getCalendars();

        expect(result, isEmpty);
      });

      test('should handle empty event list', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await calendarBridge.getEvents(testCalendarId);

        expect(result, isEmpty);
      });

      test('should handle null color values', () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarBridge.createCalendar(
          name: 'Calendar without color',
        );

        expect(result.color, isNull);
      });

      test('should handle very long calendar names', () async {
        mockRepository.setPermissionsGranted(true);
        final longName = 'A' * 1000;

        final result = await calendarBridge.createCalendar(name: longName);

        expect(result.name, equals(longName));
      });

      test('should handle special characters in calendar names', () async {
        mockRepository.setPermissionsGranted(true);
        const specialName = 'Calendar with émojis 📅 and spéciäl characters';

        final result = await calendarBridge.createCalendar(name: specialName);

        expect(result.name, equals(specialName));
      });

      test('should handle DateTime to TZDateTime conversion correctly',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final startDate = DateTime(2025, 1, 15, 10);
        final endDate = DateTime(2025, 1, 15, 11);

        final result = await calendarBridge.createSimpleEvent(
          calendarId: testCalendarId,
          title: 'DateTime Event',
          start: startDate,
          end: endDate,
        );

        expect(result, isNotEmpty);
      });

      test('should handle large event ID lists', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final eventIds = List.generate(100, (index) => 'event_$index');

        final result =
            await calendarBridge.getEventsByIds(testCalendarId, eventIds);

        expect(result, isA<List<CalendarEvent>>());
      });

      test('should handle very large days value for upcoming events', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result =
            await calendarBridge.getUpcomingEvents(testCalendarId, days: 365);

        expect(result, isA<List<CalendarEvent>>());
      });
    });
  });
}
