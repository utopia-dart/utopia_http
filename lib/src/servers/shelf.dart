import 'dart:async';
import 'dart:io';
import 'dart:isolate' as iso;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import '../request.dart';
import '../response.dart';
import '../server.dart';

class _IsolateMessage {
  final Handler handler;
  final SecurityContext? securityContext;
  final dynamic address;
  final int port;
  final String? path;
  final String context;

  _IsolateMessage({
    required this.handler,
    required this.address,
    required this.port,
    required this.context,
    this.path,
    this.securityContext,
  });
}

class ShelfServer extends Server {
  static final List<HttpServer> _servers = [];
  Handler? handler;
  String? path;

  ShelfServer(super.address, super.port, {super.securityContext});

  @override
  Future<List<HttpServer>> serve(
    Handler handler, {
    String? path,
    int threads = 1,
  }) async {
    this.handler = handler;
    this.path = path;
    iso.ReceivePort();
    await _spawnOffIsolates(threads);
    return _servers;
  }

  static Future<void> _onIsolateMain(_IsolateMessage message) async {
    final server = await shelf_io.serve(
      message.path != null
          ? shelf.Cascade()
              .add(createStaticHandler(message.path!))
              .add(
                (request) =>
                    _handleRequest(request, message.context, message.handler),
              )
              .handler
          : (request) =>
              _handleRequest(request, message.context, message.handler),
      message.address,
      message.port,
      securityContext: message.securityContext,
      shared: true,
    );
    _servers.add(server);
  }

  Future<void> _spawnOffIsolates(int num) async {
    for (var i = 0; i < num; i++) {
      await iso.Isolate.spawn<_IsolateMessage>(
        _onIsolateMain,
        _IsolateMessage(
          context: i.toString(),
          handler: handler!,
          address: address,
          port: port,
          securityContext: securityContext,
          path: path,
        ),
      );
    }
  }

  static FutureOr<shelf.Response> _handleRequest(
    shelf.Request sheflRequest,
    String context,
    Handler handler,
  ) async {
    final request = _fromShelfRequest(sheflRequest);
    final response = await handler.call(request, context);
    return _toShelfResponse(response);
  }

  static Request _fromShelfRequest(shelf.Request shelfRequest) {
    return Request(
      shelfRequest.method,
      shelfRequest.url,
      body: shelfRequest.read(),
      headers: shelfRequest.headers,
      headersAll: shelfRequest.headersAll,
      contentType: shelfRequest.headers[HttpHeaders.contentTypeHeader],
    );
  }

  static shelf.Response _toShelfResponse(Response response) {
    final res = shelf.Response(
      response.status,
      body: response.body,
      headers: response.headers,
    );
    return res;
  }
}
