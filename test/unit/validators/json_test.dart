import 'package:test/test.dart';
import 'package:utopia_framework/src/validators/json.dart';

void main() {
  final json = JSON();

  const description = 'Value must be a valid JSON';
  const jsonString = '{"key": "value"}';

  group(
    'HexColor |',
    () {
      test(
        'getDescription(): should return proper description',
        () {
          expect(json.getDescription(), description);
        },
      );

      test(
        'getType(): should return String type',
        () {
          expect(json.getType(), 'json');
        },
      );

      test(
        'isArray(): should return false',
        () {
          expect(json.isArray(), false);
        },
      );

      test(
        'isValid(): should check the validity of the input',
        () {
          expect(json.isValid({}), true);
          expect(json.isValid(jsonString), true);
          expect(json.isValid('json'), false);
        },
      );
    },
  );
}
