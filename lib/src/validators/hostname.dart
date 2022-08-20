import 'types.dart';
import 'validator.dart';

class Hostname extends Validator {
  final List<String> _allowList;

  Hostname([this._allowList = const []]);

  @override
  String getDescription() {
    return 'Value must be a valid hostname without path, port or protocol.';
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
    if (value is! String || value.isEmpty) return false;
    if (value.length > 253) return false;
    if (value.contains('/')) return false;
    if (_allowList.isEmpty) return true;
    for (final allowedHostname in _allowList) {
      if (value == allowedHostname || allowedHostname == '*') return true;
      if (allowedHostname.contains('*')) {
        final allowedSections = allowedHostname.split('.');
        final valueSections = value.split('.');

        if (allowedSections.length == valueSections.length) {
          var matchesAmount = 0;
          for (var sectionIndex = 0;
              sectionIndex < allowedSections.length;
              sectionIndex++) {
            final allowedsection = allowedSections[sectionIndex];
            if (allowedsection == '*' ||
                allowedsection == valueSections[sectionIndex]) {
              matchesAmount++;
            } else {
              break;
            }
          }

          if (matchesAmount == allowedSections.length) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
