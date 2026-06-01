/// Thrown when a message-layer operation fails.
class MessageException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  const MessageException(this.message, {this.cause});

  @override
  String toString() {
    if (cause != null) {
      return 'MessageException: $message (cause: $cause)';
    }
    return 'MessageException: $message';
  }
}
