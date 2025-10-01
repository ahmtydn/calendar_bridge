import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:calendar_bridge/src/domain/models/event.dart';
import 'package:calendar_bridge/src/domain/models/exceptions.dart';
import 'package:calendar_bridge/src/domain/models/permission_status.dart';
import 'package:calendar_bridge/src/domain/repositories/calendar_repository.dart';
import 'package:calendar_bridge/src/domain/use_cases/calendar_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock implementation of CalendarRepository for testing
class MockCalendarRepository implements CalendarRepository {
  bool _permissionsGranted = false;
  final List<Calendar> _calendars = [];
  final Map<String, List<CalendarEvent>> _events = {};
  final Map<String, int> _calendarColors = {
    'red': 0xFFFF0000,
    'blue': 0xFF0000FF,
  };
  final Map<String, Map<String, int>> _eventColors = {};

  // Configuration for testing different scenarios
  bool shouldThrowPermissionDenied = false;
  bool shouldThrowCalendarNotFound = false;
  bool shouldThrowEventNotFound = false;
  bool shouldThrowInvalidArgument = false;
  String? invalidArgumentMessage;

  void setPermissionsGranted(bool granted) {
    _permissionsGranted = granted;
  }

  void addCalendar(Calendar calendar) {
    _calendars.add(calendar);
    _events[calendar.id] = [];
    _eventColors[calendar.id] = {
      'event_red': 0xFFFF0000,
      'event_blue': 0xFF0000FF,
    };
  }

  void addEvent(String calendarId, CalendarEvent event) {
    if (_events.containsKey(calendarId)) {
      _events[calendarId]!.add(event);
    }
  }

  void reset() {
    _permissionsGranted = false;
    _calendars.clear();
    _events.clear();
    _eventColors.clear();
    shouldThrowPermissionDenied = false;
    shouldThrowCalendarNotFound = false;
    shouldThrowEventNotFound = false;
    shouldThrowInvalidArgument = false;
    invalidArgumentMessage = null;
  }

  void _checkPermissions() {
    if (shouldThrowPermissionDenied || !_permissionsGranted) {
      throw const PermissionDeniedException();
    }
  }

  void _checkCalendarExists(String calendarId) {
    if (shouldThrowCalendarNotFound ||
        !_calendars.any((c) => c.id == calendarId)) {
      throw CalendarNotFoundException(calendarId);
    }
  }

  void _checkInvalidArgument() {
    if (shouldThrowInvalidArgument) {
      throw InvalidArgumentException(invalidArgumentMessage ?? 'test argument');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    _permissionsGranted = true;
    return _permissionsGranted;
  }

  @override
  Future<PermissionStatus> hasPermissions() async {
    return _permissionsGranted
        ? PermissionStatus.granted
        : PermissionStatus.denied;
  }

  @override
  Future<List<Calendar>> getCalendars() async {
    _checkPermissions();
    return List.from(_calendars);
  }

  @override
  Future<List<CalendarEvent>> getEvents(
    String calendarId, {
    RetrieveEventsParams? params,
  }) async {
    _checkPermissions();
    _checkCalendarExists(calendarId);
    return List.from(_events[calendarId] ?? []);
  }

  @override
  Future<String> createEvent(CalendarEvent event) async {
    _checkPermissions();
    _checkCalendarExists(event.calendarId);
    _checkInvalidArgument();

    final eventId = 'generated_event_${DateTime.now().millisecondsSinceEpoch}';
    final newEvent = event.copyWith(eventId: eventId);
    addEvent(event.calendarId, newEvent);
    return eventId;
  }

  @override
  Future<String> updateEvent(CalendarEvent event) async {
    _checkPermissions();
    _checkCalendarExists(event.calendarId);
    _checkInvalidArgument();

    if (shouldThrowEventNotFound || event.eventId == null) {
      throw EventNotFoundException(event.eventId ?? 'null');
    }

    return event.eventId!;
  }

  @override
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    _checkPermissions();
    _checkCalendarExists(calendarId);

    if (shouldThrowEventNotFound) {
      throw EventNotFoundException(eventId);
    }

    final events = _events[calendarId];
    if (events != null) {
      events.removeWhere((e) => e.eventId == eventId);
    }
    return true;
  }

