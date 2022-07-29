import 'dart:math';
import 'package:test/test.dart';
import 'package:utopia_dart_framework/src/app.dart';
import 'package:utopia_dart_framework/src/request.dart';
import 'package:utopia_dart_framework/src/response.dart';
import 'package:utopia_dart_framework/src/route.dart';
import 'package:utopia_dart_framework/src/validators/text.dart';

void main() async {
  final app = App();
  App.setResource('rand', () => Random().nextInt(100));
  App.setResource('first', (params) => 'first-${params["second"]}',
      injections: ['second']);
  App.setResource('second', () => 'second');

  group('App', () {
    test('resource', () async {
      expect(app.getResource('second'), 'second');
      expect(app.getResource('first'), 'first-second');
      final resource = app.getResource('rand');
      assert(resource != null);
      expect(app.getResource('rand'), resource);
      expect(app.getResource('rand'), resource);
      expect(app.getResource('rand'), resource);

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
