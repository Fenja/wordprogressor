/// Stub implementation for native platforms (Android, iOS, Desktop).
/// The real web implementation lives in notification_service_web.dart
/// and is only compiled when dart.library.html is available.

Future<void> requestWebPermission() async {}

void showWebNotification({
  required String title,
  required String body,
  String? icon,
}) {}