import 'validator.dart';

class ArrayList extends Validator {
  final Validator validator;
  final int length;

  ArrayList(this.validator, {this.length = 0});

  @override
  String getDescription() {
    return 'Value must be a valid array and ${validator.getDescription()}';
  }

  @override
  String getType() {
    return validator.getType();
  }

  @override
  bool isArray() {
    return true;
  }

  @override
  bool isValid(dynamic value) {
    if (value is! Iterable) {
      return false;
    }

    if (length != 0 && value.length > length) {
      return false;
    }
    for (final element in value) {
      if (!validator.isValid(element)) {
        return false;
      }
    }
    return true;
  }
}
