import 'dart:io';
import 'dart:isolate' as iso;
import 'package:test/test.dart';
import 'package:utopia_http/src/isolate_message.dart';
import 'package:utopia_http/src/isolate_supervisor.dart';
import 'package:utopia_http/utopia_http.dart';

void main() {
  group('IsolateMessage', () {
    test('can be created with required parameters', () {
      final receivePort = iso.ReceivePort();
      final sendPort = receivePort.sendPort;
      final server = ShelfServer(InternetAddress.loopbackIPv4, 8080);
      
      final message = IsolateMessage(
        server: server,
        handler: (request, context) => Response('test'),
        context: 'test_context',
        sendPort: sendPort,
      );
      
      expect(message.server, server);
      expect(message.context, 'test_context');
      expect(message.sendPort, sendPort);
      expect(message.handler, isA<Handler>());
      
      receivePort.close();
    });

    test('optional parameters can be null', () {
      final receivePort = iso.ReceivePort();
      final sendPort = receivePort.sendPort;
      final server = ShelfServer(InternetAddress.loopbackIPv4, 8080);
      
      final message = IsolateMessage(
        server: server,
        handler: (request, context) => Response('test'),
        context: 'test_context',
        sendPort: sendPort,
      );
      
      expect(message.path, isNull);
      expect(message.securityContext, isNull);
      
      receivePort.close();
    });
  });

  group('IsolateSupervisor', () {
    test('can be created with required parameters', () {
      final receivePort = iso.ReceivePort();
      final isolate = iso.Isolate.current;
      
      final supervisor = IsolateSupervisor(
        isolate: isolate,
        receivePort: receivePort,
        context: 'test_supervisor',
      );
      
      expect(supervisor.isolate, isolate);
      expect(supervisor.receivePort, receivePort);
      expect(supervisor.context, 'test_supervisor');
      
      receivePort.close();
    });

    test('has messageClose constant', () {
      expect(IsolateSupervisor.messageClose, '_CLOSE');
    });
  });
}