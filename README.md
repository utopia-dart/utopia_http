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
  final port = Http.getEnv('PORT', 8080);
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

## Copyright and license

The MIT License (MIT) [https://www.opensource.org/licenses/mit-license.php](https://www.opensource.org/licenses/mit-license.php)
