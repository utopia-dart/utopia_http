import 'dart:async';
import 'dart:io';
import 'dart:isolate' as iso;
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

  Future<HttpServer> onIsolateMain(String message) async {
    server = await shelf_io.serve(
      path != null
          ? shelf.Cascade()
              .add(createStaticHandler(path!))
              .add(_handleRequest)
              .handler
          : _handleRequest,
      address,
      port,
      securityContext: securityContext,
      shared: true,
    );
    return server!;
  }

  @override
  Future<HttpServer?> serve(Handler handler,
      {String? path, int threads = 1}) async {
    this.handler = handler;
    this.path = path;
    await spawnOffIsolates(threads);
    return null;
  }

  Future<void> spawnOffIsolates(int num) async {
    for (var i = 0; i < num; i++) {
      iso.Isolate.spawn(onIsolateMain, "$i");
    }
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
