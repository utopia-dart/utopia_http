import 'dart:async';
import 'dart:io';
import 'request.dart';
import 'response.dart';

typedef Handler = FutureOr<Response> Function(Request);

abstract class Server {
  final int port;
  final dynamic address;
  final SecurityContext? securityContext;

  Server(this.address, this.port, {this.securityContext});

  Future<HttpServer?> serve(Handler handler, {String? path, int threads = 1});
}
