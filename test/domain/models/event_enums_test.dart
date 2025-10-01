import 'package:calendar_bridge/src/domain/models/event_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventStatus Enum Tests', () {
    group('Value Tests', () {
      test('should have correct string values', () {
        expect(EventStatus.confirmed.value, equals('CONFIRMED'));
        expect(EventStatus.tentative.value, equals('TENTATIVE'));
        expect(EventStatus.canceled.value, equals('CANCELED'));
        expect(EventStatus.none.value, equals('NONE'));
      });
    });

    group('fromString Tests', () {
      test('should create correct enum from valid strings', () {
        expect(
          EventStatus.fromString('CONFIRMED'),
          equals(EventStatus.confirmed),
        );
        expect(
          EventStatus.fromString('TENTATIVE'),
          equals(EventStatus.tentative),
        );
        expect(
          EventStatus.fromString('CANCELED'),
          equals(EventStatus.canceled),
        );
        expect(EventStatus.fromString('NONE'), equals(EventStatus.none));
      });

      test('should create correct enum from lowercase strings', () {
        expect(
          EventStatus.fromString('confirmed'),
          equals(EventStatus.confirmed),
        );
        expect(
          EventStatus.fromString('tentative'),
          equals(EventStatus.tentative),
        );
        expect(
          EventStatus.fromString('canceled'),
          equals(EventStatus.canceled),
        );
        expect(EventStatus.fromString('none'), equals(EventStatus.none));
      });

      test('should create correct enum from mixed case strings', () {
        expect(
          EventStatus.fromString('Confirmed'),
          equals(EventStatus.confirmed),
        );
        expect(
          EventStatus.fromString('Tentative'),
          equals(EventStatus.tentative),
        );
        expect(
          EventStatus.fromString('Canceled'),
          equals(EventStatus.canceled),
        );
        expect(EventStatus.fromString('None'), equals(EventStatus.none));
      });

      test('should return none for invalid strings', () {
        expect(EventStatus.fromString('invalid'), equals(EventStatus.none));
        expect(EventStatus.fromString(''), equals(EventStatus.none));
        expect(EventStatus.fromString('unknown'), equals(EventStatus.none));
      });
    });

    group('toString Tests', () {
      test('should return correct string values', () {
        expect(EventStatus.confirmed.toString(), equals('CONFIRMED'));
        expect(EventStatus.tentative.toString(), equals('TENTATIVE'));
        expect(EventStatus.canceled.toString(), equals('CANCELED'));
        expect(EventStatus.none.toString(), equals('NONE'));
      });
    });

    group('Enum Values Tests', () {
      test('should have all expected values', () {
        const values = EventStatus.values;

        expect(values.length, equals(4));
        expect(values, contains(EventStatus.confirmed));
        expect(values, contains(EventStatus.tentative));
        expect(values, contains(EventStatus.canceled));
        expect(values, contains(EventStatus.none));
      });
    });
  });

  group('EventAvailability Enum Tests', () {
    group('Value Tests', () {
      test('should have correct string values', () {
        expect(EventAvailability.busy.value, equals('BUSY'));
        expect(EventAvailability.free.value, equals('FREE'));
        expect(EventAvailability.tentative.value, equals('TENTATIVE'));
        expect(EventAvailability.unavailable.value, equals('UNAVAILABLE'));
      });
    });

    group('fromString Tests', () {
      test('should create correct enum from valid strings', () {
        expect(
          EventAvailability.fromString('BUSY'),
          equals(EventAvailability.busy),
        );
        expect(
          EventAvailability.fromString('FREE'),
          equals(EventAvailability.free),
        );
        expect(
          EventAvailability.fromString('TENTATIVE'),
          equals(EventAvailability.tentative),
        );
        expect(
          EventAvailability.fromString('UNAVAILABLE'),
          equals(EventAvailability.unavailable),
        );
      });

      test('should create correct enum from lowercase strings', () {
        expect(
          EventAvailability.fromString('busy'),
          equals(EventAvailability.busy),
        );
        expect(
          EventAvailability.fromString('free'),
          equals(EventAvailability.free),
        );
        expect(
          EventAvailability.fromString('tentative'),
          equals(EventAvailability.tentative),
        );
        expect(
          EventAvailability.fromString('unavailable'),
          equals(EventAvailability.unavailable),
        );
      });

      test('should create correct enum from mixed case strings', () {
        expect(
          EventAvailability.fromString('Busy'),
          equals(EventAvailability.busy),
        );
        expect(
          EventAvailability.fromString('Free'),
          equals(EventAvailability.free),
        );
        expect(
          EventAvailability.fromString('Tentative'),
          equals(EventAvailability.tentative),
        );
        expect(
          EventAvailability.fromString('Unavailable'),
          equals(EventAvailability.unavailable),
        );
      });

      test('should return busy for invalid strings', () {
        expect(
          EventAvailability.fromString('invalid'),
          equals(EventAvailability.busy),
        );
        expect(
          EventAvailability.fromString(''),
          equals(EventAvailability.busy),
        );
        expect(
          EventAvailability.fromString('unknown'),
          equals(EventAvailability.busy),
        );
      });
    });

    group('toString Tests', () {
      test('should return correct string values', () {
        expect(EventAvailability.busy.toString(), equals('BUSY'));
        expect(EventAvailability.free.toString(), equals('FREE'));
        expect(EventAvailability.tentative.toString(), equals('TENTATIVE'));
        expect(EventAvailability.unavailable.toString(), equals('UNAVAILABLE'));
      });
    });

    group('Enum Values Tests', () {
      test('should have all expected values', () {
        const values = EventAvailability.values;

        expect(values.length, equals(4));
        expect(values, contains(EventAvailability.busy));
        expect(values, contains(EventAvailability.free));
        expect(values, contains(EventAvailability.tentative));
        expect(values, contains(EventAvailability.unavailable));
      });
    });
  });

  group('Edge Cases', () {
    test('should handle null and whitespace strings for EventStatus', () {
      expect(EventStatus.fromString(''), equals(EventStatus.none));
      expect(EventStatus.fromString('   '), equals(EventStatus.none));
    });

    test('should handle null and whitespace strings for EventAvailability', () {
      expect(EventAvailability.fromString(''), equals(EventAvailability.busy));
      expect(
        EventAvailability.fromString('   '),
        equals(EventAvailability.busy),
      );
    });

    test('should handle special characters in strings', () {
      expect(EventStatus.fromString('CONFIRMED!'), equals(EventStatus.none));
      expect(
        EventStatus.fromString('CONFIRMED-STATUS'),
        equals(EventStatus.none),
      );
      expect(
        EventAvailability.fromString('BUSY!'),
        equals(EventAvailability.busy),
      );
      expect(
        EventAvailability.fromString('BUSY-STATUS'),
        equals(EventAvailability.busy),
      );
    });
  });
}
