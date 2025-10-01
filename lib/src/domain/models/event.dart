import 'package:calendar_bridge/src/domain/models/attendee.dart';
import 'package:calendar_bridge/src/domain/models/event_enums.dart';
import 'package:calendar_bridge/src/domain/models/reminder.dart';
import 'package:meta/meta.dart';
import 'package:rrule/rrule.dart';
import 'package:timezone/timezone.dart';

/// Represents a calendar event
@immutable
class CalendarEvent {
  /// Creates a new calendar event
  const CalendarEvent({
    required this.calendarId,
    this.eventId,
    this.title,
    this.description,
    this.start,
    this.end,
    this.allDay = false,
    this.location,
    this.url,
    this.recurrenceRule,
    this.originalStart,
    this.attendees = const [],
    this.reminders = const [],
    this.eventStatus,
    this.availability,
    this.organizer,
    this.eventColor,
  });

  /// Creates a calendar event from a JSON map
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      calendarId: json['calendarId'] as String,
      eventId: json['eventId'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      start: json['start'] != null
          ? TZDateTime.fromMillisecondsSinceEpoch(UTC, json['start'] as int)
          : null,
      end: json['end'] != null
          ? TZDateTime.fromMillisecondsSinceEpoch(UTC, json['end'] as int)
          : null,
      allDay: json['allDay'] as bool? ?? false,
      location: json['location'] as String?,
      url: json['url'] as String?,
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.fromString(json['recurrenceRule'] as String)
          : null,
      originalStart: json['originalStart'] != null
          ? TZDateTime.fromMillisecondsSinceEpoch(
              UTC,
              json['originalStart'] as int,
            )
          : null,
      attendees: (json['attendees'] as List<dynamic>?)
              ?.map((e) => Attendee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      eventStatus: json['eventStatus'] != null
          ? EventStatus.fromString(json['eventStatus'] as String)
          : null,
      availability: json['availability'] != null
          ? EventAvailability.fromString(json['availability'] as String)
          : null,
      organizer: json['organizer'] != null
          ? Attendee.fromJson(json['organizer'] as Map<String, dynamic>)
          : null,
      eventColor: json['eventColor'] as String?,
    );
  }

  /// Create a new event with required fields
  factory CalendarEvent.create({
    required String calendarId,
    required String title,
    required TZDateTime start,
    required TZDateTime end,
  }) =>
      CalendarEvent(
        calendarId: calendarId,
        title: title,
        start: start,
        end: end,
      );

  /// Create an all-day event
  factory CalendarEvent.allDay({
    required String calendarId,
    required String title,
    required TZDateTime date,
  }) =>
      CalendarEvent(
        calendarId: calendarId,
        title: title,
        start: date,
        end: date.add(const Duration(days: 1)),
        allDay: true,
      );

  /// ID of the calendar this event belongs to
  final String calendarId;

  /// Unique identifier for the event (null for new events)
  final String? eventId;

  /// Title of the event
  final String? title;

  /// Description of the event
  final String? description;

  /// Start date and time of the event
  final TZDateTime? start;

  /// End date and time of the event
  final TZDateTime? end;

  /// Whether this is an all-day event
  final bool allDay;

  /// Location of the event
  final String? location;

  /// URL associated with the event
  final String? url;

  /// Recurrence rule for recurring events
  final RecurrenceRule? recurrenceRule;

  /// Read-only. The original start date for recurring events
  final TZDateTime? originalStart;

  /// List of attendees
  final List<Attendee> attendees;

  /// List of reminders
  final List<Reminder> reminders;

  /// Status of the event
  final EventStatus? eventStatus;

  /// Availability of the event time
  final EventAvailability? availability;

  /// Organizer of the event
  final Attendee? organizer;

  /// Color of the event (hex color or color key)
  final String? eventColor;

