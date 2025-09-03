/// Development server functionality has been moved to the utopia_hotreload package
///
/// For advanced hot reload features, use the `utopia_hotreload` package:
///
/// ```yaml
/// dependencies:
///   utopia_http: ^0.1.0
/// dev_dependencies:
///   utopia_hotreload: ^1.0.0
/// ```
///
/// ```dart
/// import 'package:utopia_hotreload/utopia_hotreload.dart';
///
/// void main() async {
///   await DeveloperTools.start(
///     script: () async {
///       // Your server code here
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
///
/// The utopia_hotreload package provides:
/// - True hot reload using Dart VM service (preserves state like Flutter)
/// - Hot restart for when hot reload isn't possible
/// - Auto mode that tries hot reload first, then falls back to restart
/// - Flutter-like commands: 'r' for hot reload, 'R' for hot restart
/// - File watching with configurable paths and extensions
