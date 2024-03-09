import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:utopia_http/utopia_http.dart';

import 'server.dart' as server;

void main() {
  group('Http Shelf Server', () {
    Http? http;
    setUp(() async {
      http = await server.shelfServer();
    });

    test('Basic Response', basicResponseTest);

    test('No param, injection', noParamInjectionTest);

    test('Param', paramsTest);

    test('Param Validation', paramValidationTest);

    test('JSON', jsonTest);

    test('static', staticFileTest);

    test('file upload', fileUpload);

    tearDown(() async {
      await http?.closeServer();
    });
  });
}

void fileUpload() async {
  var uri = Uri.parse('http://localhost:3030/create');
  var request = http.MultipartRequest('POST', uri)
    ..fields['userId'] = '1'
    ..files.add(
      await http.MultipartFile.fromPath(
        'file',
        'test/e2e/public/index.html',
        filename: 'index',
      ),
    );
  var res = await request.send();
  final out = await utf8.decodeStream(res.stream);
  expect(res.statusCode, 200);
  expect(out, 'index');
}

void staticFileTest() async {
  final client = HttpClient();
  final req =
      await client.getUrl(Uri.parse('http://localhost:3030/index.html'));
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  assert(res.headers.contentType.toString().contains('text/html'));
  expect(output, 'Hello World Html!');
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
  req.write(jsonEncode(data));
  final res = await req.close();
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

void noParamInjectionTest() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('http://localhost:3030'));
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  expect(output, 'Hello!');
}

void actionNullReturnTest() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('http://localhost:3030/empty'));
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  expect(output, '');
}

void basicResponseTest() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('http://localhost:3030/hello'));
  final res = await req.close();
  final output = await utf8.decodeStream(res);
  expect(output, 'Hello World!');
}
