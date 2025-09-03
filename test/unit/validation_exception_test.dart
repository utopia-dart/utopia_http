import 'dart:io';
import 'package:test/test.dart';
import 'package:utopia_http/src/validation_exception.dart';

void main() {
  group('ValidationException', () {
    test('can be created with message', () {
      final exception = ValidationException('Invalid input');
      expect(exception.message, 'Invalid input');
    });

    test('extends HttpException', () {
      final exception = ValidationException('Test error');
      expect(exception, isA<HttpException>());
    });

    test('toString includes message', () {
      final exception = ValidationException('Test error message');
      expect(exception.toString(), contains('Test error message'));
    });

    test('can be thrown and caught', () {
      expect(() => throw ValidationException('Error'),
          throwsA(isA<ValidationException>()));
    });

    test('message property is accessible', () {
      const message = 'Validation failed';
      final exception = ValidationException(message);
      expect(exception.message, message);
    });
  });
}
