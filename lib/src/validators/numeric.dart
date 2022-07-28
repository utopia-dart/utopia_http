import 'package:utopia_dart_framework/src/validators/types.dart';
import 'package:utopia_dart_framework/src/validators/validator.dart';

class Numeric extends Validator {
  @override
  String getDescription() {
    return 'Value must be a valid number';
  }

  @override
  String getType() {
    return Types.num.name;
  }

  @override
  bool isArray() {
    return false;
  }

  @override
  bool isValid(value) {
    if (value is! int && value is! double && value is! num) {
      return false;
    }
    return true;
  }
}
