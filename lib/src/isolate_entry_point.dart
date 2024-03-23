import 'dart:isolate';

import 'isolate_message.dart';
import 'isolate_supervisor.dart';

Future<void> entrypoint(IsolateMessage message) async {
  final ReceivePort receivePort = ReceivePort();
  await message.server.start(
    message.handler,
    path: message.path,
    context: message.context,
  );

  message.sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    if (message == IsolateSupervisor.messageClose) {
      print('server closing');
      await message.server.close(force: true);
      receivePort.close();
    }
  });
  print('Worker ${message.context} ready');
}
