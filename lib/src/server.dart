import 'dart:async';
import 'dart:io';
import 'request.dart';
import 'response.dart';

typedef Handler = FutureOr<Response> Function(Request);

abstract class Server {
  final int port;
  final dynamic address;

  Server(this.address, this.port);

  Future<HttpServer> serve(Handler handler);
}
