import 'dart:io';

import 'package:test/test.dart';
import 'package:utopia_http/utopia_http.dart';

void main() {
  group('Response', () {
    test('json sets status', () {
      final response = Response('');
      response.json({'key': 'value'}, status: HttpStatus.created);
      expect(response.status, HttpStatus.created);
      expect(response.body, '{"key":"value"}');
      expect(response.contentType, ContentType.json);
    });

    test('json defaults to 200', () {
      final response = Response('');
      response.json({'key': 'value'});
      expect(response.status, HttpStatus.ok);
    });

    test('text sets status', () {
      final response = Response('');
      response.text('hello', status: HttpStatus.accepted);
      expect(response.status, HttpStatus.accepted);
      expect(response.body, 'hello');
    });

    test('html sets status', () {
      final response = Response('');
      response.html('<p>hi</p>', status: HttpStatus.accepted);
      expect(response.status, HttpStatus.accepted);
      expect(response.body, '<p>hi</p>');
      expect(response.contentType, ContentType.html);
    });

    test('noContent sets status and empty body', () {
      final response = Response('data');
      response.noContent();
      expect(response.status, HttpStatus.noContent);
      expect(response.body, '');
    });

    test('addHeader and removeHeader', () {
      final response = Response('');
      response.addHeader('X-Custom', 'value');
      expect(response.headers['X-Custom'], 'value');
      response.removeHeader('X-Custom');
      expect(response.headers.containsKey('X-Custom'), false);
    });

    test('addCookie and removeCookie', () {
      final response = Response('');
      final cookie = Cookie('name', 'value');
      response.addCookie(cookie);
      expect(response.cookies.length, 1);
      response.removeCookie(cookie);
      expect(response.cookies.length, 0);
    });
  });
}
