import 'package:utopia_di/utopia_validators.dart';
import 'package:utopia_http/utopia_http.dart';

void initHttp(Http http) {
  http
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

  http.get('/').action(() {
    return Response('Hello!');
  });

  http.get('/empty').action(() {});

  http
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

  http
      .get('/hello')
      .inject('request')
      .inject('response')
      .action((Request request, Response response) {
    response.text('Hello World!');
    return response;
  });

  http
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

  http
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

Future<Http> shelfServer() async {
  final http = Http(ShelfServer('localhost', 3030), path: 'test/e2e/public');
  initHttp(http);
  await http.start();
  return http;
}
