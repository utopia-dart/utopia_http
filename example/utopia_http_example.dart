import 'dart:io';
import 'package:utopia_http/utopia_http.dart';

void main() async {
  final address = InternetAddress.anyIPv4;
  final port = Http.getEnv('PORT', 8080);
  final app = Http(ShelfServer(address, port), threads: 8);

  app.get('/').inject('request').inject('response').action(
    (Request request, Response response) {
      response.text('Hello world');
      return response;
    },
  );
  app
      .get('/hello-world')
      .inject('request')
      .inject('response')
      .action((Request request, Response response) {
    response.text('Hello world');
    return response;
  });

  app
      .get('/users/:userId')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((String userId, Response response) {
    response.text(userId);
    return response;
  });

  app
      .get('/users/:userId/jhyap/:messing')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .param(key: 'messing', defaultValue: 'messing')
      .inject('response')
      .action((String userId, String messing, Response response) {
    response.text('tap tap');
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
      'userId': userId,
      'name': name,
      'email': email,
    });
    return response;
  });

  app
      .get('/users/:userId/jhyap')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((String userId, Response response) {
    print(userId);
    response.text('Jhyap');
    return response;
  });

  await app.start();
  print("server started at http://${address.address}:$port");
}
