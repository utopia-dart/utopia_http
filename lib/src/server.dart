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
  Future<void> start(
    Handler handler, {
    String context = 'utopia',
    String? path,
  });

  /// Stop the server
  Future<void> stop();
}
