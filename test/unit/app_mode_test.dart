import 'package:test/test.dart';
import 'package:utopia_http/src/app_mode.dart';

void main() {
  group('AppMode', () {
    test('enum has correct values', () {
      expect(AppMode.values, contains(AppMode.development));
      expect(AppMode.values, contains(AppMode.stage));
      expect(AppMode.values, contains(AppMode.production));
      expect(AppMode.values.length, 3);
    });

    test('development mode exists', () {
      expect(AppMode.development, isA<AppMode>());
    });

    test('stage mode exists', () {
      expect(AppMode.stage, isA<AppMode>());
    });

    test('production mode exists', () {
      expect(AppMode.production, isA<AppMode>());
    });

    test('enum values are distinct', () {
      expect(AppMode.development, isNot(AppMode.stage));
      expect(AppMode.development, isNot(AppMode.production));
      expect(AppMode.stage, isNot(AppMode.production));
    });
  });
}