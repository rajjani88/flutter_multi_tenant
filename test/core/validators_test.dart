import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_multi_tenant/core/utils/validators.dart';

void main() {
  group('Validators - Email', () {
    test('returns error when email is null or empty', () {
      expect(Validators.validateEmail(null), 'Email is required');
      expect(Validators.validateEmail(''), 'Email is required');
      expect(Validators.validateEmail('   '), 'Email is required');
    });

    test('returns error for invalid email formats', () {
      const invalidEmails = [
        'plainaddress',
        '#@%^%#\$@#\$@#.com',
        '@example.com',
        'email.example.com',
        'email@example@example.com',
        'email@example',
        'raj@',
        'raj@test',
        'raj@test.',
        'raj@.com',
        'raj@test.c', // Needs at least 2 char TLD
      ];

      for (final email in invalidEmails) {
        expect(
          Validators.validateEmail(email),
          'Please enter a valid email address',
          reason: 'Failed for invalid email: $email',
        );
      }
    });

    test('returns null for valid emails', () {
      const validEmails = [
        'raj@test.com',
        'emp1@test.com',
        'user.name@domain.co',
        'first.last+newsletter@sub.company.org',
        'jane_doe123@domain.io',
        '  raj@test.com  ', // Valid with trimming
      ];

      for (final email in validEmails) {
        expect(
          Validators.validateEmail(email),
          isNull,
          reason: 'Failed for valid email: $email',
        );
      }
    });
  });

  group('Validators - Password', () {
    test('returns error when password is null or empty', () {
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword(''), 'Password is required');
    });

    test('returns error when password is less than 6 characters', () {
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
      expect(Validators.validatePassword('a'), 'Password must be at least 6 characters');
    });

    test('returns null when password is 6 or more characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('StrongPassword!2026'), isNull);
    });
  });

  group('Validators - Name', () {
    test('returns error when name is null or empty', () {
      expect(Validators.validateName(null), 'Name is required');
      expect(Validators.validateName(''), 'Name is required');
      expect(Validators.validateName('   '), 'Name is required');
    });

    test('returns error when name is less than 2 characters', () {
      expect(Validators.validateName('a'), 'Name must be at least 2 characters');
      expect(Validators.validateName(' a '), 'Name must be at least 2 characters');
    });

    test('returns null when name is valid', () {
      expect(Validators.validateName('Al'), isNull);
      expect(Validators.validateName('Raj Test'), isNull);
      expect(Validators.validateName(' Jane Doe '), isNull);
    });
  });

  group('Validators - Required', () {
    test('returns error when value is null or whitespace', () {
      expect(Validators.validateRequired(null, 'Title'), 'Title is required');
      expect(Validators.validateRequired('', 'Title'), 'Title is required');
      expect(Validators.validateRequired('   ', 'Title'), 'Title is required');
    });

    test('returns null when value is non-empty', () {
      expect(Validators.validateRequired('My Project', 'Title'), isNull);
    });
  });
}
