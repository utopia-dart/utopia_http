import 'package:test/test.dart';
import 'package:utopia_framework/utopia_validators.dart';

void main() {
  final numeric = Numeric();

  const stringValue = 'Value must be a valid number';

  test('Numeric object:', () {
    expect(stringValue, numeric.getDescription());
    expect(Types.num.name, numeric.getType());
    expect(false, numeric.isArray());
    expect(true, numeric.isValid(1));
    expect(true, numeric.isValid(1.0));
    expect(false, numeric.isValid('1'));
  });
}
