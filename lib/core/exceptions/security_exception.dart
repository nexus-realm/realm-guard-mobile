class SecurityException implements Exception {
  final String message;

  const SecurityException([this.message = "Security exception occurred."]);

  @override
  String toString() => "SecurityException: $message";
}
