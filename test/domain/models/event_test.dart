import 'package:calendar_bridge/src/domain/models/attendee.dart';
import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/event_enums.dart';
import 'package:calendar_bridge/src/domain/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrule/rrule.dart';
import 'package:timezone/timezone.dart';

void main() {
  // Set up timezone data for tests
  setUpAll(() {
    // Initialize timezone data (normally done in main())
    // For tests, we'll use UTC
  });

  group('CalendarEvent Model Tests', () {
    const testCalendarId = 'cal_123';
    const testEventId = 'event_456';
    const testTitle = 'Test Event';
    const testDescription = 'Test Description';
    const testLocation = 'Test Location';
    const testUrl = 'https://example.com';
    const testEventColor = '#FF0000';

    late TZDateTime testStart;
    late TZDateTime testEnd;
    late TZDateTime testOriginalStart;

    setUp(() {
      testStart = TZDateTime(UTC, 2025, 1, 15, 10);
      testEnd = TZDateTime(UTC, 2025, 1, 15, 11);
      testOriginalStart = TZDateTime(UTC, 2025, 1, 15, 9);
    });

    group('Constructor Tests', () {
      test('should create event with required parameters', () {
        const event = CalendarEvent(calendarId: testCalendarId);

        expect(event.calendarId, equals(testCalendarId));
        expect(event.eventId, isNull);
        expect(event.title, isNull);
        expect(event.description, isNull);
        expect(event.start, isNull);
        expect(event.end, isNull);
        expect(event.allDay, isFalse);
        expect(event.location, isNull);
        expect(event.url, isNull);
        expect(event.recurrenceRule, isNull);
        expect(event.originalStart, isNull);
        expect(event.attendees, isEmpty);
        expect(event.reminders, isEmpty);
        expect(event.eventStatus, isNull);
        expect(event.availability, isNull);
        expect(event.organizer, isNull);
        expect(event.eventColor, isNull);
      });

      test('should create event with all parameters', () {
        final attendees = [
          const Attendee(email: 'test1@example.com'),
          const Attendee(email: 'test2@example.com'),
        ];
        final reminders = [
          Reminder.fiveMinutesBefore(),
          Reminder.oneHourBefore(),
        ];
        const organizer = Attendee(email: 'organizer@example.com');
        final recurrenceRule = RecurrenceRule(
          frequency: Frequency.weekly,
          count: 5,
        );

        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: testTitle,
          description: testDescription,
          start: testStart,
          end: testEnd,
          allDay: true,
          location: testLocation,
          url: testUrl,
          recurrenceRule: recurrenceRule,
          originalStart: testOriginalStart,
          attendees: attendees,
          reminders: reminders,
          eventStatus: EventStatus.confirmed,
          availability: EventAvailability.busy,
          organizer: organizer,
          eventColor: testEventColor,
        );

        expect(event.calendarId, equals(testCalendarId));
        expect(event.eventId, equals(testEventId));
        expect(event.title, equals(testTitle));
        expect(event.description, equals(testDescription));
        expect(event.start, equals(testStart));
        expect(event.end, equals(testEnd));
        expect(event.allDay, isTrue);
        expect(event.location, equals(testLocation));
        expect(event.url, equals(testUrl));
        expect(event.recurrenceRule, equals(recurrenceRule));
        expect(event.originalStart, equals(testOriginalStart));
        expect(event.attendees, equals(attendees));
        expect(event.reminders, equals(reminders));
        expect(event.eventStatus, equals(EventStatus.confirmed));
        expect(event.availability, equals(EventAvailability.busy));
        expect(event.organizer, equals(organizer));
        expect(event.eventColor, equals(testEventColor));
      });
    });

    group('Factory Constructor Tests', () {
      test('create should create event with required fields', () {
        final event = CalendarEvent.create(
          calendarId: testCalendarId,
          title: testTitle,
          start: testStart,
          end: testEnd,
        );

        expect(event.calendarId, equals(testCalendarId));
        expect(event.title, equals(testTitle));
        expect(event.start, equals(testStart));
        expect(event.end, equals(testEnd));
        expect(event.allDay, isFalse);
      });

      test('allDay should create all-day event', () {
        final event = CalendarEvent.allDay(
          calendarId: testCalendarId,
          title: testTitle,
          date: testStart,
        );

        expect(event.calendarId, equals(testCalendarId));
        expect(event.title, equals(testTitle));
        expect(event.start, equals(testStart));
        expect(event.end, equals(testStart.add(const Duration(days: 1))));
        expect(event.allDay, isTrue);
      });
    });

    group('JSON Serialization Tests', () {
      test('should create event from JSON with all fields', () {
        final json = {
          'calendarId': testCalendarId,
          'eventId': testEventId,
          'title': testTitle,
          'description': testDescription,
          'start': testStart.millisecondsSinceEpoch,
          'end': testEnd.millisecondsSinceEpoch,
          'allDay': true,
          'location': testLocation,
          'url': testUrl,
          'recurrenceRule': 'RRULE:FREQ=WEEKLY;COUNT=5',
          'originalStart': testOriginalStart.millisecondsSinceEpoch,
          'attendees': [
            {
              'email': 'test1@example.com',
              'role': 'required',
              'status': 'unknown',
              'isCurrentUser': false,
            },
            {
              'email': 'test2@example.com',
              'role': 'required',
              'status': 'unknown',
              'isCurrentUser': false,
            },
          ],
          'reminders': [
            {'minutes': 5},
            {'minutes': 60},
          ],
          'eventStatus': 'CONFIRMED',
          'availability': 'BUSY',
          'organizer': {
            'email': 'organizer@example.com',
            'role': 'required',
            'status': 'unknown',
            'isCurrentUser': false,
          },
          'eventColor': testEventColor,
        };

        final event = CalendarEvent.fromJson(json);

        expect(event.calendarId, equals(testCalendarId));
        expect(event.eventId, equals(testEventId));
        expect(event.title, equals(testTitle));
        expect(event.description, equals(testDescription));
        expect(event.start, equals(testStart));
        expect(event.end, equals(testEnd));
        expect(event.allDay, isTrue);
        expect(event.location, equals(testLocation));
        expect(event.url, equals(testUrl));
        expect(event.recurrenceRule?.toString(),
            equals('RRULE:FREQ=WEEKLY;COUNT=5'));
        expect(event.originalStart, equals(testOriginalStart));
        expect(event.attendees.length, equals(2));
        expect(event.reminders.length, equals(2));
        expect(event.eventStatus, equals(EventStatus.confirmed));
        expect(event.availability, equals(EventAvailability.busy));
        expect(event.organizer?.email, equals('organizer@example.com'));
        expect(event.eventColor, equals(testEventColor));
      });

      test('should create event from JSON with minimal fields', () {
        final json = {
          'calendarId': testCalendarId,
        };

        final event = CalendarEvent.fromJson(json);

        expect(event.calendarId, equals(testCalendarId));
        expect(event.eventId, isNull);
        expect(event.title, isNull);
        expect(event.description, isNull);
        expect(event.start, isNull);
        expect(event.end, isNull);
        expect(event.allDay, isFalse);
        expect(event.location, isNull);
        expect(event.url, isNull);
        expect(event.recurrenceRule, isNull);
        expect(event.originalStart, isNull);
        expect(event.attendees, isEmpty);
        expect(event.reminders, isEmpty);
        expect(event.eventStatus, isNull);
        expect(event.availability, isNull);
        expect(event.organizer, isNull);
        expect(event.eventColor, isNull);
      });

      test('should convert event to JSON', () {
        final attendees = [
          const Attendee(email: 'test1@example.com'),
        ];
        final reminders = [
          Reminder.fiveMinutesBefore(),
        ];
        const organizer = Attendee(email: 'organizer@example.com');
        final recurrenceRule = RecurrenceRule(
          frequency: Frequency.weekly,
          count: 5,
        );

        final event = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: testTitle,
          description: testDescription,
          start: testStart,
          end: testEnd,
          allDay: true,
          location: testLocation,
          url: testUrl,
          recurrenceRule: recurrenceRule,
          originalStart: testOriginalStart,
          attendees: attendees,
          reminders: reminders,
          eventStatus: EventStatus.confirmed,
          availability: EventAvailability.busy,
          organizer: organizer,
          eventColor: testEventColor,
        );

        final json = event.toJson();

        expect(json['calendarId'], equals(testCalendarId));
        expect(json['eventId'], equals(testEventId));
        expect(json['title'], equals(testTitle));
        expect(json['description'], equals(testDescription));
        expect(json['start'], equals(testStart.millisecondsSinceEpoch));
        expect(json['end'], equals(testEnd.millisecondsSinceEpoch));
        expect(json['allDay'], isTrue);
        expect(json['location'], equals(testLocation));
        expect(json['url'], equals(testUrl));
        expect(json['recurrenceRule'], isNotNull);
        expect(
          json['originalStart'],
          equals(testOriginalStart.millisecondsSinceEpoch),
        );
        expect(json['attendees'], isA<List<dynamic>>());
        expect(json['reminders'], isA<List<dynamic>>());
        expect(json['eventStatus'], equals('CONFIRMED'));
        expect(json['availability'], equals('BUSY'));
        expect(json['organizer'], isA<Map<String, dynamic>>());
        expect(json['eventColor'], equals(testEventColor));
      });

      test('should convert event with null fields to JSON', () {
        const event = CalendarEvent(calendarId: testCalendarId);

        final json = event.toJson();

        expect(json['calendarId'], equals(testCalendarId));
        expect(json['eventId'], isNull);
        expect(json['title'], isNull);
        expect(json['description'], isNull);
        expect(json['start'], isNull);
        expect(json['end'], isNull);
        expect(json['allDay'], isFalse);
        expect(json['location'], isNull);
        expect(json['url'], isNull);
        expect(json['recurrenceRule'], isNull);
        expect(json['originalStart'], isNull);
        expect(json['attendees'], isEmpty);
        expect(json['reminders'], isEmpty);
        expect(json['eventStatus'], isNull);
        expect(json['availability'], isNull);
        expect(json['organizer'], isNull);
        expect(json['eventColor'], isNull);
      });
    });

    group('copyWith Tests', () {
      test('should copy event with all fields changed', () {
        const originalEvent = CalendarEvent(calendarId: testCalendarId);

        final newStart = TZDateTime(UTC, 2025, 2, 1, 14);
        final newEnd = TZDateTime(UTC, 2025, 2, 1, 15);
        final newAttendees = [const Attendee(email: 'new@example.com')];
        final newReminders = [Reminder.oneHourBefore()];
        const newOrganizer = Attendee(email: 'new_organizer@example.com');

        final copiedEvent = originalEvent.copyWith(
          calendarId: 'new_cal',
          eventId: 'new_event',
          title: 'New Title',
          description: 'New Description',
          start: newStart,
          end: newEnd,
          allDay: true,
          location: 'New Location',
          url: 'https://new.example.com',
          attendees: newAttendees,
          reminders: newReminders,
          eventStatus: EventStatus.tentative,
          availability: EventAvailability.free,
          organizer: newOrganizer,
          eventColor: '#00FF00',
        );

        expect(copiedEvent.calendarId, equals('new_cal'));
        expect(copiedEvent.eventId, equals('new_event'));
        expect(copiedEvent.title, equals('New Title'));
        expect(copiedEvent.description, equals('New Description'));
        expect(copiedEvent.start, equals(newStart));
        expect(copiedEvent.end, equals(newEnd));
        expect(copiedEvent.allDay, isTrue);
        expect(copiedEvent.location, equals('New Location'));
        expect(copiedEvent.url, equals('https://new.example.com'));
        expect(copiedEvent.attendees, equals(newAttendees));
        expect(copiedEvent.reminders, equals(newReminders));
        expect(copiedEvent.eventStatus, equals(EventStatus.tentative));
        expect(copiedEvent.availability, equals(EventAvailability.free));
        expect(copiedEvent.organizer, equals(newOrganizer));
        expect(copiedEvent.eventColor, equals('#00FF00'));
      });

      test('should copy event with no changes', () {
        final originalEvent = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: testTitle,
          start: testStart,
          end: testEnd,
        );

        final copiedEvent = originalEvent.copyWith();

        expect(copiedEvent.calendarId, equals(testCalendarId));
        expect(copiedEvent.eventId, equals(testEventId));
        expect(copiedEvent.title, equals(testTitle));
        expect(copiedEvent.start, equals(testStart));
        expect(copiedEvent.end, equals(testEnd));
      });

      test('should copy event with partial changes', () {
        const originalEvent = CalendarEvent(calendarId: testCalendarId);

        final copiedEvent = originalEvent.copyWith(
          title: testTitle,
          allDay: true,
        );

        expect(copiedEvent.calendarId, equals(testCalendarId));
        expect(copiedEvent.title, equals(testTitle));
        expect(copiedEvent.allDay, isTrue);
        expect(copiedEvent.eventId, isNull);
        expect(copiedEvent.description, isNull);
      });
    });

    group('Validation Tests', () {
      test('isValid should return true for valid event', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testStart,
          end: testEnd,
        );

        expect(event.isValid, isTrue);
      });

      test('isValid should return false for empty calendar ID', () {
        final event = CalendarEvent(
          calendarId: '',
          start: testStart,
          end: testEnd,
        );

        expect(event.isValid, isFalse);
      });

      test('isValid should return false for missing start date', () {
        const event = CalendarEvent(
          calendarId: testCalendarId,
        );

        expect(event.isValid, isFalse);
      });

      test('isValid should return false for missing end date', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testStart,
        );

        expect(event.isValid, isFalse);
      });

      test('isValid should return false when start is after end', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testEnd,
          end: testStart,
        );

        expect(event.isValid, isFalse);
      });
    });

    group('Duration Tests', () {
      test('should calculate correct duration', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testStart,
          end: testEnd,
        );

        expect(event.duration, equals(const Duration(hours: 1)));
      });

      test('should return null duration when start is null', () {
        const event = CalendarEvent(
          calendarId: testCalendarId,
        );

        expect(event.duration, isNull);
      });

      test('should return null duration when end is null', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testStart,
        );

        expect(event.duration, isNull);
      });

      test('should handle negative duration when start is after end', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testEnd,
          end: testStart,
        );

        expect(event.duration, equals(const Duration(hours: -1)));
      });

      test('should handle zero duration', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testStart,
          end: testStart,
        );

        expect(event.duration, equals(Duration.zero));
      });
    });

    group('Equality Tests', () {
      test('should be equal when all fields match', () {
        final attendees = [const Attendee(email: 'test@example.com')];
        final reminders = [Reminder.fiveMinutesBefore()];

        final event1 = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: testTitle,
          start: testStart,
          end: testEnd,
          attendees: attendees,
          reminders: reminders,
        );

        final event2 = CalendarEvent(
          calendarId: testCalendarId,
          eventId: testEventId,
          title: testTitle,
          start: testStart,
          end: testEnd,
          attendees: attendees,
          reminders: reminders,
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const event1 = CalendarEvent(
          calendarId: testCalendarId,
          title: testTitle,
        );

        const event2 = CalendarEvent(
          calendarId: testCalendarId,
          title: 'Different Title',
        );

        expect(event1, isNot(equals(event2)));
      });

      test('should be identical when same instance', () {
        const event = CalendarEvent(calendarId: testCalendarId);

        expect(identical(event, event), isTrue);
        expect(event == event, isTrue);
      });

      test('should handle list equality for attendees', () {
        final attendees1 = [const Attendee(email: 'test1@example.com')];
        final attendees2 = [const Attendee(email: 'test1@example.com')];
        final attendees3 = [const Attendee(email: 'test2@example.com')];

        final event1 = CalendarEvent(
          calendarId: testCalendarId,
          attendees: attendees1,
        );

        final event2 = CalendarEvent(
          calendarId: testCalendarId,
          attendees: attendees2,
        );

        final event3 = CalendarEvent(
          calendarId: testCalendarId,
          attendees: attendees3,
        );

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('should handle list equality for reminders', () {
        final reminders1 = [Reminder.fiveMinutesBefore()];
        final reminders2 = [Reminder.fiveMinutesBefore()];
        final reminders3 = [Reminder.oneHourBefore()];

        final event1 = CalendarEvent(
          calendarId: testCalendarId,
          reminders: reminders1,
        );

        final event2 = CalendarEvent(
          calendarId: testCalendarId,
          reminders: reminders2,
        );

        final event3 = CalendarEvent(
          calendarId: testCalendarId,
          reminders: reminders3,
        );

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty calendar ID', () {
        const event = CalendarEvent(calendarId: '');

        expect(event.calendarId, equals(''));
        expect(event.isValid, isFalse);
      });

      test('should handle special characters in strings', () {
        const specialTitle = 'Event with émojis 📅 and spéciäl characters';
        const specialLocation = 'Locação with açcentuätęd characters';
        const specialUrl = 'https://example.com/path?param=value&other=émoji📅';

        const event = CalendarEvent(
          calendarId: testCalendarId,
          title: specialTitle,
          location: specialLocation,
          url: specialUrl,
        );

        expect(event.title, equals(specialTitle));
        expect(event.location, equals(specialLocation));
        expect(event.url, equals(specialUrl));
      });

      test('should handle very long strings', () {
        final longTitle = 'A' * 1000;
        final longDescription = 'B' * 5000;
        final longLocation = 'C' * 500;

        final event = CalendarEvent(
          calendarId: testCalendarId,
          title: longTitle,
          description: longDescription,
          location: longLocation,
        );

        expect(event.title, equals(longTitle));
        expect(event.description, equals(longDescription));
        expect(event.location, equals(longLocation));
      });

      test('should handle empty lists', () {
        const event = CalendarEvent(
          calendarId: testCalendarId,
        );

        expect(event.attendees, isEmpty);
        expect(event.reminders, isEmpty);
      });

      test('should handle large lists', () {
        final attendees = List.generate(
          100,
          (index) => Attendee(email: 'user$index@example.com'),
        );
        final reminders = List.generate(
          50,
          (index) => Reminder(minutes: index * 5),
        );

        final event = CalendarEvent(
          calendarId: testCalendarId,
          attendees: attendees,
          reminders: reminders,
        );

        expect(event.attendees.length, equals(100));
        expect(event.reminders.length, equals(50));
      });

      test('should handle extreme dates', () {
        final extremeStart = TZDateTime(UTC, 1900);
        final extremeEnd = TZDateTime(UTC, 2100, 12, 31);

        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: extremeStart,
          end: extremeEnd,
        );

        expect(event.start, equals(extremeStart));
        expect(event.end, equals(extremeEnd));
        expect(event.isValid, isTrue);
      });

      test('should handle same start and end times', () {
        final event = CalendarEvent(
          calendarId: testCalendarId,
          start: testStart,
          end: testStart,
        );

        expect(event.isValid, isTrue);
        expect(event.duration, equals(Duration.zero));
      });
    });
  });

  group('RetrieveEventsParams Tests', () {
    late TZDateTime testStartDate;
    late TZDateTime testEndDate;

    setUp(() {
      testStartDate = TZDateTime(UTC, 2025);
      testEndDate = TZDateTime(UTC, 2025, 1, 31);
    });

    group('Constructor Tests', () {
      test('should create params with all fields', () {
        final eventIds = ['event1', 'event2'];
        final params = RetrieveEventsParams(
          startDate: testStartDate,
          endDate: testEndDate,
          eventIds: eventIds,
        );

        expect(params.startDate, equals(testStartDate));
        expect(params.endDate, equals(testEndDate));
        expect(params.eventIds, equals(eventIds));
      });

      test('should create params with no fields', () {
        const params = RetrieveEventsParams();

        expect(params.startDate, isNull);
        expect(params.endDate, isNull);
        expect(params.eventIds, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should create params from JSON', () {
        final eventIds = ['event1', 'event2'];
        final json = {
          'startDate': testStartDate.millisecondsSinceEpoch,
          'endDate': testEndDate.millisecondsSinceEpoch,
          'eventIds': eventIds,
        };

        final params = RetrieveEventsParams.fromJson(json);

        expect(params.startDate, equals(testStartDate));
        expect(params.endDate, equals(testEndDate));
        expect(params.eventIds, equals(eventIds));
      });

      test('should convert params to JSON', () {
        final eventIds = ['event1', 'event2'];
        final params = RetrieveEventsParams(
          startDate: testStartDate,
          endDate: testEndDate,
          eventIds: eventIds,
        );

        final json = params.toJson();

        expect(json['startDate'], equals(testStartDate.millisecondsSinceEpoch));
        expect(json['endDate'], equals(testEndDate.millisecondsSinceEpoch));
        expect(json['eventIds'], equals(eventIds));
      });
    });

    group('copyWith Tests', () {
      test('should copy params with changes', () {
        const originalParams = RetrieveEventsParams();

        final newEventIds = ['new1', 'new2'];
        final copiedParams = originalParams.copyWith(
          startDate: testStartDate,
          endDate: testEndDate,
          eventIds: newEventIds,
        );

        expect(copiedParams.startDate, equals(testStartDate));
        expect(copiedParams.endDate, equals(testEndDate));
        expect(copiedParams.eventIds, equals(newEventIds));
      });

      test('should copy params with no changes', () {
        final eventIds = ['event1', 'event2'];
        final originalParams = RetrieveEventsParams(
          startDate: testStartDate,
          endDate: testEndDate,
          eventIds: eventIds,
        );

        final copiedParams = originalParams.copyWith();

        expect(copiedParams.startDate, equals(testStartDate));
        expect(copiedParams.endDate, equals(testEndDate));
        expect(copiedParams.eventIds, equals(eventIds));
      });
    });

    group('Equality Tests', () {
      test('should be equal when all fields match', () {
        final eventIds = ['event1', 'event2'];
        final params1 = RetrieveEventsParams(
          startDate: testStartDate,
          endDate: testEndDate,
          eventIds: eventIds,
        );

        final params2 = RetrieveEventsParams(
          startDate: testStartDate,
          endDate: testEndDate,
          eventIds: eventIds,
        );

        expect(params1, equals(params2));
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final params1 = RetrieveEventsParams(
          startDate: testStartDate,
          eventIds: const ['event1'],
        );

        final params2 = RetrieveEventsParams(
          startDate: testStartDate,
          eventIds: const ['event2'],
        );

        expect(params1, isNot(equals(params2)));
      });
    });
  });
}
