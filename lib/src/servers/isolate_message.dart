import 'dart:io';
import 'dart:isolate' as iso;

import '../server.dart';

class IsolateMessage {
  final Handler handler;
  final SecurityContext? securityContext;
  final dynamic address;
  final int port;
  final String? path;
  final String context;
  final iso.SendPort sendPort;

  IsolateMessage({
    required this.handler,
    required this.address,
    required this.port,
    required this.context,
    this.path,
    this.securityContext,
    required this.sendPort,
  });
}
