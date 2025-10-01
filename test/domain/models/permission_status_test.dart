import 'package:calendar_bridge/src/domain/models/permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionStatus Enum Tests', () {
    group('Value Tests', () {
      test('should have correct platform values', () {
        expect(PermissionStatus.granted.platformValue, equals('granted'));
        expect(PermissionStatus.denied.platformValue, equals('denied'));
        expect(PermissionStatus.restricted.platformValue, equals('restricted'));
        expect(
          PermissionStatus.notDetermined.platformValue,
          equals('notDetermined'),
        );
      });
    });

    group('Boolean Property Tests', () {
      test('isGranted should return true only for granted status', () {
        expect(PermissionStatus.granted.isGranted, isTrue);
        expect(PermissionStatus.denied.isGranted, isFalse);
        expect(PermissionStatus.restricted.isGranted, isFalse);
        expect(PermissionStatus.notDetermined.isGranted, isFalse);
      });

      test('isDenied should return true only for denied status', () {
        expect(PermissionStatus.granted.isDenied, isFalse);
        expect(PermissionStatus.denied.isDenied, isTrue);
        expect(PermissionStatus.restricted.isDenied, isFalse);
        expect(PermissionStatus.notDetermined.isDenied, isFalse);
      });

      test('isRestricted should return true only for restricted status', () {
        expect(PermissionStatus.granted.isRestricted, isFalse);
        expect(PermissionStatus.denied.isRestricted, isFalse);
        expect(PermissionStatus.restricted.isRestricted, isTrue);
        expect(PermissionStatus.notDetermined.isRestricted, isFalse);
      });

      test('isNotDetermined should return true only for notDetermined status',
          () {
        expect(PermissionStatus.granted.isNotDetermined, isFalse);
        expect(PermissionStatus.denied.isNotDetermined, isFalse);
        expect(PermissionStatus.restricted.isNotDetermined, isFalse);
        expect(PermissionStatus.notDetermined.isNotDetermined, isTrue);
      });
    });

    group('fromPlatformValue Tests', () {
      test('should create correct enum from valid platform values', () {
        expect(
          PermissionStatus.fromPlatformValue('granted'),
          equals(PermissionStatus.granted),
        );
        expect(
          PermissionStatus.fromPlatformValue('denied'),
          equals(PermissionStatus.denied),
        );
        expect(
          PermissionStatus.fromPlatformValue('restricted'),
          equals(PermissionStatus.restricted),
        );
        expect(
          PermissionStatus.fromPlatformValue('notDetermined'),
          equals(PermissionStatus.notDetermined),
        );
      });

      test('should throw ArgumentError for invalid platform values', () {
        expect(
          () => PermissionStatus.fromPlatformValue('invalid'),
          throwsArgumentError,
        );
        expect(
          () => PermissionStatus.fromPlatformValue(''),
          throwsArgumentError,
        );
        expect(
          () => PermissionStatus.fromPlatformValue('GRANTED'),
          throwsArgumentError,
        );
      });
    });

    group('JSON Serialization Tests', () {
      test('should convert to JSON correctly', () {
        final grantedJson = PermissionStatus.granted.toJson();
        final deniedJson = PermissionStatus.denied.toJson();
        final restrictedJson = PermissionStatus.restricted.toJson();
        final notDeterminedJson = PermissionStatus.notDetermined.toJson();

        expect(grantedJson['status'], equals('granted'));
        expect(deniedJson['status'], equals('denied'));
        expect(restrictedJson['status'], equals('restricted'));
        expect(notDeterminedJson['status'], equals('notDetermined'));
      });

      test('should create from JSON correctly', () {
        final grantedStatus = PermissionStatus.fromJson({'status': 'granted'});
        final deniedStatus = PermissionStatus.fromJson({'status': 'denied'});
        final restrictedStatus =
            PermissionStatus.fromJson({'status': 'restricted'});
        final notDeterminedStatus =
            PermissionStatus.fromJson({'status': 'notDetermined'});

        expect(grantedStatus, equals(PermissionStatus.granted));
        expect(deniedStatus, equals(PermissionStatus.denied));
        expect(restrictedStatus, equals(PermissionStatus.restricted));
        expect(notDeterminedStatus, equals(PermissionStatus.notDetermined));
      });

      test('should throw error when creating from invalid JSON', () {
        expect(
          () => PermissionStatus.fromJson({'status': 'invalid'}),
          throwsArgumentError,
        );
        expect(() => PermissionStatus.fromJson({}), throwsA(isA<TypeError>()));
      });
    });

    group('Enum Values Tests', () {
      test('should have all expected values', () {
        const values = PermissionStatus.values;

        expect(values.length, equals(4));
        expect(values, contains(PermissionStatus.granted));
        expect(values, contains(PermissionStatus.denied));
        expect(values, contains(PermissionStatus.restricted));
        expect(values, contains(PermissionStatus.notDetermined));
      });
    });

    group('Edge Cases', () {
      test('should handle case sensitivity in platform values', () {
        // Platform values are case-sensitive, so these should throw
        expect(
          () => PermissionStatus.fromPlatformValue('Granted'),
          throwsArgumentError,
        );
        expect(
          () => PermissionStatus.fromPlatformValue('DENIED'),
          throwsArgumentError,
        );
      });

      test('should maintain immutability', () {
        const status = PermissionStatus.granted;

        expect(status.platformValue, equals('granted'));
        expect(status.isGranted, isTrue);

        // Enum values are immutable by default
        expect(status, equals(PermissionStatus.granted));
      });
    });

    group('toString Tests', () {
      test('should provide meaningful string representation', () {
        const statuses = PermissionStatus.values;

        for (final status in statuses) {
          final stringRep = status.toString();
          expect(stringRep, isNotEmpty);
          expect(stringRep, contains('PermissionStatus'));
        }
      });
    });
  });
}
