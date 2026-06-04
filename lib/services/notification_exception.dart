/// Thrown when a notification-layer operation fails.
class NotificationException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  const NotificationException(this.message, {this.cause});

  @override
  String toString() {
    if (cause != null) {
      return 'NotificationException: $message (cause: $cause)';
    }
    return 'NotificationException: $message';
  }
}