  /// Converts the calendar event to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'calendarId': calendarId,
      'eventId': eventId,
      'title': title,
      'description': description,
      'start': start?.millisecondsSinceEpoch,
      'end': end?.millisecondsSinceEpoch,
      'allDay': allDay,
      'location': location,
      'url': url,
      'recurrenceRule': recurrenceRule?.toString(),
      'originalStart': originalStart?.millisecondsSinceEpoch,
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'eventStatus': eventStatus?.value,
      'availability': availability?.value,
      'organizer': organizer?.toJson(),
      'eventColor': eventColor,
    };
  }

  /// Creates a copy of this event with the given fields
  /// replaced with new values
  CalendarEvent copyWith({
    String? calendarId,
    String? eventId,
    String? title,
    String? description,
    TZDateTime? start,
    TZDateTime? end,
    bool? allDay,
    String? location,
    String? url,
    RecurrenceRule? recurrenceRule,
    TZDateTime? originalStart,
    List<Attendee>? attendees,
    List<Reminder>? reminders,
    EventStatus? eventStatus,
    EventAvailability? availability,
    Attendee? organizer,
    String? eventColor,
  }) {
    return CalendarEvent(
      calendarId: calendarId ?? this.calendarId,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      url: url ?? this.url,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      originalStart: originalStart ?? this.originalStart,
      attendees: attendees ?? this.attendees,
      reminders: reminders ?? this.reminders,
      eventStatus: eventStatus ?? this.eventStatus,
      availability: availability ?? this.availability,
      organizer: organizer ?? this.organizer,
      eventColor: eventColor ?? this.eventColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.calendarId == calendarId &&
        other.eventId == eventId &&
        other.title == title &&
        other.description == description &&
        other.start == start &&
        other.end == end &&
        other.allDay == allDay &&
        other.location == location &&
        other.url == url &&
        other.recurrenceRule == recurrenceRule &&
        other.originalStart == originalStart &&
        _listEquals(other.attendees, attendees) &&
        _listEquals(other.reminders, reminders) &&
        other.eventStatus == eventStatus &&
        other.availability == availability &&
        other.organizer == organizer &&
        other.eventColor == eventColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      calendarId,
      eventId,
      title,
      description,
      start,
      end,
      allDay,
      location,
      url,
      recurrenceRule,
      originalStart,
      Object.hashAll(attendees),
      Object.hashAll(reminders),
      eventStatus,
      availability,
      organizer,
      eventColor,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// Check if this event is valid
  bool get isValid {
    if (calendarId.isEmpty) return false;
    if (start == null || end == null) return false;
    if (start!.isAfter(end!)) return false;
    return true;
  }

  /// Get the duration of the event
  Duration? get duration {
    if (start == null || end == null) return null;
    return end!.difference(start!);
  }
}

/// Parameters for retrieving events
@immutable
class RetrieveEventsParams {
  /// Creates new parameters for retrieving events
  const RetrieveEventsParams({
    this.startDate,
    this.endDate,
    this.eventIds,
  });

  /// Creates parameters from a JSON map
  factory RetrieveEventsParams.fromJson(Map<String, dynamic> json) {
    return RetrieveEventsParams(
      startDate: json['startDate'] != null
          ? TZDateTime.fromMillisecondsSinceEpoch(UTC, json['startDate'] as int)
          : null,
      endDate: json['endDate'] != null
          ? TZDateTime.fromMillisecondsSinceEpoch(UTC, json['endDate'] as int)
          : null,
      eventIds: (json['eventIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Start date for the query range
  final TZDateTime? startDate;

  /// End date for the query range
  final TZDateTime? endDate;

  /// Specific event IDs to retrieve
  final List<String>? eventIds;

  /// Converts the parameters to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'eventIds': eventIds,
    };
  }

  /// Creates a copy of these parameters with the given
  /// fields replaced with new values
  RetrieveEventsParams copyWith({
    TZDateTime? startDate,
    TZDateTime? endDate,
    List<String>? eventIds,
  }) {
    return RetrieveEventsParams(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      eventIds: eventIds ?? this.eventIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetrieveEventsParams &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        _listEquals(other.eventIds, eventIds);
  }

  @override
  int get hashCode {
    return Object.hash(startDate, endDate, eventIds);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
