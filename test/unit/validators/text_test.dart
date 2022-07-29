import 'package:test/test.dart';
import 'package:utopia_dart_framework/src/validators/text.dart';
import 'package:utopia_dart_framework/src/validators/types.dart';

void main() async {
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

    // Test numbers
    validator = Text(length: 100, allowList: Text.numbers);
    expect(Types.string.name, validator.getType());
    expect(false, validator.isArray());
    expect(true, validator.isValid('1234567890'));
    expect(true, validator.isValid('123'));
    expect(false, validator.isValid('123 456'));
    expect(false, validator.isValid('hello123'));

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
  });
}
