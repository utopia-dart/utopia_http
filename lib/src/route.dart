import 'package:utopia_dart_framework/src/hook.dart';

class Route extends Hook {
  String method = '';
  bool hook = true;
  final String _path;
  static int counter = 0;
  final Map<String, dynamic> labels = {};
  late int order;

  String get path => _path;

  Route(this.method, this._path) : super() {
    Route.counter++;
    order = counter;
  }

  Route label(String key, String value) {
    labels[key] = value;
    return this;
  }

  String? getLabel(String key, {String? defaultValue}) {
    return labels[key] ?? defaultValue;
  }
}
