import 'dart:isolate' as iso;

class IsolateSupervisor {
  final iso.Isolate isolate;
  final iso.ReceivePort receivePort;
  final String context;
  iso.SendPort? isolateSendPort;

  static const String messageClose = '_CLOSE';

  IsolateSupervisor({
    required this.isolate,
    required this.isolateSendPort,
    required this.receivePort,
    required this.context,
  }) {
    receivePort.listen(listen);
  }

  void stop() {
    isolateSendPort?.send(messageClose);
    receivePort.close();
  }

  void listen(dynamic message) async {
    if (message is iso.SendPort) {
      isolateSendPort = message;
    }
  }
}
