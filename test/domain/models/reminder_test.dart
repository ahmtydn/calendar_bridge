import 'package:calendar_bridge/src/domain/models/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reminder Model Tests', () {
    const testMinutes = 30;

    group('Constructor Tests', () {
      test('should create reminder with minutes', () {
        const reminder = Reminder(minutes: testMinutes);

        expect(reminder.minutes, equals(testMinutes));
      });

      test('should create reminder with zero minutes', () {
        const reminder = Reminder(minutes: 0);

        expect(reminder.minutes, equals(0));
      });

      test('should create reminder with negative minutes', () {
        const reminder = Reminder(minutes: -10);

        expect(reminder.minutes, equals(-10));
      });
    });

    group('Factory Constructor Tests', () {
      test('atEventTime should create reminder at event time', () {
        final reminder = Reminder.atEventTime();

        expect(reminder.minutes, equals(0));
      });

      test('fiveMinutesBefore should create 5-minute reminder', () {
        final reminder = Reminder.fiveMinutesBefore();

        expect(reminder.minutes, equals(5));
      });

      test('fifteenMinutesBefore should create 15-minute reminder', () {
        final reminder = Reminder.fifteenMinutesBefore();

        expect(reminder.minutes, equals(15));
      });

      test('thirtyMinutesBefore should create 30-minute reminder', () {
        final reminder = Reminder.thirtyMinutesBefore();

        expect(reminder.minutes, equals(30));
      });

      test('oneHourBefore should create 60-minute reminder', () {
        final reminder = Reminder.oneHourBefore();

        expect(reminder.minutes, equals(60));
      });

      test('oneDayBefore should create 1440-minute reminder', () {
        final reminder = Reminder.oneDayBefore();

        expect(reminder.minutes, equals(1440));
      });

      test('oneWeekBefore should create 10080-minute reminder', () {
        final reminder = Reminder.oneWeekBefore();

        expect(reminder.minutes, equals(10080));
      });
    });

    group('JSON Serialization Tests', () {
      test('should create reminder from JSON', () {
        final json = {
          'minutes': testMinutes,
        };

        final reminder = Reminder.fromJson(json);

        expect(reminder.minutes, equals(testMinutes));
      });

      test('should convert reminder to JSON', () {
        const reminder = Reminder(minutes: testMinutes);

        final json = reminder.toJson();

        expect(json['minutes'], equals(testMinutes));
      });
    });

    group('copyWith Tests', () {
      test('should copy reminder with changed minutes', () {
        const originalReminder = Reminder(minutes: testMinutes);

        final copiedReminder = originalReminder.copyWith(minutes: 60);

        expect(copiedReminder.minutes, equals(60));
      });

      test('should copy reminder with no changes', () {
        const originalReminder = Reminder(minutes: testMinutes);

        final copiedReminder = originalReminder.copyWith();

        expect(copiedReminder.minutes, equals(testMinutes));
      });
    });

    group('Description Tests', () {
      test('should return correct description for event time', () {
        final reminder = Reminder.atEventTime();

        expect(reminder.description, equals('At event time'));
      });

      test('should return correct description for minutes', () {
        const reminder = Reminder(minutes: 15);

        expect(reminder.description, equals('15 minutes before'));
      });

      test('should return correct description for single minute', () {
        const reminder = Reminder(minutes: 1);

        expect(reminder.description, equals('1 minutes before'));
      });

      test('should return correct description for hours', () {
        const reminder = Reminder(minutes: 120); // 2 hours

        expect(reminder.description, equals('2 hours before'));
      });

      test('should return correct description for single hour', () {
        const reminder = Reminder(minutes: 60);

        expect(reminder.description, equals('1 hours before'));
      });

      test('should return correct description for days', () {
        const reminder = Reminder(minutes: 2880); // 2 days

        expect(reminder.description, equals('2 days before'));
      });

      test('should return correct description for single day', () {
        final reminder = Reminder.oneDayBefore();

        expect(reminder.description, equals('1 days before'));
      });

      test('should return correct description for weeks', () {
        const reminder = Reminder(minutes: 20160); // 2 weeks

        expect(reminder.description, equals('2 weeks before'));
      });

      test('should return correct description for single week', () {
        final reminder = Reminder.oneWeekBefore();

        expect(reminder.description, equals('1 weeks before'));
      });

      test('should handle edge case for 59 minutes', () {
        const reminder = Reminder(minutes: 59);

        expect(reminder.description, equals('59 minutes before'));
      });

      test('should handle edge case for 61 minutes', () {
        const reminder = Reminder(minutes: 61);

        expect(reminder.description, equals('1 hours before'));
      });

      test('should handle large numbers of weeks', () {
        const reminder = Reminder(minutes: 50400); // 5 weeks

        expect(reminder.description, equals('5 weeks before'));
      });
    });

    group('Equality Tests', () {
      test('should be equal when minutes match', () {
        const reminder1 = Reminder(minutes: testMinutes);
        const reminder2 = Reminder(minutes: testMinutes);

        expect(reminder1, equals(reminder2));
        expect(reminder1.hashCode, equals(reminder2.hashCode));
      });

      test('should not be equal when minutes differ', () {
        const reminder1 = Reminder(minutes: testMinutes);
        const reminder2 = Reminder(minutes: 60);

        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should be identical when same instance', () {
        const reminder = Reminder(minutes: testMinutes);

        expect(identical(reminder, reminder), isTrue);
        expect(reminder == reminder, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle very large numbers', () {
        const reminder = Reminder(minutes: 1000000);

        expect(reminder.minutes, equals(1000000));
        expect(reminder.description, contains('weeks before'));
      });

      test('should handle zero minutes correctly', () {
        const reminder = Reminder(minutes: 0);

        expect(reminder.description, equals('At event time'));
      });

      test('should handle negative minutes', () {
        const reminder = Reminder(minutes: -30);

        expect(reminder.minutes, equals(-30));
        expect(reminder.description, equals('-30 minutes before'));
      });
    });

    group('toString Tests', () {
      test('should provide readable string representation', () {
        const reminder = Reminder(minutes: testMinutes);

        final stringRep = reminder.toString();

        expect(stringRep, contains(testMinutes.toString()));
        expect(stringRep, contains('Reminder'));
      });
    });
  });
}
