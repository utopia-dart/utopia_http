import 'package:utopia_dart_framework/src/validators/validator.dart';

class Hook {
  String description = '';
  List<String> _groups = [];
  static int counter = 0;
  final Map<String, Param> _params = {};
  final Map<String, Injection> _injections = {};
  late int order;
  late dynamic _action;

  Map<String, Injection> get injections => _injections;
  Map<String, Param> get params => _params;

  List<String> getGroups() => _groups;
  Function getAction() => _action;

  Hook() {
    Hook.counter++;
    order = counter;
    _action = () {};
  }

  Hook action(Function action) {
    _action = action;
    return this;
  }

  Hook desc(String description) {
    this.description = description;
    return this;
  }

  Hook groups(List<String> groups) {
    _groups = groups;
    return this;
  }

  Hook inject(String injection) {
    if (_injections.containsKey(injection)) {
      throw Exception("Injection already declared for $injection");
    }
    _injections[injection] =
        Injection(injection, _params.length + _injections.length);
    return this;
  }

  Hook param(
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
