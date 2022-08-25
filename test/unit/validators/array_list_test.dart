import 'package:test/test.dart';
import 'package:utopia_framework/utopia_validators.dart';

import 'mock_validator.dart';

String _description(String value) {
  return 'Value must be a valid array and $value';
}

void main() {
  final mockValidator = MockValidator();
  final arrayListWithLengthZero = ArrayList(mockValidator);
  final arrayListWithLengthNonZero = ArrayList(mockValidator, length: 2);

  group(
    'ArrayList |',
    () {
      test(
        'getDescription(): should return a description',
        () {
          mockValidator.description = 'description';
          final result = arrayListWithLengthZero.getDescription();
          expect(result, _description('description'));
        },
      );

      test(
        'getType(): should return a proper data type',
        () {
          mockValidator.type = 'String';
          expect(arrayListWithLengthZero.getType(), 'String');

          mockValidator.type = 'int';
          expect(arrayListWithLengthZero.getType(), 'int');
        },
      );

      test(
        'isArray(): should return true',
        () {
          expect(arrayListWithLengthZero.isArray(), true);
        },
      );

      test(
        'isValid(): should return proper boolean value',
        () {
          expect(arrayListWithLengthZero.isValid(1), false);
          expect(arrayListWithLengthNonZero.isValid([1, 2, 3]), false);

          mockValidator.validity = false;
          expect(arrayListWithLengthNonZero.isValid([1, 2]), false);

          mockValidator.validity = true;
          expect(arrayListWithLengthNonZero.isValid([1, 2]), true);
        },
      );
    },
  );
}
