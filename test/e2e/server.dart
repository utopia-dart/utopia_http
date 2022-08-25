import 'dart:io';

import 'package:utopia_framework/src/validators/text.dart';
import 'package:utopia_framework/utopia_framework.dart';

void initApp(App app) {
  app
      .error()
      .inject('error')
      .inject('response')
      .action((Exception error, Response response) {
    if (error is ValidationException) {
      response.status = 400;
      response.body = error.message;
    }
    return response;
  });

  app.get('/').action(() {
    return Response('Hello!');
  });

  app.get('/empty').action(() {});

  app
      .post('/create')
      .param(key: 'userId')
      .param(key: 'file')
      .inject('request')
      .inject('response')
      .action(
          (String userId, dynamic file, Request request, Response response) {
    response.text(file['filename']);
    return response;
  });

  app
      .get('/hello')
      .inject('request')
      .inject('response')
      .action((Request request, Response response) {
    response.text('Hello World!');
    return response;
  });

  app
      .get('/users/:userId')
      .param(
        key: 'userId',
        validator: Text(length: 10),
        defaultValue: '',
        description: 'Users unique ID',
      )
      .inject('response')
      .action((String userId, Response response) {
    response.text(userId);
    return response;
  });

  app
      .post('/users')
      .param(key: 'userId')
      .param(key: 'name')
      .param(key: 'email')
      .inject('response')
      .inject('request')
      .action((
    String userId,
    String name,
    String email,
    Response response,
    Request request,
  ) {
    response.json({
      "userId": userId,
      "email": email,
      "name": name,
    });
    return response;
  });
}

Future<HttpServer> shelfServer() async {
  final app = App();
  initApp(app);
  return app.serve(ShelfServer('localhost', 3030), path: 'test/e2e/public');
}
