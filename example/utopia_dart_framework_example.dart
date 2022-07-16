import 'package:utopia_dart_framework/utopia_dart_framework.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart' as shelf;

void main() {
  App.get('/hello-world').inject('request').inject('response').action((params) {
    print(params);
    params['response'].end('Hello world');
    return params['response'];
  });

  App.get('/users/:userId')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((params) {
    print(params);
    params['response'].end(params['userId']);
    return params['response'];
  });

  App.get('/users/:userId/jhyap/:messing')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .param(key: 'messing', defaultValue: 'messing')
      .inject('response')
      .action((params) {
    print(params);
    params['response'].end('tap tap');
    return params['response'];
  });

  App.post('/users')
      .param(key: 'userId')
      .param(key: 'name')
      .param(key: 'email')
      .inject('response')
      .inject('request')
      .action((params) {
    print(params);
    params['response'].end(params.toString());
    return params['response'];
  });

  App.get('/users/:userId/jhyap')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((params) {
    print(params);
    params['response'].end('Jhyap');
    return params['response'];
  });

  shelf_io.serve((request) async {
    // print(await request.readAsString());
    final response = Response('');
    final res = await App().run(
      Request(request.method, request.url,
          headers: request.headers,
          headersAll: request.headersAll,
          encoding: request.encoding,
          contentType: request.mimeType,
          body: request.read()),
      response,
    );
    return shelf.Response(res.status, body: res.body, headers: res.headers);
  }, 'localhost', 8080);
}
