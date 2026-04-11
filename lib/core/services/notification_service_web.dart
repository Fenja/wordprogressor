// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Request permission for browser notifications.
/// Must be called in response to a user gesture on first use.
Future<void> requestWebPermission() async {
  if (html.Notification.supported) {
    await html.Notification.requestPermission();
  }
}

/// Show a browser notification immediately.
void showWebNotification({
  required String title,
  required String body,
  String? icon,
}) {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;

  html.Notification(
    title,
    body: body,
    icon: icon ?? '/icons/Icon-192.png',
  );
}