import 'dart:async';
import 'dart:io';
import '../request.dart';
import '../response.dart';
import '../server.dart';

class DefaultServer extends Server {
  HttpServer? server;
  Handler? handler;

  DefaultServer(super.address, super.port);

  @override
  Future<HttpServer> serve(Handler handler) async {
    this.handler = handler;
    server = await HttpServer.bind(address, port);
    _handleRequest();
    return server!;
  }

  void _handleRequest() async {
    server!.forEach((httpRequest) async {
      final request = _fromHttpRequest(httpRequest);
      final response = await handler!.call(request);
      _toHttpResponse(response, httpRequest.response);
    });
  }

  Request _fromHttpRequest(HttpRequest httpRequest) {
    final headers = <String, String>{};
    final headersAll = <String, List<String>>{};
    httpRequest.headers.forEach((name, values) {
      headersAll[name] = values;
      headers[name] = values.join(',');
    });
    return Request(
      httpRequest.method,
      httpRequest.uri,
      headers: headers,
      headersAll: headersAll,
      contentType: httpRequest.headers.value(HttpHeaders.contentTypeHeader),
      body: httpRequest,
    );
  }

  void _toHttpResponse(Response response, HttpResponse httpResponse) {
    httpResponse.statusCode = response.status;
    response.headers.forEach((name, value) {
      httpResponse.headers.set(name, value);
    });
    httpResponse.write(response.body);
    httpResponse.close();
  }
}
