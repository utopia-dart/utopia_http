import 'dart:io';
import 'package:test/test.dart';
import 'package:utopia_http/utopia_http.dart';

void main() {
  group('ShelfServer', () {
    test('can be constructed', () {
      final server = ShelfServer(InternetAddress.loopbackIPv4, 8080);
      expect(server.port, 8080);
      expect(server.address, InternetAddress.loopbackIPv4);
    });
    
    test('has correct default properties', () {
      final server = ShelfServer(InternetAddress.loopbackIPv4, 3000);
      expect(server.port, 3000);
      expect(server.address, InternetAddress.loopbackIPv4);
    });
  });

  group('Server abstract class', () {
    test('has required properties', () {
      // Server is abstract, so we test via ShelfServer
      final server = ShelfServer(InternetAddress.loopbackIPv6, 9000);
      expect(server.port, 9000);
      expect(server.address, InternetAddress.loopbackIPv6);
    });
  });
}