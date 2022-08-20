import 'dart:convert';
import 'types.dart';
import 'validator.dart';

class JSON extends Validator {
  @override
  String getDescription() {
    return 'Value must be a valid JSON';
  }

  @override
  String getType() {
    return Types.json.name;
  }

  @override
  bool isArray() {
    return false;
  }

  @override
  bool isValid(dynamic value) {
    if (value is Map) {
      return true;
    }

    if (value is String) {
      try {
        jsonDecode(value);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
