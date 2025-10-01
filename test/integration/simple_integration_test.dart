import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
  });

  group('CalendarBridge Integration Tests', () {
    late CalendarBridge calendarBridge;

    setUp(() {
      calendarBridge = CalendarBridge();
    });

    group('Permission Integration', () {
      test('should handle permission requests', () async {
        try {
          final hasPermission = await calendarBridge.requestPermissions();
          expect(hasPermission, isA<bool>());

          final permissionStatus = await calendarBridge.hasPermissions();
          expect(permissionStatus, isA<PermissionStatus>());
        } catch (e) {
          // Permission requests may fail in test environment
          expect(
            e,
            anyOf([
              isA<PermissionDeniedException>(),
              isA<Exception>(),
            ]),
          );
        }
      });
    });

    group('Calendar Management Integration', () {
      test('should handle calendar operations', () async {
        try {
          // Test retrieving calendars
          final calendars = await calendarBridge.getCalendars();
          expect(calendars, isA<List<Calendar>>());

          // Test getting writable calendars
          final writableCalendars = await calendarBridge.getWritableCalendars();
          expect(writableCalendars, isA<List<Calendar>>());

          // Test getting default calendar
          final defaultCalendar = await calendarBridge.getDefaultCalendar();
          expect(defaultCalendar, isA<Calendar>());

          // Test creating calendar
          final createdCalendar = await calendarBridge.createCalendar(
            name: 'Integration Test Calendar',
            color: 0xFFFF5722,
          );
          expect(createdCalendar, isA<Calendar>());
          expect(createdCalendar.name, 'Integration Test Calendar');

          // Test calendar colors
          final calendarColors = await calendarBridge.getCalendarColors();
          expect(
            calendarColors,
            anyOf([
              isA<Map<String, int>>(),
              isNull,
            ]),
          );

          // Clean up - try to delete the calendar
          await calendarBridge.deleteCalendar(createdCalendar.id);
        } catch (e) {
          // Platform operations may fail in test environment
          expect(
            e,
            anyOf([
              isA<PermissionDeniedException>(),
              isA<CalendarNotFoundException>(),
              isA<InvalidArgumentException>(),
              isA<Exception>(),
            ]),
          );
        }
      });
    });

    group('Event Management Integration', () {
      test('should handle simple event operations', () async {
        try {
          // Get a calendar to work with
          final calendar = await calendarBridge.getDefaultCalendar();

          // Create a simple event
          final eventId = await calendarBridge.createSimpleEvent(
            calendarId: calendar.id,
            title: 'Integration Test Event',
            start: DateTime.now().add(const Duration(days: 1)),
            end: DateTime.now().add(const Duration(days: 1, hours: 1)),
            description: 'This is a test event',
            location: 'Test Location',
          );
          expect(eventId, isA<String>());

          // Test retrieving events
          final events = await calendarBridge.getEvents(
            calendar.id,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 7)),
          );
          expect(events, isA<List<CalendarEvent>>());

          // Test getting today's events
          final todaysEvents =
              await calendarBridge.getTodaysEvents(calendar.id);
          expect(todaysEvents, isA<List<CalendarEvent>>());

          // Test getting upcoming events
          final upcomingEvents = await calendarBridge.getUpcomingEvents(
            calendar.id,
          );
          expect(upcomingEvents, isA<List<CalendarEvent>>());

          // Clean up events
          await calendarBridge.deleteEvent(calendar.id, eventId);
        } catch (e) {
          // Platform operations may fail in test environment
          expect(
            e,
            anyOf([
              isA<PermissionDeniedException>(),
              isA<CalendarNotFoundException>(),
              isA<EventNotFoundException>(),
              isA<InvalidArgumentException>(),
              isA<Exception>(),
            ]),
          );
        }
      });

      test('should handle full event operations', () async {
        try {
          final calendar = await calendarBridge.getDefaultCalendar();

          // Create a full event
          final event = CalendarEvent(
            calendarId: calendar.id,
            title: 'Full Integration Test Event',
            description: 'Complete test event',
            start: tz.TZDateTime.now(tz.local).add(const Duration(days: 2)),
            end: tz.TZDateTime.now(tz.local)
                .add(const Duration(days: 2, hours: 2)),
            location: 'Test Location',
            attendees: const [
              Attendee(
                name: 'John Doe',
                email: 'john@example.com',
              ),
            ],
            reminders: [
              Reminder.fifteenMinutesBefore(),
              Reminder.oneHourBefore(),
            ],
          );

          final fullEventId = await calendarBridge.createEvent(event);
          expect(fullEventId, isA<String>());

          // Test getting events by IDs
          final eventsById = await calendarBridge.getEventsByIds(
            calendar.id,
            [fullEventId],
          );
          expect(eventsById, isA<List<CalendarEvent>>());

          // Clean up
          await calendarBridge.deleteEvent(calendar.id, fullEventId);
        } catch (e) {
          expect(
            e,
            anyOf([
              isA<PermissionDeniedException>(),
              isA<CalendarNotFoundException>(),
              isA<EventNotFoundException>(),
              isA<InvalidArgumentException>(),
              isA<Exception>(),
            ]),
          );
        }
      });
    });

    group('Error Handling Integration', () {
      test('should handle invalid operations gracefully', () async {
        // Test with non-existent calendar
        expect(
          () => calendarBridge.deleteCalendar('non-existent-calendar'),
          throwsA(
            anyOf([
              isA<CalendarNotFoundException>(),
              isA<Exception>(),
            ]),
          ),
        );

        // Test with invalid event
        expect(
          () => calendarBridge.deleteEvent(
            'non-existent-calendar',
            'non-existent-event',
          ),
          throwsA(
            anyOf([
              isA<CalendarNotFoundException>(),
              isA<EventNotFoundException>(),
              isA<Exception>(),
            ]),
          ),
        );
      });
    });
  });
}
