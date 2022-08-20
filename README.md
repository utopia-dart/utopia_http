# Utopia Dart Framework

**NOT READY FOR PRODUCTION**

Light and Fast Dart Framework to build awesome Dart applications. Inspired from [Utopia PHP Framework](https://github.com/utopia-php/framework).

## ⚠️ Warning!

This library is highly volatile and heavily under development.

## Getting Started

First add the dependency in your pubspec.yaml

```yaml
dependencies:
  utopia_framework:
    git: https://github.com/utopia-dart/utopia_framework
```

Now, in main.dart, you can

```dart
import 'dart:io';
import 'package:utopia_framework/utopia_framework.dart';

void main() async {
  final app = App();
  app
      .get('/')
      .inject('response')
      .action((Response response) {
    response.text('Hello World!');
    return response;
  });

  final address = InternetAddress.anyIPv4;
  final port = App.getEnv('PORT', 8080);
  await app.serve(ShelfServer(address, port));
  print("server started at ${address.address}:$port");
}
```

## Authors

- [https://twitter.com/lohanidamodar](https://twitter.com/lohanidamodar)
- [https://github.com/lohanidamodar](https://github.com/lohanidamodar)

## Copyright and license

The MIT License (MIT) [http://www.opensource.org/licenses/mit-license.php](http://www.opensource.org/licenses/mit-license.php)