  @override
  Future<Calendar> createCalendar(CreateCalendarParams params) async {
    _checkPermissions();
    _checkInvalidArgument();

    final calendarId = 'generated_cal_${DateTime.now().millisecondsSinceEpoch}';
    final calendar = Calendar(
      id: calendarId,
      name: params.name,
      color: params.color,
      accountName: params.localAccountName,
    );
    addCalendar(calendar);
    return calendar;
  }

  @override
  Future<bool> deleteCalendar(String calendarId) async {
    _checkPermissions();
    _checkCalendarExists(calendarId);

    _calendars.removeWhere((c) => c.id == calendarId);
    _events.remove(calendarId);
    _eventColors.remove(calendarId);
    return true;
  }

  @override
  Future<Map<String, int>?> getCalendarColors() async {
    _checkPermissions();
    return Map.from(_calendarColors);
  }

  @override
  Future<Map<String, int>?> getEventColors(String calendarId) async {
    _checkPermissions();
    _checkCalendarExists(calendarId);
    return Map.from(_eventColors[calendarId] ?? {});
  }

  @override
  Future<bool> updateCalendarColor(String calendarId, String colorKey) async {
    _checkPermissions();
    _checkCalendarExists(calendarId);
    return true;
  }

  @override
  Future<bool> deleteEventInstance(
    String calendarId,
    String eventId,
    DateTime startDate, {
    bool followingInstances = false,
  }) async {
    _checkPermissions();
    _checkCalendarExists(calendarId);

    if (shouldThrowEventNotFound) {
      throw EventNotFoundException(eventId);
    }

    return true;
  }
}

