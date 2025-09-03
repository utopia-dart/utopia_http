import 'dart:io';
import 'package:utopia_http/utopia_http.dart';

void main() async {
  await HttpDev.start(
    script: () async {
      final address = InternetAddress.anyIPv4;
      final port = Http.getEnv('PORT', 8080);

      print('🚀 Starting Utopia HTTP Server with Hot Reload...');
      print('🌐 Address: ${address.address}:$port');
      print('');

      // Create HTTP server
      final app = Http(
        ShelfServer(address, port),
        threads: 2,
      );

      // Define routes
      app.get('/').inject('response').action((Response response) {
        response.text(
            'Hello from Utopia HTTP with Hot Reload! 🔥 [AUTO-RELOAD sachai ho?]');
        return response;
      });

      app.get('/api/status').inject('response').action((Response response) {
        response.json({
          'status': 'running',
          'mode': 'development',
          'hot_reload': true,
          'version': '2.0',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return response;
      });

      app
          .get('/api/hello/:name')
          .param(
              key: 'name', defaultValue: 'World', description: 'Name to greet')
          .inject('response')
          .action((String name, Response response) {
        response.json({
          'greeting': 'Hello, $name! 👋',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return response;
      });

      // Add request logging
      app.init().inject('request').action((Request request) {
        final timestamp = DateTime.now().toIso8601String();
        final method = request.method.padRight(6);
        print('📥 $timestamp - $method ${request.url}');
      });

      // Add error handling
      app.error().inject('error').inject('response').action(
        (Exception error, Response response) {
          response.json(
            {
              'error': error.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
            status: HttpStatus.internalServerError,
          );
          return response;
        },
      );

      try {
        await app.start();
        print('✅ Server started successfully!');
        print('🌐 Server URL: http://${address.address}:${app.server.port}');
        print('');
        print('📡 Available endpoints:');
        print('  GET  /                - Hello message');
        print('  GET  /api/status      - Server status');
        print('  GET  /api/hello/:name - Personalized greeting');
        print('');
        print('🔥 Hot reload is active - edit this file to see changes!');
        print('');

        // Keep the server running
        await ProcessSignal.sigint.watch().first;
      } catch (e) {
        print('❌ Failed to start server: $e');
        exit(1);
      } finally {
        await app.stop();
        app.dispose();
      }
    },
    watchPaths: ['lib', 'example'],
    watchExtensions: ['.dart'],
  );
}
