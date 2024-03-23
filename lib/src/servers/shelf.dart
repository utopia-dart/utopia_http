import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../request.dart';
import '../response.dart';
import '../server.dart';

/// ShelfServer
///
/// Create a server
class ShelfServer extends Server {
  HttpServer? _server;
  ShelfServer(super.address, super.port, {super.securityContext});

  /// Start the server
  @override
  Future<void> start(
    Handler handler, {
    String context = 'utopia',
    String? path,
  }) async {
    var shelfHandler = (shelf.Request request) => _handleRequest(
          request,
          context,
          handler,
        );
    if (path != null) {
      shelfHandler = shelf.Cascade()
          .add(createStaticHandler(path))
          .add(
            (request) => _handleRequest(
              request,
              context,
              handler,
            ),
          )
          .handler;
    }

    _server = await shelf_io.serve(
      shelfHandler,
      address,
      port,
      securityContext: securityContext,
      shared: true,
    );
  }

  /// Stop servers
  @override
  Future<void> stop() async {
    await _server?.close(force: true);
  }

  FutureOr<shelf.Response> _handleRequest(
    shelf.Request sheflRequest,
    String context,
    Handler handler,
  ) async {
    final request = _fromShelfRequest(sheflRequest);
    final response = await handler.call(request, context);
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
