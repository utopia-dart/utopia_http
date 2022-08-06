import 'numeric.dart';
import 'types.dart';

class Range extends Numeric {
  final num _min;
  final num _max;

  Types _format = Types.int;

  Types get format => _format;
  num get min => _min;
  num get max => _max;

  Range(this._min, this._max, {Types? format}) {
    _format = format ?? _format;
  }

  @override
  String getType() {
    return _format.name;
  }

  @override
  bool isValid(dynamic value) {
    if (!super.isValid(value)) {
      return false;
    }
    switch (_format) {
      case Types.int:
        if (value is! int) {
          return false;
        }
        break;
      case Types.double:
        if (value is! double) {
          return false;
        }
        break;
      default:
        return false;
    }
    if (_min <= value && _max >= value) {
      return true;
    }
    return false;
  }
}
