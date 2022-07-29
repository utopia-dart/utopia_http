import 'types.dart';
import 'validator.dart';

class Text extends Validator {
  static List<String> numbers = '0123456789'.split('');
  static List<String> alphabetUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  static List<String> alphabetLower = 'abcdefghijklmnopqrstuvwxyz'.split('');

  final int _length;
  final List<String> _allowList;

  Text({int length = 0, List<String> allowList = const []})
      : _allowList = allowList,
        _length = length;

  @override
  String getDescription() {
    String message = 'Value must be a valid string';

    if (_length > 0) {
      message += ' and no longer than $_length chars';
    }

    if (_allowList.isNotEmpty) {
      message += ' and only consist of \'${_allowList.join(",")}\' chars';
    }

    return message;
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
    if (value is! String) {
      return false;
    }

    if (value.length > _length && _length != 0) {
      return false;
    }

    if (_allowList.isNotEmpty) {
      bool valid = true;
      value.split('').forEach((element) {
        if (!_allowList.contains(element)) {
          valid = false;
        }
      });
      return valid;
    }

    return true;
  }
}
