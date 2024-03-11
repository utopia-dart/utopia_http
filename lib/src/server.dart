import 'dart:async';
import 'dart:io';
import 'request.dart';
import 'response.dart';

/// Server request handler
typedef Handler = FutureOr<Response> Function(Request, String);

/// Server adapter
abstract class Server {
  /// Server port
  final int port;

  /// Server address
  final dynamic address;

  /// Server security context
  final SecurityContext? securityContext;

  Server(this.address, this.port, {this.securityContext});

  /// Start the server
  Future<List<HttpServer>> start(
    Handler handler, {
    String? path,
    int threads = 1,
  });
}
