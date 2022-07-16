import 'dart:io';
import 'package:utopia_dart_framework/utopia_dart_framework.dart';

void main() async {
  App.get('/hello').inject('request').inject('response').action((params) {
    params['response'].text('Hello World!');
    return params['response'];
  });

  App.get('/users/:userId')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((params) {
    params['response'].text(params['userId']);
    return params['response'];
  });

  App.post('/users')
      .param(key: 'userId')
      .param(key: 'name')
      .param(key: 'email')
      .inject('response')
      .inject('request')
      .action((params) {
    params['response'].json({
      "userId": params['userId'],
      "email": params['email'],
      "name": params['name']
    });
    return params['response'];
  });

  final server = await HttpServer.bind('localhost', 3030);
  await server.forEach((HttpRequest request) async {
    final headers = <String, String>{};
    final headersAll = <String, List<String>>{};
    request.headers.forEach((name, values) {
      headersAll[name] = values;
      headers[name] = values.join(',');
    });
    final req = Request(request.method, request.uri,
        headers: headers,
        headersAll: headersAll,
        contentType: request.headers.value(HttpHeaders.contentTypeHeader),
        body: request);
    final res = await App().run(req, Response(''));
    request.response.statusCode = res.status;
    res.headers.forEach((name, value) {
      request.response.headers.set(name, value);
    });
    request.response.write(res.body);
    request.response.close();
  });
}
