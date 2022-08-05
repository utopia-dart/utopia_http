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

  test(
    'isValid',
    () {
      expect(text.isValid('text'), true);
      expect(text.isValid('7'), true);
      expect(text.isValid('7.9'), true);
      expect(text.isValid('["seven"]'), true);
      expect(text.isValid(["seven"]), false);
      expect(text.isValid(["seven", 8, 9.0]), false);
      expect(text.isValid(false), false);
      expect(text.isArray(), false);
      expect(text.getType(), 'string');
      expect(
        text.getDescription(),
        message + stringWhenLengthIsGreaterThanZero(10),
      );
    },
  );

  test(
    'allowList',
    () {
      // Test lowercase alphabet
      var validator = Text(length: 100, allowList: Text.alphabetLower);
      expect(validator.getType(), 'string');
      expect(validator.isArray(), false);
      expect(validator.isValid('qwertzuiopasdfghjklyxcvbnm'), true);
      expect(validator.isValid('hello'), true);
      expect(validator.isValid('world'), true);
      expect(validator.isValid('hello world'), false);
      expect(validator.isValid('Hello'), false);
      expect(validator.isValid('worlD'), false);
      expect(validator.isValid('hello123'), false);
      expect(
        validator.getDescription(),
        stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
          100,
          Text.alphabetLower,
        ),
      );

      // Test uppercase alphabet
      validator = Text(length: 100, allowList: Text.alphabetUpper);
      expect(validator.getType(), Types.string.name);
      expect(validator.isArray(), false);
      expect(validator.isValid('QWERTZUIOPASDFGHJKLYXCVBNM'), true);
      expect(validator.isValid('HELLO'), true);
      expect(validator.isValid('WORLD'), true);
      expect(validator.isValid('HELLO WORLD'), false);
      expect(validator.isValid('hELLO'), false);
      expect(validator.isValid('WORLd'), false);
      expect(validator.isValid('HELLO123'), false);
      expect(
        validator.getDescription(),
        stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
          100,
          Text.alphabetUpper,
        ),
      );

      // Test numbers
      validator = Text(length: 100, allowList: Text.numbers);
      expect(validator.getType(), Types.string.name);
      expect(validator.isArray(), false);
      expect(validator.isValid('1234567890'), true);
      expect(validator.isValid('123'), true);
      expect(validator.isValid('123 456'), false);
      expect(validator.isValid('hello123'), false);
      expect(
        validator.getDescription(),
        stringWhenLengthIsGreaterThanZeroAndListIsNotEmpty(
          100,
          Text.numbers,
        ),
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
      expect(validator.getType(), Types.string.name);
      expect(validator.isArray(), false);
      expect(validator.isValid('1234567890'), true);
      expect(validator.isValid('qwertzuiopasdfghjklyxcvbnm'), true);
      expect(validator.isValid('QWERTZUIOPASDFGHJKLYXCVBNM'), true);
      expect(
        validator.isValid(
          'QWERTZUIOPASDFGHJKLYXCVBNMqwertzuiopasdfghjklyxcvbnm1234567890',
        ),
        true,
      );
      expect(validator.isValid('hello-world'), false);
      expect(validator.isValid('hello_world'), false);
      expect(validator.isValid('hello/world'), false);

      // Test length validation
      validator = Text(length: 5, allowList: Text.alphabetLower);
      expect(validator.getType(), Types.string.name);
      expect(validator.isArray(), false);
      expect(validator.isValid('hell'), true);
      expect(validator.isValid('hello'), true);
      expect(validator.isValid('hellow'), false);

      // Test when length is 0 and List is empty
      validator = Text();
      expect(validator.isArray(), false);
      expect(validator.isValid('qwertzuiopasdfghjklyxcvbnm'), true);
      expect(validator.isValid('hello'), true);
      expect(validator.isValid('world'), true);
      expect(validator.isValid('hello world'), true);
      expect(validator.isValid('Hello'), true);
      expect(validator.isValid('worlD'), true);
      expect(validator.isValid('hello123'), true);
      expect(validator.getDescription(), message);
    },
  );
}
