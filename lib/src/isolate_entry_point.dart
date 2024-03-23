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
  receivePort.listen((data) async {
    if (data == IsolateSupervisor.messageClose) {
      await message.server.stop();
      receivePort.close();
    }
  });
}
