import 'package:utopia_di/utopia_di.dart';

import 'request.dart';

/// Route
///
/// A http route
class Route extends Hook {
  /// HTTP method
  String method = '';

  /// Whether or not hook is enabled
  bool hook = true;

  /// Route path
  String path;
  static int counter = 0;
  final List<String> _aliases = [];
  final Map<String, dynamic> labels = {};

  final Map<String, int> _pathParams = {};

  Route(this.method, this.path) : super() {
    Route.counter++;
    order = counter;
  }

  /// Get route aliases
  List<String> get aliases => _aliases;
  Map<String, int> get pathParams => _pathParams;

  /// Add a route alias
  Route alias(String path) {
    if (!_aliases.contains(path)) {
      _aliases.add(path);
    }

    return this;
  }

  /// Set path params
  void setPathParam(String key, int index) {
    _pathParams[key] = index;
  }

  /// Get values for path params
  Map<String, String> getPathValues(Request request) {
    var pathValues = <String, String>{};
    var parts = request.url.path.split('/').where((part) => part.isNotEmpty);

    for (var entry in pathParams.entries) {
      if (entry.value < parts.length) {
        pathValues[entry.key] = parts.elementAt(entry.value);
      }
    }

    return pathValues;
  }

  /// Set route label
  Route label(String key, String value) {
    labels[key] = value;
    return this;
  }

  /// Get route label
  String? getLabel(String key, {String? defaultValue}) {
    return labels[key] ?? defaultValue;
  }
}
