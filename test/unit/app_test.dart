import 'dart:math';

import 'package:test/test.dart';
import 'package:utopia_di/utopia_validators.dart';
import 'package:utopia_framework/utopia_framework.dart';

void main() async {
  final app = App();
  app.setResource('rand', () => Random().nextInt(100));
  app.setResource(
    'first',
    (String second) => 'first-$second',
    injections: ['second'],
  );
  app.setResource('second', () => 'second');

  group('App', () {
    test('resource injection', () async {
      final resource = app.getResource('rand');

      final route = Route('GET', '/path');
      route
          .inject('rand')
          .param(
            key: 'x',
            defaultValue: 'x-def',
            description: 'x param',
            validator: Text(length: 200),
          )
          .param(
            key: 'y',
            defaultValue: 'y-def',
            description: 'y param',
            validator: Text(length: 200),
          )
          .action((int rand, String x, String y) => Response("$x-$y-$rand"));
      final res = await app.execute(route, Request('GET', Uri.parse('/path')));
      expect(res.body, 'x-def-y-def-$resource');
    });
  });
}
