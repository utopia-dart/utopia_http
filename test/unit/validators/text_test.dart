import 'package:test/test.dart';
import 'package:utopia_framework/src/validators/text.dart';
import 'package:utopia_framework/src/validators/types.dart';

void main() async {
  String message = 'Value must be a valid string';

  String stringWhenLengthIsGreaterThanZero(int value) =>
      ' and no longer than $value chars';

  String stringWhenListIsNotEmpty(List<String> value) =>
      ' and only consist of \'${value.join(",")}\' chars';

  String stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
    int intValue,
    List<String> listValue,
  ) =>
      message +
      stringWhenLengthIsGreaterThanZero(intValue) +
      stringWhenListIsNotEmpty(listValue);

  final text = Text(length: 10);

  test('isValid', () {
    expect(true, text.isValid('text'));
    expect(true, text.isValid('7'));
    expect(true, text.isValid('7.9'));
    expect(true, text.isValid('["seven"]'));
    expect(false, text.isValid(["seven"]));
    expect(false, text.isValid(["seven", 8, 9.0]));
    expect(false, text.isValid(false));
    expect(false, text.isArray());
    expect('string', text.getType());
    expect(
      message + stringWhenLengthIsGreaterThanZero(10),
      text.getDescription(),
    );
  });

  test('allowList', () {
    // Test lowercase alphabet
    var validator = Text(length: 100, allowList: Text.alphabetLower);
    expect('string', validator.getType());
    expect(false, validator.isArray());
    expect(true, validator.isValid('qwertzuiopasdfghjklyxcvbnm'));
    expect(true, validator.isValid('hello'));
    expect(true, validator.isValid('world'));
    expect(false, validator.isValid('hello world'));
    expect(false, validator.isValid('Hello'));
    expect(false, validator.isValid('worlD'));
    expect(false, validator.isValid('hello123'));
    expect(
      stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
        100,
        Text.alphabetLower,
      ),
      validator.getDescription(),
    );

    // Test uppercase alphabet
    validator = Text(length: 100, allowList: Text.alphabetUpper);
    expect(Types.string.name, validator.getType());
    expect(false, validator.isArray());
    expect(true, validator.isValid('QWERTZUIOPASDFGHJKLYXCVBNM'));
    expect(true, validator.isValid('HELLO'));
    expect(true, validator.isValid('WORLD'));
    expect(false, validator.isValid('HELLO WORLD'));
    expect(false, validator.isValid('hELLO'));
    expect(false, validator.isValid('WORLd'));
    expect(false, validator.isValid('HELLO123'));
    expect(
      stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
        100,
        Text.alphabetUpper,
      ),
      validator.getDescription(),
    );

    // Test numbers
    validator = Text(length: 100, allowList: Text.numbers);
    expect(Types.string.name, validator.getType());
    expect(false, validator.isArray());
    expect(true, validator.isValid('1234567890'));
    expect(true, validator.isValid('123'));
    expect(false, validator.isValid('123 456'));
    expect(false, validator.isValid('hello123'));
    expect(
      stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
        100,
        Text.numbers,
      ),
      validator.getDescription(),
    );

    // Test combination of allowLists
    validator = Text(
      length: 100,
      allowList: [
        ...Text.alphabetLower,
        ...Text.alphabetUpper,
        ...Text.numbers
      ],
    );
    expect(Types.string.name, validator.getType());
    expect(false, validator.isArray());
    expect(true, validator.isValid('1234567890'));
    expect(true, validator.isValid('qwertzuiopasdfghjklyxcvbnm'));
    expect(true, validator.isValid('QWERTZUIOPASDFGHJKLYXCVBNM'));
    expect(
      true,
      validator.isValid(
        'QWERTZUIOPASDFGHJKLYXCVBNMqwertzuiopasdfghjklyxcvbnm1234567890',
      ),
    );
    expect(false, validator.isValid('hello-world'));
    expect(false, validator.isValid('hello_world'));
    expect(false, validator.isValid('hello/world'));

    // Test length validation
    validator = Text(length: 5, allowList: Text.alphabetLower);
    expect(Types.string.name, validator.getType());
    expect(false, validator.isArray());
    expect(true, validator.isValid('hell'));
    expect(true, validator.isValid('hello'));
    expect(false, validator.isValid('hellow'));

    // Test when length is 0 and List is empty
    validator = Text();
    expect(false, validator.isArray());
    expect(true, validator.isValid('qwertzuiopasdfghjklyxcvbnm'));
    expect(true, validator.isValid('hello'));
    expect(true, validator.isValid('world'));
    expect(true, validator.isValid('hello world'));
    expect(true, validator.isValid('Hello'));
    expect(true, validator.isValid('worlD'));
    expect(true, validator.isValid('hello123'));
    expect(
      message,
      validator.getDescription(),
    );
  });
}
