import 'package:test/test.dart';
import 'package:utopia_framework/utopia_validators.dart';

void main() {
  final range = Range(1, 5);
  final range2 = Range(5, 1);
  final range3 = Range(1, 5, format: Types.double);

  group(
    'Range| ',
    () {
      test(
        'format getter should return int type',
        () {
          expect(range.format, Types.int);
        },
      );

      test(
        'min getter should return _min',
        () {
          expect(range.min, 1);
        },
      );

      test(
        'max getter should return _max',
        () {
          expect(range.max, 5);
        },
      );

      test(
        'getDescription(): should return proper description message',
        () {
          const expectedValue = 'Value must be a valid range between 1 and 5';

          expect(range.getDescription(), expectedValue);
        },
      );

      test(
        'getType(): should return proper data type',
        () {
          expect(range.getType(), 'int');
        },
      );

      test(
        'isArray(): should return false',
        () {
          expect(range.isArray(), false);
        },
      );

      test(
        'isValid(): should check the validity and return proper boolean value',
        () {
          expect(range.isValid('a'), false);
          expect(range.isValid(1), true);
          expect(range2.isValid(1), false);
          expect(range3.isValid(2.0), true);
        },
      );
    },
  );
}
