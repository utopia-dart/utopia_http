import 'package:utopia_dart_framework/utopia_dart_framework.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart' as shelf;

void main() {
  App.get('/hello-world').action(() {
    return 'hello world';
  });
  shelf_io.serve((request) async {
    // print(await request.readAsString());
    final response = await App.run(Request(
      request.method,
      request.url,
      headers: request.headers,
      headersAll: request.headersAll,
      encoding: request.encoding,
      contentType: request.mimeType,
      body: request.read()
    ));
    return shelf.Response.ok(response.body);
  }, 'localhost', 8080);
}
