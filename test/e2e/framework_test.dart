import 'dart:convert';
import 'dart:io';

import 'server/server.dart' as server;
import 'package:test/test.dart';

void main() {
  server.main();
  group('A group of tests', () {
    setUp(() {});

    test('Basic Response', () async {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://localhost:3030/hello'));
      final res = await req.close();
      final output = await utf8.decodeStream(res);
      expect(output, 'Hello World!');
    });

    test('Param', () async {
      final client = HttpClient();
      final req = await client
          .getUrl(Uri.parse('http://localhost:3030/users/myuserid'));
      final res = await req.close();
      final output = await utf8.decodeStream(res);
      expect(output, 'myuserid');
    });

    test('JSON', () async {
      final client = HttpClient();
      final req =
          await client.postUrl(Uri.parse('http://localhost:3030/users'));
      req.headers
          .set(HttpHeaders.contentTypeHeader, ContentType.json.toString());
      final data = {
        "userId": "myuserid",
        "email": "email@gmail.com",
        "name": "myname"
      };
      final stream = Stream.value(utf8.encode(jsonEncode(data)));
      final res = await stream.pipe(req) as HttpClientResponse;
      final output = await utf8.decodeStream(res);
      expect(res.headers.contentType.toString(), ContentType.json.toString());
      expect(output,
          '{"userId":"myuserid","email":"email@gmail.com","name":"myname"}');
    });
  });
}
