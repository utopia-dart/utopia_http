import 'package:utopia_dart_framework/src/validators/validator.dart';

class Route {
  String method = '';
  bool middleware = true;
  final String _path;
  String description = '';
  List<String> _groups = [];
  static int counter = 0;
  final Map<String, Param> _params = {};
  final Map<String, dynamic> labels = {};
  final Map<String, Injection> _injections = {};
  late int order;
  late dynamic _action;

  Map<String, Injection> get injections => _injections;
  Map<String, Param> get params => _params;
  String get path => _path;

  List<String> getGroups() => _groups;
  Function getAction() => _action;

  Route(this.method, this._path) {
    Route.counter++;
    order = counter;
    _action = () {};
  }

  Route action(Function action) {
    _action = action;
    return this;
  }

  Route desc(String description) {
    this.description = description;
    return this;
  }

  Route groups(List<String> groups) {
    _groups = groups;
    return this;
  }

  Route label(String key, String value) {
    labels[key] = value;
    return this;
  }

  String? getLabel(String key, {String? defaultValue}) {
    return labels[key];
  }

  Route inject(String injection) {
    if (_injections.containsKey(injection)) {
      throw Exception("Injection already declared for $injection");
    }
    _injections[injection] =
        Injection(injection, _params.length + _injections.length);
    return this;
  }

  Route param(
      {required String key,
      dynamic defaultValue,
      Validator? validator,
      String description = '',
      bool optional = false}) {
    _params[key] = Param(
        defaultValue: defaultValue,
        validator: validator,
        description: description,
        value: null,
        order: _params.values.length + _injections.values.length,
        optional: optional);
    return this;
  }
}

class Injection {
  final String name;
  final int order;

  Injection(this.name, this.order);
}

class Param {
  final dynamic defaultValue;
  final Validator? validator;
  final String description;
  final dynamic value;
  final int order;
  final bool optional;

  Param(
      {required this.defaultValue,
      required this.validator,
      required this.description,
      required this.value,
      required this.order,
      required this.optional});
}
