// import 'dart:io';
import 'dart:io';

import 'package:utopia_dart_framework/src/validation_exception.dart';
import 'package:utopia_dart_framework/src/validators/text.dart';
import 'package:utopia_dart_framework/utopia_dart_framework.dart';

void initApp() {
  App.error().inject('error').inject('response').action((params) {
    final error = params['error'];
    final response = params['response'];
    if (error is ValidationException) {
      response.status = 400;
      response.body = error.message;
    }
    return response;
  });
  App.get('/hello').inject('request').inject('response').action((params) {
    params['response'].text('Hello World!');
    return params['response'];
  });

  App.get('/users/:userId')
      .param(
          key: 'userId',
          validator: Text(length: 10),
          defaultValue: '',
          description: 'Users unique ID')
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
}

Future<HttpServer> defaultServer() async {
  App.reset();
  initApp();
  return App.serve(DefaultServer('localhost', 3030));
}

Future<HttpServer> shelfServer() async {
  App.reset();
  initApp();
  return App.serve(ShelfServer('localhost', 3030));
}
