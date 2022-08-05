import 'validator.dart';

class AllowList<T> extends Validator {
  final List<T> _list;

  List<T> get list => _list;

  AllowList(this._list, {bool strict = false});

  @override
  String getDescription() {
    return 'Value must of one of (${_list.join(", ")})';
  }

  @override
  String getType() {
    return T.toString();
  }

  @override
  bool isArray() {
    return false;
  }

  @override
  bool isValid(value) {
    if (value is List) return false;

    if (!_list.contains(value)) return false;

    return true;
  }
}