void main() {
  group('CalendarUseCases Tests', () {
    late MockCalendarRepository mockRepository;
    late CalendarUseCases calendarUseCases;

    setUp(() {
      mockRepository = MockCalendarRepository();
      calendarUseCases = CalendarUseCases(mockRepository);
    });

    tearDown(() {
      mockRepository.reset();
    });

    group('Permission Tests', () {
      test('requestPermissions should return true when permissions granted',
          () async {
        final result = await calendarUseCases.requestPermissions();

        expect(result, isTrue);
      });

      test('hasPermissions should return granted status', () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarUseCases.hasPermissions();

        expect(result, equals(PermissionStatus.granted));
      });

      test('hasPermissions should return denied status', () async {
        mockRepository.setPermissionsGranted(false);

        final result = await calendarUseCases.hasPermissions();

        expect(result, equals(PermissionStatus.denied));
      });
    });

    group('Calendar Retrieval Tests', () {
      test(
          'getAllCalendars should return all calendars when permissions granted',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar1 = Calendar(id: 'cal1', name: 'Calendar 1');
        const calendar2 = Calendar(id: 'cal2', name: 'Calendar 2');
        mockRepository.addCalendar(calendar1);
        mockRepository.addCalendar(calendar2);

        final result = await calendarUseCases.getAllCalendars();

        expect(result.length, equals(2));
        expect(result, contains(calendar1));
        expect(result, contains(calendar2));
      });

      test(
          'getAllCalendars should throw PermissionDeniedException when permissions denied',
          () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => calendarUseCases.getAllCalendars(),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('getFilteredCalendars should filter by read-only status', () async {
        mockRepository.setPermissionsGranted(true);
        const readOnlyCalendar =
            Calendar(id: 'cal1', name: 'Read Only', isReadOnly: true);
        const writableCalendar = Calendar(id: 'cal2', name: 'Writable');
        mockRepository.addCalendar(readOnlyCalendar);
        mockRepository.addCalendar(writableCalendar);

        final writableResult =
            await calendarUseCases.getFilteredCalendars(isReadOnly: false);
        final readOnlyResult =
            await calendarUseCases.getFilteredCalendars(isReadOnly: true);

        expect(writableResult.length, equals(1));
        expect(writableResult.first.isReadOnly, isFalse);
        expect(readOnlyResult.length, equals(1));
        expect(readOnlyResult.first.isReadOnly, isTrue);
      });

      test('getFilteredCalendars should filter by account type', () async {
        mockRepository.setPermissionsGranted(true);
        const googleCalendar =
            Calendar(id: 'cal1', name: 'Google', accountType: 'Google');
        const localCalendar =
            Calendar(id: 'cal2', name: 'Local', accountType: 'Local');
        mockRepository.addCalendar(googleCalendar);
        mockRepository.addCalendar(localCalendar);

        final googleResult =
            await calendarUseCases.getFilteredCalendars(accountType: 'Google');
        final localResult =
            await calendarUseCases.getFilteredCalendars(accountType: 'Local');

        expect(googleResult.length, equals(1));
        expect(googleResult.first.accountType, equals('Google'));
        expect(localResult.length, equals(1));
        expect(localResult.first.accountType, equals('Local'));
      });

      test('getWritableCalendars should return only writable calendars',
          () async {
        mockRepository.setPermissionsGranted(true);
        const readOnlyCalendar =
            Calendar(id: 'cal1', name: 'Read Only', isReadOnly: true);
        const writableCalendar = Calendar(id: 'cal2', name: 'Writable');
        mockRepository.addCalendar(readOnlyCalendar);
        mockRepository.addCalendar(writableCalendar);

        final result = await calendarUseCases.getWritableCalendars();

        expect(result.length, equals(1));
        expect(result.first.isReadOnly, isFalse);
      });

      test('getDefaultCalendar should return default calendar when available',
          () async {
        mockRepository.setPermissionsGranted(true);
        const defaultCalendar =
            Calendar(id: 'cal1', name: 'Default', isDefault: true);
        const regularCalendar = Calendar(id: 'cal2', name: 'Regular');
        mockRepository.addCalendar(defaultCalendar);
        mockRepository.addCalendar(regularCalendar);

        final result = await calendarUseCases.getDefaultCalendar();

        expect(result.isDefault, isTrue);
        expect(result.id, equals('cal1'));
      });

      test(
          'getDefaultCalendar should return first writable calendar when no default',
          () async {
        mockRepository.setPermissionsGranted(true);
        const readOnlyCalendar =
            Calendar(id: 'cal1', name: 'Read Only', isReadOnly: true);
        const writableCalendar = Calendar(id: 'cal2', name: 'Writable');
        mockRepository.addCalendar(readOnlyCalendar);
        mockRepository.addCalendar(writableCalendar);

        final result = await calendarUseCases.getDefaultCalendar();

        expect(result.isReadOnly, isFalse);
        expect(result.id, equals('cal2'));
      });

      test(
          'getDefaultCalendar should throw CalendarNotFoundException when no writable calendars',
          () async {
        mockRepository.setPermissionsGranted(true);
        const readOnlyCalendar =
            Calendar(id: 'cal1', name: 'Read Only', isReadOnly: true);
        mockRepository.addCalendar(readOnlyCalendar);

        expect(
          () async => calendarUseCases.getDefaultCalendar(),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });
    });

    group('Calendar Management Tests', () {
      test('createCalendar should create calendar successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const params = CreateCalendarParams(
          name: 'New Calendar',
          color: 0xFF0000FF,
          localAccountName: 'test@example.com',
        );

        final result = await calendarUseCases.createCalendar(params);

        expect(result.name, equals('New Calendar'));
        expect(result.color, equals(0xFF0000FF));
        expect(result.accountName, equals('test@example.com'));
        expect(result.id, isNotEmpty);
      });

      test(
          'createCalendar should throw PermissionDeniedException when permissions denied',
          () async {
        mockRepository.setPermissionsGranted(false);
        const params = CreateCalendarParams(name: 'New Calendar');

        expect(
          () async => calendarUseCases.createCalendar(params),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test(
          'createCalendar should throw InvalidArgumentException when invalid params',
          () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository.shouldThrowInvalidArgument = true;
        const params = CreateCalendarParams(name: 'Invalid Calendar');

        expect(
          () async => calendarUseCases.createCalendar(params),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('deleteCalendar should delete calendar successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: 'cal1', name: 'Calendar to Delete');
        mockRepository.addCalendar(calendar);

        final result = await calendarUseCases.deleteCalendar('cal1');

        expect(result, isTrue);
      });

      test(
          'deleteCalendar should throw CalendarNotFoundException when calendar not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository.shouldThrowCalendarNotFound = true;

        expect(
          () async => calendarUseCases.deleteCalendar('nonexistent'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test(
          'deleteCalendar should throw PermissionDeniedException when permissions denied',
          () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => calendarUseCases.deleteCalendar('cal1'),
          throwsA(isA<PermissionDeniedException>()),
        );
      });
    });

    group('Color Management Tests', () {
      test('getCalendarColors should return available colors', () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarUseCases.getCalendarColors();

        expect(result, isNotNull);
        expect(result!.containsKey('red'), isTrue);
        expect(result.containsKey('blue'), isTrue);
        expect(result['red'], equals(0xFFFF0000));
        expect(result['blue'], equals(0xFF0000FF));
      });

      test(
          'getCalendarColors should throw PermissionDeniedException when permissions denied',
          () async {
        mockRepository.setPermissionsGranted(false);

        expect(
          () async => calendarUseCases.getCalendarColors(),
          throwsA(isA<PermissionDeniedException>()),
        );
      });

      test('getEventColors should return available event colors', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: 'cal1', name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result = await calendarUseCases.getEventColors('cal1');

        expect(result, isNotNull);
        expect(result!.containsKey('event_red'), isTrue);
        expect(result.containsKey('event_blue'), isTrue);
      });

      test(
          'getEventColors should throw CalendarNotFoundException when calendar not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository.shouldThrowCalendarNotFound = true;

        expect(
          () async => calendarUseCases.getEventColors('nonexistent'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });

      test('updateCalendarColor should update color successfully', () async {
        mockRepository.setPermissionsGranted(true);
        const calendar = Calendar(id: 'cal1', name: 'Test Calendar');
        mockRepository.addCalendar(calendar);

        final result =
            await calendarUseCases.updateCalendarColor('cal1', 'red');

        expect(result, isTrue);
      });

      test(
          'updateCalendarColor should throw CalendarNotFoundException when calendar not found',
          () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository.shouldThrowCalendarNotFound = true;

        expect(
          () async =>
              calendarUseCases.updateCalendarColor('nonexistent', 'red'),
          throwsA(isA<CalendarNotFoundException>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle empty calendar list', () async {
        mockRepository.setPermissionsGranted(true);

        final result = await calendarUseCases.getAllCalendars();

        expect(result, isEmpty);
      });

      test('should handle null calendar colors', () async {
        mockRepository.setPermissionsGranted(true);
        mockRepository._calendarColors.clear();

        final result = await calendarUseCases.getCalendarColors();

        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test(
          'getFilteredCalendars should return all calendars when no filters applied',
          () async {
        mockRepository.setPermissionsGranted(true);
        const calendar1 = Calendar(id: 'cal1', name: 'Calendar 1');
        const calendar2 = Calendar(id: 'cal2', name: 'Calendar 2');
        mockRepository.addCalendar(calendar1);
        mockRepository.addCalendar(calendar2);

        final result = await calendarUseCases.getFilteredCalendars();

        expect(result.length, equals(2));
      });

      test('should handle multiple filters simultaneously', () async {
        mockRepository.setPermissionsGranted(true);
        const matchingCalendar = Calendar(
          id: 'cal1',
          name: 'Matching',
          accountType: 'Google',
        );
        const nonMatchingCalendar = Calendar(
          id: 'cal2',
          name: 'Non-matching',
          isReadOnly: true,
          accountType: 'Local',
        );
        mockRepository.addCalendar(matchingCalendar);
        mockRepository.addCalendar(nonMatchingCalendar);

        final result = await calendarUseCases.getFilteredCalendars(
          isReadOnly: false,
          accountType: 'Google',
        );

        expect(result.length, equals(1));
        expect(result.first.id, equals('cal1'));
      });
    });
  });
}
