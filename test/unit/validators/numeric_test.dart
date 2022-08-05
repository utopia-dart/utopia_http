import 'package:test/test.dart';
import 'package:utopia_framework/utopia_validators.dart';

void main() {
  final numeric = Numeric();

  const stringValue = 'Value must be a valid number';

  test(
    'Numeric object:',
    () {
      expect(numeric.getDescription(), stringValue);
      expect(numeric.getType(), Types.num.name);
      expect(numeric.isArray(), false);
      expect(numeric.isValid(1), true);
      expect(numeric.isValid(1.0), true);
      expect(numeric.isValid('1'), false);
    },
  );
}
