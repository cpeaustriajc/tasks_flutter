abstract class ValidationStrategy<T, E extends Exception> {
  void validate(T value);
}

class EmailValidationStrategy
    implements ValidationStrategy<String, EmailValidationException> {
  @override
  void validate(String value) {
    final bool isValid = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    ).hasMatch(value);

    if (!isValid) {
      throw EmailValidationException('Invalid email format');
    }

    return;
  }
}

class EmailValidationException implements Exception {
  EmailValidationException(this.message);
  final String message;

  @override
  String toString() => 'EmailValidationException: $message';
}
