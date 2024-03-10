import 'dart:async';
import 'dart:io';
import 'request.dart';
import 'response.dart';

typedef Handler = FutureOr<Response> Function(Request, String);

abstract class Server {
  final int port;
  final dynamic address;
  final SecurityContext? securityContext;

  Server(this.address, this.port, {this.securityContext});

  Future<List<HttpServer>> serve(
    Handler handler, {
    String? path,
    int threads = 1,
  });
}
