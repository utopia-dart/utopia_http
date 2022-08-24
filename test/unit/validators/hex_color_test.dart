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
          expect(hexColor.isValid('AB10BC99'), false);
          expect(hexColor.isValid('AR1012'), false);
          expect(hexColor.isValid('ab12bc99'), false);
          expect(hexColor.isValid('00'), false);
          expect(hexColor.isValid('ffff'), false);
          expect(hexColor.isValid('000'), true);
          expect(hexColor.isValid('ffffff'), true);
          expect(hexColor.isValid('000000'), true);
        },
      );
    },
  );
}
