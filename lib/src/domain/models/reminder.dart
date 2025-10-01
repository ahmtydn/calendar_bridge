import 'package:meta/meta.dart';

/// Represents a reminder for a calendar event
@immutable
class Reminder {
  /// Creates a new reminder
  const Reminder({
    /// Minutes before the event to trigger the reminder
    required this.minutes,
  });

  /// Create a Reminder from JSON
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      minutes: json['minutes'] as int,
    );
  }

  /// Create a reminder that triggers at the event start time
  factory Reminder.atEventTime() => const Reminder(minutes: 0);

  /// Create a reminder that triggers 5 minutes before the event
  factory Reminder.fiveMinutesBefore() => const Reminder(minutes: 5);

  /// Create a reminder that triggers 15 minutes before the event
  factory Reminder.fifteenMinutesBefore() => const Reminder(minutes: 15);

  /// Create a reminder that triggers 30 minutes before the event
  factory Reminder.thirtyMinutesBefore() => const Reminder(minutes: 30);

  /// Create a reminder that triggers 1 hour before the event
  factory Reminder.oneHourBefore() => const Reminder(minutes: 60);

  /// Create a reminder that triggers 1 day before the event
  factory Reminder.oneDayBefore() => const Reminder(minutes: 1440);

  /// Create a reminder that triggers 1 week before the event
  factory Reminder.oneWeekBefore() => const Reminder(minutes: 10080);

  /// Minutes before the event to trigger the reminder
  final int minutes;

  /// Convert Reminder to JSON
  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes,
    };
  }

  /// Create a copy of this Reminder with modified properties
  Reminder copyWith({
    int? minutes,
  }) {
    return Reminder(
      minutes: minutes ?? this.minutes,
    );
  }

  /// Get a human-readable description of the reminder
  String get description {
    if (minutes == 0) return 'At event time';
    if (minutes < 60) return '$minutes minutes before';
    if (minutes < 1440) return '${(minutes / 60).round()} hours before';
    if (minutes < 10080) return '${(minutes / 1440).round()} days before';
    return '${(minutes / 10080).round()} weeks before';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Reminder) return false;
    return minutes == other.minutes;
  }

  @override
  int get hashCode {
    return minutes.hashCode;
  }

  @override
  String toString() {
    return 'Reminder(minutes: $minutes)';
  }
}
