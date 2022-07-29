import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'server.dart' as server;

void main() {
  group('Framework Default Server', () {
    HttpServer? ser;
    setUp(() async {
      ser = await server.defaultServer();
    });

    test('Basic Response', basicResponseTest);

    test('Param', paramsTest);

    test('Param Validation', paramValidationTest);

    test('JSON', jsonTest);

    tearDown(() async {
      await ser?.close();
    });
  });

  group('Framework Shelf Server', () {
    HttpServer? ser;
    setUp(() async {
      ser = await server.shelfServer();
    });

    test('Basic Response', basicResponseTest);

    test('Param', paramsTest);

    test('Param Validation', paramValidationTest);

    test('JSON', jsonTest);

    tearDown(() async {
      await ser?.close();
    });
  });
}

void jsonTest() async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse('http://localhost:3030/users'));
  req.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.toString());
  final data = {
    "userId": "myuserid",
    "email": "email@gmail.com",
    "name": "myname"
  };
  final stream = Stream.value(utf8.encode(jsonEncode(data)));
  final res = await stream.pipe(req) as HttpClientResponse;
  final output = await utf8.decodeStream(res);
  expect(res.headers.contentType.toString(), ContentType.json.toString());
  expect(
    output,
    '{"userId":"myuserid","email":"email@gmail.com","name":"myname"}',
  );
}

void paramValidationTest() async {
  final client = HttpClient();
  final req = await client.getUrl(
    Uri.parse('http://localhost:3030/users/verylonguseridnotvalidate'),
  );
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  expect(
    output,
    'Invalid userId: Value must be a valid string and no longer than 10 chars',
  );
}

void paramsTest() async {
  final client = HttpClient();
  final req =
      await client.getUrl(Uri.parse('http://localhost:3030/users/myuserid'));
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  expect(output, 'myuserid');
}

void basicResponseTest() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('http://localhost:3030/hello'));
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  expect(output, 'Hello World!');
}
