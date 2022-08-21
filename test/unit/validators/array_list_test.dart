import 'package:test/test.dart';
import 'package:utopia_framework/utopia_validators.dart';

String _description(String value) {
  return 'Value must be a valid array and $value';
}

void main() {
  final mockValidator = _MockValidator();
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

class _MockValidator implements Validator {
  late String _description, _type;
  late bool _isValid;

  // The setters will work as method stubs.

  // These setters need to be called first before calling the
  // corresponding overriden methods below in the test. 👇️

  set description(String description) => _description = description;
  set type(String type) => _type = type;
  set validity(bool isValid) => _isValid = isValid;

  @override
  String getDescription() {
    return _description;
  }

  @override
  String getType() {
    return _type;
  }

  @override
  bool isValid(value) {
    return _isValid;
  }

  @override
  bool isArray() {
    return false;
  }
}
