class Route {
  String method = '';
  bool middleware = true;
  String path = '';
  String description = '';
  List<String> _groups = [];
  static int counter = 0;
  Map<String, Param> _params = {};
  Map<String, dynamic> labels = {};
  late int order;
  late dynamic _action;

  List<String> getGroups() => _groups;
  Function getAction() => _action;

  Route(this.method, this.path) {
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
    this._groups = groups;
    return this;
  }

  Route label(String key, dynamic value) {
    this.labels[key] = value;
    return this;
  }

  Route param(
      {required String key,
      dynamic defaultValue,
      Function? validator,
      String description = '',
      bool optional = false}) {
    this._params[key] = Param(
        defaultValue: defaultValue,
        validator: validator,
        description: description,
        value: null,
        count: _params.values.length,
        optional: optional);
    return this;
  }
}

class Param {
  final dynamic defaultValue;
  final Function? validator;
  final String description;
  final dynamic value;
  final int count;
  final bool optional;

  Param(
      {required this.defaultValue,
      required this.validator,
      required this.description,
      required this.value,
      required this.count,
      required this.optional});
}
