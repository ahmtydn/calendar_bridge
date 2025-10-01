import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:calendar_bridge/src/domain/use_cases/event_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'calendar_use_cases_test.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  group('EventUseCases Tests', () {
    late MockCalendarRepository mockRepository;
    late EventUseCases eventUseCases;

    const testCalendarId = 'cal_123';
    late TZDateTime testStart;
    late TZDateTime testEnd;

    setUp(() {
      mockRepository = MockCalendarRepository();
      eventUseCases = EventUseCases(mockRepository);

      testStart = TZDateTime(UTC, 2025, 1, 15, 10);
      testEnd = TZDateTime(UTC, 2025, 1, 15, 11);
    });

    tearDown(() {
      mockRepository.reset();
    });

    group('Event Retrieval Tests', () {
      test('getEvents should return events when calendar exists', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: 'event1',
          title: 'Test Event',
          start: testStart,
          end: testEnd,
        );
        mockRepository.addEvent(testCalendarId, event);

        final result = await eventUseCases.getEvents(testCalendarId);

        expect(result.length, equals(1));
        expect(result.first.title, equals('Test Event'));
      });

      test(
          'getEvents should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getEvents(''),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'getEvents should throw InvalidArgumentException for whitespace-only calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getEvents('   '),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'getEvents should throw PermissionDeniedException when permissions denied',
          () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => eventUseCases.getEvents(testCalendarId),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test(
          'getEvents should throw CalendarNotFoundException when calendar not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository.shouldThrowCalendarNotFound = true;

        expect(
          () async => eventUseCases.getEvents('nonexistent'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test('getEvents should accept date range parameters', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final startDate = TZDateTime(UTC, 2025);
        final endDate = TZDateTime(UTC, 2025, 1, 31);

        final result = await eventUseCases.getEvents(
          testCalendarId,
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isA<List<CalendarEvent>>());
      });

      test('getEventsByIds should return specific events', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final eventIds = ['event1', 'event2'];
        final result =
            await eventUseCases.getEventsByIds(testCalendarId, eventIds);

        expect(result, isA<List<CalendarEvent>>());
      });

      test(
          'getEventsByIds should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getEventsByIds('', ['event1']),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'getEventsByIds should throw InvalidArgumentException for empty event IDs list',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getEventsByIds(testCalendarId, []),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'getEventsByIds should throw InvalidArgumentException for event IDs with empty strings',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases
              .getEventsByIds(testCalendarId, ['event1', '', 'event2']),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('getTodaysEvents should return events for today', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await eventUseCases.getTodaysEvents(testCalendarId);

        expect(result, isA<List<CalendarEvent>>());
      });

      test(
          'getTodaysEvents should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getTodaysEvents(''),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('getUpcomingEvents should return upcoming events', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await eventUseCases.getUpcomingEvents(testCalendarId);

        expect(result, isA<List<CalendarEvent>>());
      });

      test('getUpcomingEvents should accept custom days parameter', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result =
            await eventUseCases.getUpcomingEvents(testCalendarId, days: 14);

        expect(result, isA<List<CalendarEvent>>());
      });

      test(
          'getUpcomingEvents should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getUpcomingEvents(''),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'getUpcomingEvents should throw InvalidArgumentException for negative days',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getUpcomingEvents(testCalendarId, days: -1),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'getUpcomingEvents should throw InvalidArgumentException for zero days',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.getUpcomingEvents(testCalendarId, days: 0),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('Event Creation Tests', () {
      test('createEvent should create event successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'New Event',
          start: testStart,
          end: testEnd,
        );

        final result = await eventUseCases.createEvent(event);

        expect(result, isNotEmpty);
        expect(result, startsWith('generated_event_'));
      });

      test(
          'createEvent should throw InvalidArgumentException for invalid event',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        const invalidEvent = CalendarEvent(calendarId: ''); // Empty calendar ID

        expect(
          () async => eventUseCases.createEvent(invalidEvent),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'createEvent should throw InvalidArgumentException for event with start after end',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final invalidEvent = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Invalid Event',
          start: testEnd, // Start after end
          end: testStart,
        );

        expect(
          () async => eventUseCases.createEvent(invalidEvent),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'createEvent should throw PermissionDeniedException when permissions denied',
          () async {
        mockRepository.setPermissionsGranted(false);

        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'New Event',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => eventUseCases.createEvent(event),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test(
          'createEvent should throw CalendarNotFoundException when calendar not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository.shouldThrowCalendarNotFound = true;

        final event = CalendarEvent(
          calendarId: 'nonexistent',
          title: 'New Event',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => eventUseCases.createEvent(event),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test('createSimpleEvent should create event successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await eventUseCases.createSimpleEvent(
          calendarId: testCalendarId,
          title: 'Simple Event',
          start: testStart,
          end: testEnd,
          description: 'Simple Description',
          location: 'Simple Location',
        );

        expect(result, isNotEmpty);
        expect(result, startsWith('generated_event_'));
      });

      test(
          'createSimpleEvent should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.createSimpleEvent(
            calendarId: '',
            title: 'Simple Event',
            start: testStart,
            end: testEnd,
          ),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'createSimpleEvent should throw InvalidArgumentException for empty title',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        expect(
          () async => eventUseCases.createSimpleEvent(
            calendarId: testCalendarId,
            title: '',
            start: testStart,
            end: testEnd,
          ),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'createSimpleEvent should throw InvalidArgumentException for start after end',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        expect(
          () async => eventUseCases.createSimpleEvent(
            calendarId: testCalendarId,
            title: 'Simple Event',
            start: testEnd, // Start after end
            end: testStart,
          ),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('Event Update Tests', () {
      test('updateEvent should update event successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: 'existing_event',
          title: 'Updated Event',
          start: testStart,
          end: testEnd,
        );

        final result = await eventUseCases.updateEvent(event);

        expect(result, equals('existing_event'));
      });

      test(
          'updateEvent should throw InvalidArgumentException for invalid event',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        const invalidEvent = CalendarEvent(calendarId: ''); // Empty calendar ID

        expect(
          () async => eventUseCases.updateEvent(invalidEvent),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'updateEvent should throw InvalidArgumentException for event without ID',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final eventWithoutId = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Event without ID',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => eventUseCases.updateEvent(eventWithoutId),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'updateEvent should throw EventNotFoundException when event not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);
        mockRepository.shouldThrowEventNotFound = true;

        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: 'nonexistent_event',
          title: 'Updated Event',
          start: testStart,
          end: testEnd,
        );

        expect(
          () async => eventUseCases.updateEvent(event),
          throwsA(isA<EventNotFoundException>()),
        );
      });
    });

    group('Event Deletion Tests', () {
      test('deleteEvent should delete event successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result =
            await eventUseCases.deleteEvent(testCalendarId, 'event_to_delete');

        expect(result, isTrue);
      });

      test(
          'deleteEvent should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.deleteEvent('', 'event_id'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'deleteEvent should throw InvalidArgumentException for empty event ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.deleteEvent(testCalendarId, ''),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'deleteEvent should throw EventNotFoundException when event not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);
        mockRepository.shouldThrowEventNotFound = true;

        expect(
          () async =>
              eventUseCases.deleteEvent(testCalendarId, 'nonexistent_event'),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('deleteEventInstance should delete event instance successfully',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await eventUseCases.deleteEventInstance(
          testCalendarId,
          'recurring_event',
          testStart.toLocal(),
        );

        expect(result, isTrue);
      });

      test(
          'deleteEventInstance should delete following instances when specified',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await eventUseCases.deleteEventInstance(
          testCalendarId,
          'recurring_event',
          testStart.toLocal(),
          followingInstances: true,
        );

        expect(result, isTrue);
      });

      test(
          'deleteEventInstance should throw InvalidArgumentException for empty calendar ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.deleteEventInstance(
            '',
            'event_id',
            testStart.toLocal(),
          ),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'deleteEventInstance should throw InvalidArgumentException for empty event ID',
          () async {
        mockRepository.setPermissionsGranted(true);

        expect(
          () async => eventUseCases.deleteEventInstance(
            testCalendarId,
            '',
            testStart.toLocal(),
          ),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test(
          'deleteEventInstance should throw EventNotFoundException when event not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);
        mockRepository.shouldThrowEventNotFound = true;

        expect(
          () async => eventUseCases.deleteEventInstance(
            testCalendarId,
            'nonexistent_event',
            testStart.toLocal(),
          ),
          throwsA(isA<EventNotFoundException>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle events with null start/end dates during validation',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        const eventWithNullDates = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Event with null dates',
        );

        expect(
          () async => eventUseCases.createEvent(eventWithNullDates),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('should handle very long event titles', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final longTitle = 'A' * 1000;
        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: longTitle,
          start: testStart,
          end: testEnd,
        );

        final result = await eventUseCases.createEvent(event);

        expect(result, isNotEmpty);
      });

      test('should handle events with same start and end times', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Zero duration event',
          start: testStart,
          end: testStart, // Same as start
        );

        final result = await eventUseCases.createEvent(event);

        expect(result, isNotEmpty);
      });

      test('should handle special characters in calendar and event IDs',
          () async {
        mockRepository.setPermissionsGranted(true);
        const specialCalendarId = 'cal@#\$%^&*(){}[]|\\:";\'<>?,.';
        const calendar = Calendar(id: specialCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result =
            await eventUseCases.deleteEvent(specialCalendarId, r'event@#$%');

        expect(result, isTrue);
      });

      test('getUpcomingEvents should handle very large days value', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result =
            await eventUseCases.getUpcomingEvents(testCalendarId, days: 365);

        expect(result, isA<List<CalendarEvent>>());
      });

      test('should handle event IDs list with maximum allowed entries',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: testCalendarId, name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final eventIds = List.generate(100, (index) => 'event_$index');
        final result =
            await eventUseCases.getEventsByIds(testCalendarId, eventIds);

        expect(result, isA<List<CalendarEvent>>());
      });
    });
  });
}
