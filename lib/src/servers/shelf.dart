import 'dart:async';
import 'dart:io';
import 'dart:isolate' as iso;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../request.dart';
import '../response.dart';
import '../server.dart';
import 'isolate_message.dart';
import 'isolate_supervisor.dart';

final List<IsolateSupervisor> _isolates = [];

/// ShelfServer
///
/// Create a server
class ShelfServer extends Server {
  Handler? handler;
  String? path;

  ShelfServer(super.address, super.port, {super.securityContext});

  /// Start the server
  @override
  Future<void> start(
    Handler handler, {
    String? path,
    int threads = 1,
  }) async {
    this.handler = handler;
    this.path = path;

    for (var i = 0; i < threads; i++) {
      final sup = await _spawn(i.toString());
      _isolates.add(sup);
      sup.isolate.resume(sup.isolate.pauseCapability!);
    }
  }

  Future<IsolateSupervisor> _spawn(String context) async {
    final receivePort = iso.ReceivePort();
    final message = IsolateMessage(
      context: context,
      handler: handler!,
      address: address,
      port: port,
      securityContext: securityContext,
      path: path,
      sendPort: receivePort.sendPort,
    );
    final isolate = await iso.Isolate.spawn(
      _entrypoint,
      message,
      paused: true,
      debugName: 'isolate_$context',
    );
    return IsolateSupervisor(
      isolate: isolate,
      isolateSendPort: receivePort.sendPort,
      receivePort: receivePort,
      context: message.context,
    );
  }

  /// Stop servers
  @override
  Future<void> stop() async {
    for (final supervisor in _isolates) {
      supervisor.stop();
    }
  }
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

Future<void> _entrypoint(IsolateMessage message) async {
  final iso.ReceivePort receivePort = iso.ReceivePort();
  var handler = (shelf.Request request) => _handleRequest(
        request,
        message.context,
        message.handler,
      );
  if (message.path != null) {
    handler = shelf.Cascade()
        .add(createStaticHandler(message.path!))
        .add(
          (request) => _handleRequest(
            request,
            message.context,
            message.handler,
          ),
        )
        .handler;
  }

  final server = await shelf_io.serve(
    handler,
    message.address,
    message.port,
    securityContext: message.securityContext,
    shared: true,
  );

  message.sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    if (message == IsolateSupervisor.messageClose) {
      print('server closing');
      await server.close(force: true);
      receivePort.close();
    }
  });
  print('Worker ${message.context} ready');
}

//https://dart.dev/language/isolates#sending-multiple-messages-between-isolates-with-ports
