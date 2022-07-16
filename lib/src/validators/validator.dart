library utopia_dart_framework.validators;

abstract class Validator {
  String getDescription();

  bool isArray();

  bool isValid(dynamic value);

  String getType();
}
