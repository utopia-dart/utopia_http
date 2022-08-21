import 'package:test/test.dart';
import 'package:utopia_framework/src/validators/hex_color.dart';

void main() {
  final hexColor = HexColor();

  const description = 'Value must be a valid Hex color code';

  group(
    'HexColor |',
    () {
      test(
        'getDescription(): should return proper description',
        () {
          expect(hexColor.getDescription(), description);
        },
      );

      test(
        'getType(): should return String type',
        () {
          expect(hexColor.getType(), 'string');
        },
      );

      test(
        'isArray(): should return false',
        () {
          expect(hexColor.isArray(), false);
        },
      );

      test(
        'isValid(): should return true if the string is a valid string',
        () {
          expect(hexColor.isValid(1), false);
          expect(hexColor.isValid('abc'), false);
          expect(hexColor.isValid('#FF7723'), true);
        },
      );
    },
  );
}
