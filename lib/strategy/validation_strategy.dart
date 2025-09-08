abstract class ValidationStrategy<T, E extends Exception> {
  void validate(T value);
}

class EmailValidationStrategy
    implements ValidationStrategy<String, EmailValidationException> {
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  @override
  void validate(String value) {
    if (!_emailRegex.hasMatch(value)) {
      throw EmailValidationException('Invalid email format');
    }
  }
}

class EmailValidationException implements Exception {
  EmailValidationException(this.message);
  final String message;

  @override
  String toString() => 'EmailValidationException: $message';
}
