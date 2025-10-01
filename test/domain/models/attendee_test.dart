import 'package:calendar_bridge/src/domain/models/attendee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendee Model Tests', () {
    const testEmail = 'test@example.com';
    const testName = 'Test User';

    group('Constructor Tests', () {
      test('should create attendee with required parameters', () {
        const attendee = Attendee(email: testEmail);

        expect(attendee.email, equals(testEmail));
        expect(attendee.name, isNull);
        expect(attendee.role, equals(AttendeeRole.required));
        expect(attendee.status, equals(AttendeeStatus.unknown));
        expect(attendee.isCurrentUser, isFalse);
      });

      test('should create attendee with all parameters', () {
        const attendee = Attendee(
          email: testEmail,
          name: testName,
          role: AttendeeRole.chair,
          status: AttendeeStatus.accepted,
          isCurrentUser: true,
        );

        expect(attendee.email, equals(testEmail));
        expect(attendee.name, equals(testName));
        expect(attendee.role, equals(AttendeeRole.chair));
        expect(attendee.status, equals(AttendeeStatus.accepted));
        expect(attendee.isCurrentUser, isTrue);
      });
    });

    group('JSON Serialization Tests', () {
      test('should create attendee from JSON with all fields', () {
        final json = {
          'email': testEmail,
          'name': testName,
          'role': 'chair',
          'status': 'accepted',
          'isCurrentUser': true,
        };

        final attendee = Attendee.fromJson(json);

        expect(attendee.email, equals(testEmail));
        expect(attendee.name, equals(testName));
        expect(attendee.role, equals(AttendeeRole.chair));
        expect(attendee.status, equals(AttendeeStatus.accepted));
        expect(attendee.isCurrentUser, isTrue);
      });

      test('should create attendee from JSON with minimal fields', () {
        final json = {
          'email': testEmail,
        };

        final attendee = Attendee.fromJson(json);

        expect(attendee.email, equals(testEmail));
        expect(attendee.name, isNull);
        expect(attendee.role, equals(AttendeeRole.required));
        expect(attendee.status, equals(AttendeeStatus.unknown));
        expect(attendee.isCurrentUser, isFalse);
      });

      test('should convert attendee to JSON', () {
        const attendee = Attendee(
          email: testEmail,
          name: testName,
          role: AttendeeRole.chair,
          status: AttendeeStatus.accepted,
          isCurrentUser: true,
        );

        final json = attendee.toJson();

        expect(json['email'], equals(testEmail));
        expect(json['name'], equals(testName));
        expect(json['role'], equals('chair'));
        expect(json['status'], equals('accepted'));
        expect(json['isCurrentUser'], isTrue);
      });

      test('should convert attendee with null fields to JSON', () {
        const attendee = Attendee(email: testEmail);

        final json = attendee.toJson();

        expect(json['email'], equals(testEmail));
        expect(json['name'], isNull);
        expect(json['role'], equals('required'));
        expect(json['status'], equals('unknown'));
        expect(json['isCurrentUser'], isFalse);
      });
    });

    group('copyWith Tests', () {
      test('should copy attendee with all fields changed', () {
        const originalAttendee = Attendee(email: testEmail);

        final copiedAttendee = originalAttendee.copyWith(
          email: 'new@example.com',
          name: 'New User',
          role: AttendeeRole.optional,
          status: AttendeeStatus.declined,
          isCurrentUser: true,
        );

        expect(copiedAttendee.email, equals('new@example.com'));
        expect(copiedAttendee.name, equals('New User'));
        expect(copiedAttendee.role, equals(AttendeeRole.optional));
        expect(copiedAttendee.status, equals(AttendeeStatus.declined));
        expect(copiedAttendee.isCurrentUser, isTrue);
      });

      test('should copy attendee with no changes', () {
        const originalAttendee = Attendee(
          email: testEmail,
          name: testName,
          role: AttendeeRole.chair,
          status: AttendeeStatus.accepted,
          isCurrentUser: true,
        );

        final copiedAttendee = originalAttendee.copyWith();

        expect(copiedAttendee.email, equals(testEmail));
        expect(copiedAttendee.name, equals(testName));
        expect(copiedAttendee.role, equals(AttendeeRole.chair));
        expect(copiedAttendee.status, equals(AttendeeStatus.accepted));
        expect(copiedAttendee.isCurrentUser, isTrue);
      });

      test('should copy attendee with partial changes', () {
        const originalAttendee = Attendee(email: testEmail);

        final copiedAttendee = originalAttendee.copyWith(
          name: testName,
          status: AttendeeStatus.tentative,
        );

        expect(copiedAttendee.email, equals(testEmail));
        expect(copiedAttendee.name, equals(testName));
        expect(copiedAttendee.role, equals(AttendeeRole.required));
        expect(copiedAttendee.status, equals(AttendeeStatus.tentative));
        expect(copiedAttendee.isCurrentUser, isFalse);
      });
    });

    group('Equality Tests', () {
      test('should be equal when all fields match', () {
        const attendee1 = Attendee(
          email: testEmail,
          name: testName,
          role: AttendeeRole.chair,
          status: AttendeeStatus.accepted,
          isCurrentUser: true,
        );

        const attendee2 = Attendee(
          email: testEmail,
          name: testName,
          role: AttendeeRole.chair,
          status: AttendeeStatus.accepted,
          isCurrentUser: true,
        );

        expect(attendee1, equals(attendee2));
        expect(attendee1.hashCode, equals(attendee2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const attendee1 = Attendee(email: testEmail);
        const attendee2 = Attendee(email: 'different@example.com');

        expect(attendee1, isNot(equals(attendee2)));
      });

      test('should be identical when same instance', () {
        const attendee = Attendee(email: testEmail);

        expect(identical(attendee, attendee), isTrue);
        expect(attendee == attendee, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle empty email', () {
        const attendee = Attendee(email: '');

        expect(attendee.email, equals(''));
      });

      test('should handle invalid email format', () {
        const attendee = Attendee(email: 'not-an-email');

        expect(attendee.email, equals('not-an-email'));
      });

      test('should handle special characters in email and name', () {
        const specialEmail = 'user+test@sub.domain.com';
        const specialName = 'Użer with spéciäl châräcters';

        const attendee = Attendee(
          email: specialEmail,
          name: specialName,
        );

        expect(attendee.email, equals(specialEmail));
        expect(attendee.name, equals(specialName));
      });
    });

    group('toString Tests', () {
      test('should provide readable string representation', () {
        const attendee = Attendee(
          email: testEmail,
          name: testName,
          role: AttendeeRole.chair,
          status: AttendeeStatus.accepted,
          isCurrentUser: true,
        );

        final stringRep = attendee.toString();

        expect(stringRep, contains(testEmail));
        expect(stringRep, contains(testName));
        expect(stringRep, contains('chair'));
        expect(stringRep, contains('accepted'));
        expect(stringRep, contains('true'));
      });
    });
  });

  group('AttendeeRole Enum Tests', () {
    group('Value Tests', () {
      test('should return correct string values', () {
        expect(AttendeeRole.required.value, equals('required'));
        expect(AttendeeRole.optional.value, equals('optional'));
        expect(AttendeeRole.chair.value, equals('chair'));
        expect(AttendeeRole.nonParticipant.value, equals('non-participant'));
      });
    });

    group('fromString Tests', () {
      test('should create correct enum from valid strings', () {
        expect(
          AttendeeRole.fromString('required'),
          equals(AttendeeRole.required),
        );
        expect(
          AttendeeRole.fromString('optional'),
          equals(AttendeeRole.optional),
        );
        expect(AttendeeRole.fromString('chair'), equals(AttendeeRole.chair));
        expect(
          AttendeeRole.fromString('non-participant'),
          equals(AttendeeRole.nonParticipant),
        );
      });

      test('should return default value for invalid strings', () {
        expect(
          AttendeeRole.fromString('invalid'),
          equals(AttendeeRole.required),
        );
        expect(AttendeeRole.fromString(''), equals(AttendeeRole.required));
        expect(
          AttendeeRole.fromString('REQUIRED'),
          equals(AttendeeRole.required),
        );
      });
    });
  });

  group('AttendeeStatus Enum Tests', () {
    group('Value Tests', () {
      test('should return correct string values', () {
        expect(AttendeeStatus.unknown.value, equals('unknown'));
        expect(AttendeeStatus.pending.value, equals('pending'));
        expect(AttendeeStatus.accepted.value, equals('accepted'));
        expect(AttendeeStatus.declined.value, equals('declined'));
        expect(AttendeeStatus.tentative.value, equals('tentative'));
      });
    });

    group('fromString Tests', () {
      test('should create correct enum from valid strings', () {
        expect(
          AttendeeStatus.fromString('unknown'),
          equals(AttendeeStatus.unknown),
        );
        expect(
          AttendeeStatus.fromString('pending'),
          equals(AttendeeStatus.pending),
        );
        expect(
          AttendeeStatus.fromString('accepted'),
          equals(AttendeeStatus.accepted),
        );
        expect(
          AttendeeStatus.fromString('declined'),
          equals(AttendeeStatus.declined),
        );
        expect(
          AttendeeStatus.fromString('tentative'),
          equals(AttendeeStatus.tentative),
        );
      });

      test('should return default value for invalid strings', () {
        expect(
          AttendeeStatus.fromString('invalid'),
          equals(AttendeeStatus.unknown),
        );
        expect(AttendeeStatus.fromString(''), equals(AttendeeStatus.unknown));
        expect(
          AttendeeStatus.fromString('ACCEPTED'),
          equals(AttendeeStatus.unknown),
        );
      });
    });
  });
}
