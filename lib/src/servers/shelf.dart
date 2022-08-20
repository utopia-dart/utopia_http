import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import '../request.dart';
import '../response.dart';
import '../server.dart';

class ShelfServer extends Server {
  HttpServer? server;
  Handler? handler;
  String? path;

  ShelfServer(super.address, super.port, {super.securityContext});

  @override
  Future<HttpServer> serve(Handler handler, {String? path}) async {
    this.handler = handler;
    this.path = path;

    server = await shelf_io.serve(
      path != null
          ? shelf.Cascade()
              .add(createStaticHandler(path))
              .add(_handleRequest)
              .handler
          : _handleRequest,
      address,
      port,
      securityContext: securityContext,
    );
    return server!;
  }

  FutureOr<shelf.Response> _handleRequest(shelf.Request sheflRequest) async {
    final request = _fromShelfRequest(sheflRequest);
    final response = await handler!.call(request);
    return _toShelfResponse(response);
  }

  Request _fromShelfRequest(shelf.Request shelfRequest) {
    return Request(
      shelfRequest.method,
      shelfRequest.url,
      body: shelfRequest.read(),
      headers: shelfRequest.headers,
      headersAll: shelfRequest.headersAll,
      contentType: shelfRequest.headers[HttpHeaders.contentTypeHeader],
    );
  }

  shelf.Response _toShelfResponse(Response response) {
    final res = shelf.Response(
      response.status,
      body: response.body,
      headers: response.headers,
    );
    return res;
  }
}
