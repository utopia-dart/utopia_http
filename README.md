# Utopia HTTP Server

Light and Fast Dart HTTP library to build awesome Dart server side applications. Inspired from [Utopia PHP ecosystem](https://github.com/utopia-php).

## Getting Started

First add the dependency in your pubspec.yaml

```yaml
dependencies:
  utopia_http: ^0.1.0
```

Now, in main.dart, you can

```dart
import 'dart:io';
import 'package:utopia_http/utopia_http.dart';

void main() async {
  final address = InternetAddress.anyIPv4;
  final port = Http.getEnv('PORT', 8000);
  final app = Http(ShelfServer(address, port), threads: 8);

  app.get('/').inject('request').inject('response').action(
    (Request request, Response response) {
      response.text('Hello world');
      return response;
    },
  );
  
  await app.start();
}

```

## Features

### Parameters

Parameters are used to receive input into endpoint action from the HTTP request. Parameters could be defined as URL parameters or in a body with a structure such as JSON.

Every parameter must have a validator defined. Validators are simple classes that verify the input and ensure the security of inputs. You can define your own validators or use some of built-in validators.

Define an endpoint with params:

```dart
app
  .get('/hello-world')
  .param('name', 'World', Text(255), 'Name to greet. Optional', true)
  .inject('response').action((String name, Response response) {
    response.text('Hello $name');
    return response;
  });
```

```bash
curl http://localhost:8000/hello-world
curl http://localhost:8000/hello-world?name=Utopia
curl http://localhost:8000/hello-world?name=Appwrite
```

It's always recommended to use params instead of getting params or body directly from the request resource. If you do that intentionally, always make sure to run validation right after fetching such a raw input.

### Hooks

There are three types of hooks:

- Init hooks are executed before the route action is executed
- Shutdown hooks are executed after route action is finished, but before application shuts down
- Error hooks are executed whenever there's an error in the application lifecycle.

You can provide multiple hooks for each stage. If you do not assign groups to the hook, by default, the hook will be executed for every route. If a group is defined on a hook, it will only run during the lifecycle of a request that belongs to the same group.


```dart
app
  .init()
  .inject('request')
  .action((Request request) {
    print('Received: ${request.method} ${request.url}');
  });

app
  .shutdown()
  .inject('response')
  .action((Response response) {
    print('Responding with status code: ${response.status}');
  });

app
  .error()
  .inject('error')
  .inject('response')
  .action((Exception error, Response response) {
    response.text(error.toString(), status: HttpStatus.internalServerError);
  });

```

Hooks are designed to be actions that run during the lifecycle of requests. Hooks should include functional logic. Hooks are not designed to prepare dependencies or context for the request. For such a use case, you should use resources.

### Groups

Groups allow you to define common behavior for multiple endpoints.

You can start by defining a group on an endpoint. Keep in mind you can also define multiple groups on a single endpoint.

```dart
app
  .get('/login')
  .group(['api', 'public'])
  .inject('response')
  .action((Response response) {
    response.text('OK');
    return response;
  });
```

Now you can define hooks that would apply only to specific groups. Remember, hooks can also be assigned to multiple groups.

```dart
app
  .init()
  .group(['api'])
  .inject('request')
  .action((Request request) {
    final apiKey = request.headers['x-api-key'] ?? '';
    if (apiKey.isEmpty) {
      response.text('Api key missing.', status: HttpStatus.unauthorized);
    }
  });
```

Groups are designed to be actions that run during the lifecycle of requests to endpoints that have some logic in common. Groups allow you to prevent code duplication and are designed to be defined anywhere in your source code to allow flexibility.

### Resources
Resources allow you to prepare dependencies for requests such as database connection or the user who sent the request. A new instance of a resource is created for every request.

Define a resource:

```dart
app.resource('timestamp', () {
  return DateTime.now().millisecondsSinceEpoch;
});
```

Inject resource into endpoint action:

```dart
app
  .get('/')
  .inject('timestamp')
  .inject('response')
  .action((int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    print('Request took: $difference');
  });
```

Inject resource into a hook:

```dart
app
  .init()
  .inject('timestamp')
  .action((int timestamp) {
    print('Request timestamp: ${timestamp.toString()}');
  });
```

In advanced scenarios, resources can also be injected into other resources or endpoint parameters.

Resources are designed to prepare dependencies or context for the request. Resources are not meant to do functional logic or return callbacks. For such a use case, you should use hooks.

## Copyright and license

The MIT License (MIT) [https://www.opensource.org/licenses/mit-license.php](https://www.opensource.org/licenses/mit-license.php)
