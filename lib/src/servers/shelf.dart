import 'dart:async';
import 'dart:io';
import '../request.dart';
import '../response.dart';
import '../server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart' as shelf;

class ShelfServer extends Server {
  HttpServer? server;
  Handler? handler;

  ShelfServer(super.address, super.port);

  @override
  Future<HttpServer> serve(Handler handler) async {
    this.handler = handler;
    server = await shelf_io.serve(_handleRequest, address, port);
    return server!;
  }

  FutureOr<shelf.Response> _handleRequest(shelf.Request sheflRequest) async {
    final request = _fromShelfRequest(sheflRequest);
    final response = await handler!.call(request);
    return _toShelfResponse(response);
  }

  Request _fromShelfRequest(shelf.Request shelfRequest) {
    return Request(shelfRequest.method, shelfRequest.url,
        body: shelfRequest.read(),
        contentType: shelfRequest.headers[HttpHeaders.contentTypeHeader]);
  }

  shelf.Response _toShelfResponse(Response response) {
    final res = shelf.Response(response.status,
        body: response.body, headers: response.headers);
    return res;
  }
}
