import 'dart:developer' as dev;
import 'dart:isolate' as iso;

class IsolateSupervisor {
  final iso.Isolate isolate;
  final iso.ReceivePort receivePort;
  final String context;
  iso.SendPort? _isolateSendPort;

  static const String messageClose = '_CLOSE';

  IsolateSupervisor({
    required this.isolate,
    required this.receivePort,
    required this.context,
  });

  void resume() {
    receivePort.listen(listen);
    isolate.resume(isolate.pauseCapability!);
  }

  void stop() {
    dev.log('Stopping isolate $context', name: 'FINE');
    _isolateSendPort?.send(messageClose);
    receivePort.close();
  }

  void listen(dynamic message) async {
    if (message is iso.SendPort) {
      _isolateSendPort = message;
    }
  }
}
