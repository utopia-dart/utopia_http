import 'package:utopia_dart_framework/utopia_dart_framework.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart' as shelf;

void main() {
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


  shelf_io.serve((request) async {
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
  }, 'localhost', 3030);
}

