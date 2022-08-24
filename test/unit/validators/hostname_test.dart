import 'package:test/test.dart';
import 'package:utopia_framework/src/validators/hostname.dart';

void main() {
  final hostname = Hostname(['abc123', '*.test']);

  group(
    'HostName |',
    () {
      test(
        'getDescription(): should return proper description message',
        () {
          const expectedValue =
              'Value must be a valid hostname without path, port or protocol.';

          expect(hostname.getDescription(), expectedValue);
        },
      );

      test(
        'getType(): should return proper data type',
        () {
          expect(hostname.getType(), 'string');
        },
      );

      test(
        'isArray(): should return false',
        () {
          expect(hostname.isArray(), false);
        },
      );

      test(
        'isValid(): should check the validity and return proper boolean value',
        () {
          expect(hostname.isValid(1), false);
          expect(hostname.isValid(''), false);
          expect(hostname.isValid('/'), false);
          expect(hostname.isValid('abc123'), true);
          expect(hostname.isValid('cat'), false);
          expect(hostname.isValid('abc.xyz'), false);
        },
      );
    },
  );
}
