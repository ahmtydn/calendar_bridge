# Calendar Bridge

[![pub package](https://img.shields.io/pub/v/calendar_bridge.svg)](https://pub.dev/packages/calendar_bridge)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20macos-lightgrey)](https://pub.dev/packages/calendar_bridge)

A comprehensive Flutter plugin for accessing and managing device calendars on Android, iOS, and macOS with clean architecture principles.

## Table of Contents

- [Features](#features)
- [Platform Support](#platform-support)
- [Installation](#installation)
- [Platform Setup](#platform-setup)
- [Usage](#usage)
  - [Basic Setup](#basic-setup)
  - [Permission Handling](#permission-handling)
  - [Working with Calendars](#working-with-calendars)
  - [Working with Events](#working-with-events)
  - [Recurring Events](#recurring-events)
  - [Calendar Colors](#calendar-colors)
- [Error Handling](#error-handling)
- [Models](#models)
- [Example App](#example-app)
- [Testing](#testing)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Features

- **Calendar Management**: Create, retrieve, and delete calendars
- **Event CRUD Operations**: Full create, read, update, delete support for events
- **Recurring Events**: Support for recurring events using RRULE format
- **Timezone Support**: Full timezone handling with TZDateTime
- **Attendee Management**: Add and manage event attendees
- **Reminders**: Set and manage event reminders
- **Permission Handling**: Proper permission management across platforms
- **Calendar Colors**: Support for calendar and event colors
- **Clean Architecture**: Built with domain-driven design principles
- **Well Tested**: Comprehensive test coverage

## Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Android  | Yes | API 21+ |
| iOS      | Yes | iOS 1+ |
| macOS    | Yes | macOS 11+ |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  calendar_bridge: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### iOS & macOS

Add the following keys to your `Info.plist` file:

```xml
<key>NSCalendarsUsageDescription</key>
<string>This app requires access to your calendar to manage your events.</string>
<!-- Full access for macOS 14+ -->
<key>NSCalendarsFullAccessUsageDescription</key>
<string>This app requires full calendar access to create, edit, and delete your events.</string>
<!-- Additional write access -->
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>This app requires access to create calendar events.</string>
<key>NSRemindersUsageDescription</key>
<string>This app needs access to reminders to set event notifications</string>
```

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

## Usage

### Basic Setup

```dart
import 'package:calendar_bridge/calendar_bridge.dart';

final calendarApi = CalendarBridge();
```

### Permission Handling

Always request permissions before accessing calendar data:

```dart
// Check if permissions are granted
final hasPermissions = await calendarApi.hasPermissions();
if (hasPermissions != PermissionStatus.granted) {
  // Request permissions
  final granted = await calendarApi.requestPermissions();
  if (!granted) {
    // Handle permission denied
    return;
  }
}
```

### Working with Calendars

#### Get All Calendars

```dart
try {
  final calendars = await calendarApi.getCalendars();
  for (final calendar in calendars) {
    print('Calendar: ${calendar.name} (${calendar.id})');
  }
} catch (e) {
  print('Error getting calendars: $e');
}
```

#### Create a New Calendar

```dart
try {
  final newCalendar = await calendarApi.createCalendar(
    name: 'My Custom Calendar',
    color: 0xFF2196F3, // Blue color
    localAccountName: 'Local',
  );
  print('Created calendar: ${newCalendar.name}');
} catch (e) {
  print('Error creating calendar: $e');
}
```

#### Get Default Calendar

```dart
try {
  final defaultCalendar = await calendarApi.getDefaultCalendar();
  print('Default calendar: ${defaultCalendar.name}');
} catch (e) {
  print('Error getting default calendar: $e');
}
```

### Working with Events

#### Create a Simple Event

```dart
try {
  final eventId = await calendarApi.createSimpleEvent(
    calendarId: calendar.id,
    title: 'Team Meeting',
    start: DateTime.now().add(Duration(hours: 1)),
    end: DateTime.now().add(Duration(hours: 2)),
    description: 'Weekly team sync',
    location: 'Conference Room A',
  );
  print('Created event with ID: $eventId');
} catch (e) {
  print('Error creating event: $e');
}
```

#### Create a Complex Event with Attendees and Reminders

```dart
final event = CalendarEvent(
  calendarId: calendar.id,
  title: 'Project Review',
  description: 'Quarterly project review meeting',
  start: TZDateTime.from(DateTime.now().add(Duration(days: 1)), UTC),
  end: TZDateTime.from(DateTime.now().add(Duration(days: 1, hours: 2)), UTC),
  location: 'Meeting Room B',
  attendees: [
    Attendee(
      name: 'John Doe',
      email: 'john@example.com',
      role: AttendeeRole.required,
    ),
    Attendee(
      name: 'Jane Smith',
      email: 'jane@example.com',
      role: AttendeeRole.optional,
    ),
  ],
  reminders: [
    Reminder(minutes: 15), // 15 minutes before
    Reminder(minutes: 60), // 1 hour before
  ],
);

try {
  final eventId = await calendarApi.createEvent(event);
  print('Created complex event with ID: $eventId');
} catch (e) {
  print('Error creating event: $e');
}
```

#### Get Events from a Calendar

```dart
try {
  // Get all events
  final allEvents = await calendarApi.getEvents(calendar.id);
  
  // Get events in a date range
  final eventsInRange = await calendarApi.getEvents(
    calendar.id,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(Duration(days: 30)),
  );
  
  // Get today's events
  final todaysEvents = await calendarApi.getTodaysEvents(calendar.id);
  
  // Get upcoming events (next 7 days by default)
  final upcomingEvents = await calendarApi.getUpcomingEvents(calendar.id);
  
  print('Found ${allEvents.length} total events');
} catch (e) {
  print('Error getting events: $e');
}
```

#### Update an Event

```dart
// First, get the event
final events = await calendarApi.getEvents(calendar.id);
if (events.isNotEmpty) {
  final eventToUpdate = events.first.copyWith(
    title: 'Updated Event Title',
    description: 'Updated description',
  );
  
  try {
    await calendarApi.updateEvent(eventToUpdate);
    print('Event updated successfully');
  } catch (e) {
    print('Error updating event: $e');
  }
}
```

#### Delete an Event

```dart
try {
  final success = await calendarApi.deleteEvent(calendar.id, eventId);
  if (success) {
    print('Event deleted successfully');
  }
} catch (e) {
  print('Error deleting event: $e');
}
```

### Recurring Events

Calendar Bridge supports recurring events using the RRULE standard:

```dart
import 'package:rrule/rrule.dart';

final recurringEvent = CalendarEvent(
  calendarId: calendar.id,
  title: 'Daily Standup',
  start: TZDateTime.from(DateTime.now(), UTC),
  end: TZDateTime.from(DateTime.now().add(Duration(minutes: 30)), UTC),
  recurrenceRule: RecurrenceRule(
    frequency: Frequency.daily,
    count: 30, // Repeat 30 times
  ),
);

await calendarApi.createEvent(recurringEvent);
```

### Calendar Colors

Get and set calendar colors:

```dart
// Get available calendar colors
final calendarColors = await calendarApi.getCalendarColors();
print('Available calendar colors: $calendarColors');

// Get available event colors for a calendar
final eventColors = await calendarApi.getEventColors(calendar.id);
print('Available event colors: $eventColors');

// Update calendar color
if (calendarColors != null && calendarColors.isNotEmpty) {
  final colorKey = calendarColors.keys.first;
  await calendarApi.updateCalendarColor(calendar.id, colorKey);
}
```

## Error Handling

Calendar Bridge provides specific exception types for better error handling:

```dart
try {
  final calendars = await calendarApi.getCalendars();
} on PermissionDeniedException {
  print('Calendar permissions are required');
} on CalendarNotFoundException {
  print('Calendar not found');
} on EventNotFoundException {
  print('Event not found');
} on InvalidArgumentException {
  print('Invalid arguments provided');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Models

### Calendar

```dart
class Calendar {
  final String id;
  final String name;
  final int? color;
  final String? accountName;
  final String? accountType;
  final bool isReadOnly;
  final bool isDefault;
}
```

### CalendarEvent

```dart
class CalendarEvent {
  final String calendarId;
  final String? eventId;
  final String? title;
  final String? description;
  final TZDateTime? start;
  final TZDateTime? end;
  final bool allDay;
  final String? location;
  final String? url;
  final RecurrenceRule? recurrenceRule;
  final List<Attendee> attendees;
  final List<Reminder> reminders;
  final EventStatus? eventStatus;
  final Availability? availability;
  final String? organizer;
  final String? eventColor;
}
```

### Attendee

```dart
class Attendee {
  final String? name;
  final String? email;
  final AttendeeRole? role;
  final AttendeeStatus? status;
}
```

### Reminder

```dart
class Reminder {
  final int minutes; // Minutes before event start
}
```

## Example App

The plugin comes with a comprehensive example app that demonstrates all features. To run the example:

```bash
cd example
flutter run
```

The example app includes:
- Calendar list view
- Event management (create, edit, delete)
- Calendar view with monthly grid
- Settings and permissions handling

## Testing

Calendar Bridge includes comprehensive test coverage. Run tests with:

```bash
flutter test
```

For integration tests:

```bash
cd example
flutter test integration_test/
```

## Architecture

This plugin follows clean architecture principles:

- **Domain Layer**: Contains business logic, entities, and use cases
- **Infrastructure Layer**: Platform-specific implementations
- **API Layer**: Simple, clean interface for consumers

## Contributing

Contributions are welcome! Please read the contributing guidelines and submit pull requests to the [GitHub repository](https://github.com/ahmtydn/calendar_bridge).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please [file an issue](https://github.com/ahmtydn/calendar_bridge/issues) on GitHub.