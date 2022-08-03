import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'server.dart' as server;

void main() {
  group('Framework Shelf Server', () {
    HttpServer? ser;
    setUp(() async {
      ser = await server.shelfServer();
    });

    test('Basic Response', basicResponseTest);

    test('Param', paramsTest);

    test('Param Validation', paramValidationTest);

    test('JSON', jsonTest);

    test('static', staticFileTest);

    test('file upload', fileUpload);

    tearDown(() async {
      await ser?.close();
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

  print(out);
  print(res.statusCode);
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
