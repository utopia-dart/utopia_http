import 'dart:async';
import 'dart:io';
import 'package:utopia_dart_framework/src/request.dart';
import 'package:utopia_dart_framework/src/response.dart';

typedef Handler = FutureOr<Response> Function(Request);

abstract class Server {
  final int port;
  final dynamic address;

  Server(this.address, this.port);

  Future<HttpServer> serve(Handler handler);
}
