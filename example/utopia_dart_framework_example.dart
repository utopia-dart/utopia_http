import 'package:utopia_dart_framework/utopia_dart_framework.dart';

void main() {
  final app = App();
  app.get('/hello-world').inject('request').inject('response').action((params) {
    print(params);
    params['response'].end('Hello world');
    return params['response'];
  });

  app.get('/users/:userId')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((params) {
    print(params);
    params['response'].end(params['userId']);
    return params['response'];
  });

  app.get('/users/:userId/jhyap/:messing')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .param(key: 'messing', defaultValue: 'messing')
      .inject('response')
      .action((params) {
    print(params);
    params['response'].end('tap tap');
    return params['response'];
  });

  app.post('/users')
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

  app.get('/users/:userId/jhyap')
      .param(key: 'userId', defaultValue: '', description: 'Users unique ID')
      .inject('response')
      .action((params) {
    print(params);
    params['response'].end('Jhyap');
    return params['response'];
  });

  app.serve(ShelfServer('localhost', 8080));
}
