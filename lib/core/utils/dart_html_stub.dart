// Stub for dart:html on native platforms (Android, iOS, Desktop).
// On web, the real dart:html is used via conditional import.
// This file is never executed on native — it only satisfies the compiler.

class HttpRequest {
  final dynamic response = null;

  static Future<HttpRequest> request(
      String url, {
        String? method,
        String? responseType,
        Map<String, String>? requestHeaders,
      }) async {
    throw UnsupportedError(
        'dart:html.HttpRequest is not available on native platforms.');
  }
}