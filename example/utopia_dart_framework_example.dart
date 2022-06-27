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
    final response = Res('');
    final res = await App().run(
      Request(request.method, request.url,
          headers: request.headers,
          headersAll: request.headersAll,
          encoding: request.encoding,
          contentType: request.mimeType,
          body: request.read()),
      response,
    );
    return shelf.Response.ok(res.body);
  }, 'localhost', 8080);
}

class Res extends Response {
  Res(super.body);

  @override
  end(message, {int status = 200}) {
    body = message;
    status = status;
  }

  Res.send(super.message, {int status = 200}) {
    shelf.Response(status, body: body);
  }
}
