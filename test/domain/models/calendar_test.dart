import 'package:calendar_bridge/src/domain/models/calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calendar Model Tests', () {
    const testId = 'test_id';
    const testName = 'Test Calendar';
    const testColor = 0xFF0000FF;
    const testAccountName = 'test@example.com';
    const testAccountType = 'Google';

    group('Constructor Tests', () {
      test('should create calendar with required parameters', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
        );

        expect(calendar.id, equals(testId));
        expect(calendar.name, equals(testName));
        expect(calendar.color, isNull);
        expect(calendar.accountName, isNull);
        expect(calendar.accountType, isNull);
        expect(calendar.isReadOnly, isFalse);
        expect(calendar.isDefault, isFalse);
      });

      test('should create calendar with all parameters', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        expect(calendar.id, equals(testId));
        expect(calendar.name, equals(testName));
        expect(calendar.color, equals(testColor));
        expect(calendar.accountName, equals(testAccountName));
        expect(calendar.accountType, equals(testAccountType));
        expect(calendar.isReadOnly, isTrue);
        expect(calendar.isDefault, isTrue);
      });
    });

    group('JSON Serialization Tests', () {
      test('should create calendar from JSON with all fields', () {
        final json = {
          'id': testId,
          'name': testName,
          'color': testColor,
          'accountName': testAccountName,
          'accountType': testAccountType,
          'isReadOnly': true,
          'isDefault': true,
        };

        final calendar = Calendar.fromJson(json);

        expect(calendar.id, equals(testId));
        expect(calendar.name, equals(testName));
        expect(calendar.color, equals(testColor));
        expect(calendar.accountName, equals(testAccountName));
        expect(calendar.accountType, equals(testAccountType));
        expect(calendar.isReadOnly, isTrue);
        expect(calendar.isDefault, isTrue);
      });

      test('should create calendar from JSON with minimal fields', () {
        final json = {
          'id': testId,
          'name': testName,
        };

        final calendar = Calendar.fromJson(json);

        expect(calendar.id, equals(testId));
        expect(calendar.name, equals(testName));
        expect(calendar.color, isNull);
        expect(calendar.accountName, isNull);
        expect(calendar.accountType, isNull);
        expect(calendar.isReadOnly, isFalse);
        expect(calendar.isDefault, isFalse);
      });

      test('should convert calendar to JSON', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        final json = calendar.toJson();

        expect(json['id'], equals(testId));
        expect(json['name'], equals(testName));
        expect(json['color'], equals(testColor));
        expect(json['accountName'], equals(testAccountName));
        expect(json['accountType'], equals(testAccountType));
        expect(json['isReadOnly'], isTrue);
        expect(json['isDefault'], isTrue);
      });

      test('should convert calendar with null fields to JSON', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
        );

        final json = calendar.toJson();

        expect(json['id'], equals(testId));
        expect(json['name'], equals(testName));
        expect(json['color'], isNull);
        expect(json['accountName'], isNull);
        expect(json['accountType'], isNull);
        expect(json['isReadOnly'], isFalse);
        expect(json['isDefault'], isFalse);
      });
    });

    group('copyWith Tests', () {
      test('should copy calendar with all fields changed', () {
        const originalCalendar = Calendar(
          id: testId,
          name: testName,
        );

        final copiedCalendar = originalCalendar.copyWith(
          id: 'new_id',
          name: 'New Name',
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        expect(copiedCalendar.id, equals('new_id'));
        expect(copiedCalendar.name, equals('New Name'));
        expect(copiedCalendar.color, equals(testColor));
        expect(copiedCalendar.accountName, equals(testAccountName));
        expect(copiedCalendar.accountType, equals(testAccountType));
        expect(copiedCalendar.isReadOnly, isTrue);
        expect(copiedCalendar.isDefault, isTrue);
      });

      test('should copy calendar with no changes', () {
        const originalCalendar = Calendar(
          id: testId,
          name: testName,
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        final copiedCalendar = originalCalendar.copyWith();

        expect(copiedCalendar.id, equals(testId));
        expect(copiedCalendar.name, equals(testName));
        expect(copiedCalendar.color, equals(testColor));
        expect(copiedCalendar.accountName, equals(testAccountName));
        expect(copiedCalendar.accountType, equals(testAccountType));
        expect(copiedCalendar.isReadOnly, isTrue);
        expect(copiedCalendar.isDefault, isTrue);
      });

      test('should copy calendar with partial changes', () {
        const originalCalendar = Calendar(
          id: testId,
          name: testName,
        );

        final copiedCalendar = originalCalendar.copyWith(
          name: 'Updated Name',
          isReadOnly: true,
        );

        expect(copiedCalendar.id, equals(testId));
        expect(copiedCalendar.name, equals('Updated Name'));
        expect(copiedCalendar.color, isNull);
        expect(copiedCalendar.accountName, isNull);
        expect(copiedCalendar.accountType, isNull);
        expect(copiedCalendar.isReadOnly, isTrue);
        expect(copiedCalendar.isDefault, isFalse);
      });
    });

    group('Equality Tests', () {
      test('should be equal when all fields match', () {
        const calendar1 = Calendar(
          id: testId,
          name: testName,
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        const calendar2 = Calendar(
          id: testId,
          name: testName,
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        expect(calendar1, equals(calendar2));
        expect(calendar1.hashCode, equals(calendar2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const calendar1 = Calendar(
          id: testId,
          name: testName,
        );

        const calendar2 = Calendar(
          id: 'different_id',
          name: testName,
        );

        expect(calendar1, isNot(equals(calendar2)));
      });

      test('should be identical when same instance', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
        );

        expect(identical(calendar, calendar), isTrue);
        expect(calendar == calendar, isTrue);
      });

      test('should not be equal to different type', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
        );

        // Test that calendar is not equal to string (using Object.equals)
        expect(
          calendar == const Calendar(id: 'different', name: 'different'),
          isFalse,
        );
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        const calendar = Calendar(
          id: '',
          name: '',
          accountName: '',
          accountType: '',
        );

        expect(calendar.id, equals(''));
        expect(calendar.name, equals(''));
        expect(calendar.accountName, equals(''));
        expect(calendar.accountType, equals(''));
      });

      test('should handle special characters in strings', () {
        const specialId = 'id@#\$%^&*(){}[]|\\:";\'<>?,./-_+=`~';
        const specialName = 'Calendar with émojis 📅 and spéciäl characters';

        const calendar = Calendar(
          id: specialId,
          name: specialName,
        );

        expect(calendar.id, equals(specialId));
        expect(calendar.name, equals(specialName));
      });

      test('should handle color edge values', () {
        const calendar1 = Calendar(
          id: testId,
          name: testName,
          color: 0x00000000, // Transparent black
        );

        const calendar2 = Calendar(
          id: testId,
          name: testName,
          color: 0xFFFFFFFF, // Opaque white
        );

        expect(calendar1.color, equals(0x00000000));
        expect(calendar2.color, equals(0xFFFFFFFF));
      });
    });

    group('toString Tests', () {
      test('should provide readable string representation', () {
        const calendar = Calendar(
          id: testId,
          name: testName,
          color: testColor,
          accountName: testAccountName,
          accountType: testAccountType,
          isReadOnly: true,
          isDefault: true,
        );

        final stringRep = calendar.toString();

        expect(stringRep, contains(testId));
        expect(stringRep, contains(testName));
        expect(stringRep, contains(testColor.toString()));
        expect(stringRep, contains(testAccountName));
        expect(stringRep, contains(testAccountType));
        expect(stringRep, contains('true'));
      });
    });
  });
}
