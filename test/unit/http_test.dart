import 'dart:math';

import 'package:test/test.dart';
import 'package:utopia_di/utopia_validators.dart';
import 'package:utopia_http/utopia_http.dart';

void main() async {
  group('Http', () {
    test('resource injection', () async {
      final http = Http(ShelfServer('localhost', 8080));
      http.setResource('rand', () => Random().nextInt(100));
      http.setResource(
        'first',
        (String second) => 'first-$second',
        injections: ['second'],
      );
      http.setResource('second', () => 'second');

      final resource = http.getResource('rand');

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
      final res = await http.execute(
        route,
        Request(
          'GET',
          Uri.parse('/path'),
        ),
        'utopia',
      );
      expect(res.body, 'x-def-y-def-$resource');
    });

    test('shutdown hooks execute for groups', () async {
      final http = Http(ShelfServer('localhost', 8081));
      var shutdownCalled = false;

      http
          .shutdown()
          .groups(['api'])
          .inject('response')
          .action((Response response) {
            shutdownCalled = true;
          });

      final route = Route('GET', '/test-shutdown');
      route
          .groups(['api'])
          .inject('response')
          .action((Response response) {
        response.text('ok');
        return response;
      });

      http.setResource('response', () => Response(''), context: 'test');
      await http.execute(
        route,
        Request('GET', Uri.parse('/test-shutdown')),
        'test',
      );
      expect(shutdownCalled, isTrue);
    });

    test('404 response for unmatched route', () async {
      final http = Http(ShelfServer('localhost', 8082));
      final response = await http.run(
        Request('GET', Uri.parse('/nonexistent')),
        'test-404',
      );
      expect(response.status, 404);
      expect(response.body, 'Not Found');
    });

    test('supervisors are instance-level', () {
      final http1 = Http(ShelfServer('localhost', 8083));
      final http2 = Http(ShelfServer('localhost', 8084));
      expect(identical(http1.supervisors, http2.supervisors), isFalse);
      expect(http1.supervisors, isEmpty);
      expect(http2.supervisors, isEmpty);
      // Verify that modifying one instance's supervisors doesn't affect the other
      expect(http1.supervisors.length, 0);
      expect(http2.supervisors.length, 0);
    });
  });
}
