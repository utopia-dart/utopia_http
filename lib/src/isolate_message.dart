import 'dart:io';
import 'dart:isolate' as iso;

import 'server.dart';

class IsolateMessage {
  final Handler handler;
  final SecurityContext? securityContext;
  final String? path;
  final String context;
  final iso.SendPort sendPort;
  final Server server;

  IsolateMessage({
    required this.server,
    required this.handler,
    required this.context,
    this.path,
    this.securityContext,
    required this.sendPort,
  });
}
