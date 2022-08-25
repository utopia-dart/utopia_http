import 'types.dart';
import 'validator.dart';

class HexColor extends Validator {
  @override
  String getDescription() {
    return 'Value must be a valid Hex color code';
  }

  @override
  String getType() {
    return Types.string.name;
  }

  @override
  bool isArray() {
    return false;
  }

  @override
  bool isValid(dynamic value) {
    if (value is String &&
        RegExp(r'^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$').hasMatch(value)) {
      return true;
    }
    return false;
  }
}
