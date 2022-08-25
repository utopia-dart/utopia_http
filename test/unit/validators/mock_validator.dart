import 'package:utopia_framework/utopia_validators.dart' show Validator;

/// A mocked version of the [Validator] class.
///
/// The setters [description], [type], [validity] and [array] can be used as
/// stubs to define certain behavior without having to rely on third party
/// mocking libraries.
///
/// The setters need to be invoked first before calling the corresponding
/// methods, or else `LateInitializationError` is thrown.
class MockValidator implements Validator {
  late String _description, _type;
  late bool _isValid, _isArray;

  set description(String description) => _description = description;

  set type(String type) => _type = type;

  set validity(bool isValid) => _isValid = isValid;

  set array(bool isArray) => _isArray = isArray;

  @override
  String getDescription() {
    return _description;
  }

  @override
  String getType() {
    return _type;
  }

  @override
  bool isValid(value) {
    return _isValid;
  }

  @override
  bool isArray() {
    return _isArray;
  }
}
