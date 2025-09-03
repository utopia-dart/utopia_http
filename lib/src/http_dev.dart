import 'dart:async';
import 'dart:io';

/// Development server with hot reload functionality
///
/// Provides automatic process restart when source files change,
/// ensuring all code changes are immediately reflected.
class HttpDev {
  HttpDev._();

  /// Start a development server with hot reload
  ///
  /// This will restart the entire Dart process when files change,
  /// ensuring all code changes (routes, handlers, imports) are picked up.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   await HttpDev.start(
  ///     script: () async {
  ///       final app = Http(ShelfServer(InternetAddress.anyIPv4, 8080));
  ///       app.get('/').inject('response').action((Response response) {
  ///         response.text('Hello with hot reload!');
  ///         return response;
  ///       });
  ///       await app.start();
  ///     },
  ///     watchPaths: ['lib', 'example'],
  ///     watchExtensions: ['.dart'],
  ///   );
  /// }
  /// ```
  static Future<void> start({
    required Future<void> Function() script,
    List<String> watchPaths = const ['lib', 'example'],
    List<String> watchExtensions = const ['.dart'],
    List<String> ignorePatterns = const [
      '.git/',
      '.dart_tool/',
      'build/',
      'test/'
    ],
  }) async {
    // Check if we're already in a child process (to avoid infinite recursion)
    if (Platform.environment['UTOPIA_DEV_CHILD'] == 'true') {
      // We're in the child process, just run the script
      await script();
      return;
    }

    // We're in the parent process, set up hot reload
    print('🚀 Starting Utopia HTTP Development Server with Hot Reload...');
    print('📁 Watching paths: $watchPaths');
    print('📄 Watching extensions: $watchExtensions');
    print('🔄 Hot reload enabled - file changes will restart the process');
    print('');

    Process? currentProcess;
    bool isRestarting = false;

    // Handle Ctrl+C gracefully
    ProcessSignal.sigint.watch().listen((signal) async {
      print('\n🛑 Shutting down development server...');
      if (currentProcess != null) {
        print('   Stopping child process...');
        currentProcess!.kill(ProcessSignal.sigint);
        try {
          await currentProcess!.exitCode.timeout(Duration(seconds: 2));
        } catch (e) {
          // Force kill if graceful shutdown fails
          currentProcess!.kill(ProcessSignal.sigkill);
        }
      }
      print('✅ Development server stopped');
      exit(0);
    });

    // Function to start the child process
    Future<void> startChildProcess() async {
      if (isRestarting) return;

      try {
        print('🔄 Starting server process...');

        // Get current script path and arguments
        final scriptPath = Platform.script.toFilePath();
        final args = List<String>.from(Platform.executableArguments);

        // Start child process with environment variable to indicate it's a child
        currentProcess = await Process.start(
          Platform.executable,
          [...args, scriptPath],
          environment: {
            ...Platform.environment,
            'UTOPIA_DEV_CHILD': 'true',
          },
          mode: ProcessStartMode.normal,
        );

        // Forward stdout and stderr
        currentProcess!.stdout.listen((data) {
          stdout.add(data);
        });

        currentProcess!.stderr.listen((data) {
          stderr.add(data);
        });

        // Wait for process to exit
        final exitCode = await currentProcess!.exitCode;

        if (!isRestarting) {
          if (exitCode == 0) {
            print('✅ Process exited normally');
          } else {
            print('❌ Process exited with code: $exitCode');
          }
        }
      } catch (e) {
        print('❌ Error starting process: $e');
      }
    }

    // Function to restart the child process
    Future<void> restartChildProcess() async {
      if (isRestarting) return;

      isRestarting = true;
      print('🔄 Restarting due to file change...');

      if (currentProcess != null) {
        currentProcess!.kill(ProcessSignal.sigterm);
        try {
          await currentProcess!.exitCode.timeout(Duration(seconds: 2));
        } catch (e) {
          // Force kill if graceful shutdown fails
          currentProcess!.kill(ProcessSignal.sigkill);
        }
      }

      // Small delay to ensure clean shutdown
      await Future.delayed(Duration(milliseconds: 300));

      isRestarting = false;
      await startChildProcess();
    }

    // Set up file watchers
    final watchers = <StreamSubscription>[];
    Timer? debounceTimer;

    for (final path in watchPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        print('👁️  Watching directory: ${dir.absolute.path}');

        final watcher = dir.watch(recursive: true).listen((event) {
          final filePath = event.path;

          // Check if file should be watched
          bool shouldWatch = false;
          for (final ext in watchExtensions) {
            if (filePath.endsWith(ext)) {
              shouldWatch = true;
              break;
            }
          }

          if (!shouldWatch) return;

          // Check ignore patterns
          for (final pattern in ignorePatterns) {
            if (filePath.contains(pattern)) {
              return;
            }
          }

          // Debounce file changes
          debounceTimer?.cancel();
          debounceTimer = Timer(Duration(milliseconds: 500), () {
            final currentDir = Directory.current.path;
            String relativePath = filePath;
            if (filePath.startsWith(currentDir)) {
              relativePath = filePath.substring(currentDir.length);
              if (relativePath.startsWith(Platform.pathSeparator)) {
                relativePath = relativePath.substring(1);
              }
            }
            print('📝 File changed: $relativePath');
            restartChildProcess();
          });
        });

        watchers.add(watcher);
      } else {
        print('⚠️  Watch path does not exist: $path');
      }
    }

    if (watchers.isEmpty) {
      print('❌ No valid watch paths found, running without hot reload');
      await script();
      return;
    }

    print('');

    // Start the initial child process
    await startChildProcess();

    // Keep the parent process alive
    while (true) {
      await Future.delayed(Duration(seconds: 1));
    }
  }
}
