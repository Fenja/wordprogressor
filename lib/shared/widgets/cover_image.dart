import 'dart:io';
import 'dart:typed_data';

// Conditional import: dart:html on web, no-op stub on native.
// This prevents the 'dart:html not available on this platform' compile error.
import 'package:wordprogressor/core/utils/dart_html_stub.dart'
if (dart.library.html) 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays a project cover image with platform-adaptive loading.
///
/// ## Root cause of statusCode 0 on web
///
/// Flutter Web's `Image.network` uses the browser's `<img>` element or
/// CanvasKit's fetch — both are subject to CORS preflight. Firebase Storage
/// returns CORS headers only when the `Origin` is whitelisted via `gsutil
/// cors set`. Even with CORS configured, `Image.network` cannot attach an
/// `Authorization` header because Flutter Web's image pipeline does not
/// support custom headers on `<img>` elements.
///
/// ## Solution
///
/// On web we fetch the raw bytes manually using `dart:html.HttpRequest`
/// with the Firebase user's ID token in the `Authorization` header.
/// Firebase Storage accepts Bearer tokens in addition to the query-string
/// token, so this works without changing Storage rules.
/// The bytes are then rendered with `Image.memory` — identical to native.
///
/// On native, `FirebaseStorage.ref.getData()` is used (unchanged).
class CoverImage extends ConsumerWidget {
  final String? localPath;
  final String? remoteUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const CoverImage({
    super.key,
    this.localPath,
    this.remoteUrl,
    this.width = 56,
    this.height = 78,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme    = Theme.of(context);
    final hasImage = localPath != null || remoteUrl != null;

    return Semantics(
      label: hasImage ? 'Projektcover' : 'Kein Coverbild',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: width,
          height: height,
          child: _buildContent(ref, theme),
        ),
      ),
    );
  }

  Widget _buildContent(WidgetRef ref, ThemeData theme) {
    // Native: local file takes priority
    if (!kIsWeb && localPath != null) {
      return Image.file(
        File(localPath!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => remoteUrl != null
            ? _RemoteImage(remoteUrl: remoteUrl!, width: width, height: height, fit: fit)
            : _Placeholder(width: width, theme: theme),
      );
    }

    if (remoteUrl != null) {
      return _RemoteImage(
          remoteUrl: remoteUrl!, width: width, height: height, fit: fit);
    }

    return _Placeholder(width: width, theme: theme);
  }
}

// ── Remote image — native + web ───────────────────────────────────────────────

class _RemoteImage extends ConsumerWidget {
  final String remoteUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const _RemoteImage({
    required this.remoteUrl,
    required this.width,
    required this.height,
    required this.fit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_coverBytesProvider(remoteUrl));

    return async.when(
      loading: () => _LoadingIndicator(width: width, height: height, theme: theme),
      error: (e, _) {
        debugPrint('CoverImage: failed to load — $e');
        return _Placeholder(width: width, theme: theme);
      },
      data: (bytes) => bytes != null
          ? Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _Placeholder(width: width, theme: theme),
      )
          : _Placeholder(width: width, theme: theme),
    );
  }
}

// ── Unified bytes provider — platform-adaptive fetch ─────────────────────────

/// Downloads cover image bytes for both native and web.
///
/// Native:  `FirebaseStorage.ref.getData()` — SDK handles auth automatically.
///
/// Web:     `getDownloadURL()` to get the HTTPS token-URL, then fetch the
///          bytes using `dart:html.HttpRequest` with the Firebase user's
///          ID token in the `Authorization` header. This bypasses the CORS
///          limitation of `Image.network` / `<img>` elements entirely because
///          `XMLHttpRequest` with `responseType = 'arraybuffer'` and a proper
///          `Authorization` header is a credentialed CORS request — the
///          browser sends the `Origin` header, Firebase Storage responds with
///          `Access-Control-Allow-Origin`, and the bytes arrive correctly.
///
///          Prerequisite: CORS must be configured on the Storage bucket:
///          `gsutil cors set cors.json gs://your-bucket.appspot.com`
///          where cors.json allows your origin (localhost for dev, your domain
///          for production).
final _coverBytesProvider =
FutureProvider.family<Uint8List?, String>((ref, storageUrl) async {
  try {
    final storageRef = FirebaseStorage.instance.refFromURL(storageUrl);

    if (!kIsWeb) {
      // ── Native ──────────────────────────────────────────────────────────
      return await storageRef.getData(5 * 1024 * 1024);
    } else {
      // ── Web ─────────────────────────────────────────────────────────────
      // Step 1: get a fresh download URL (token embedded, no Bearer needed
      //         for this step — SDK uses the JS Firebase SDK internally)
      final downloadUrl = await storageRef.getDownloadURL();

      // Step 2: get the current user's ID token for the Authorization header
      final user    = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      // Step 3: fetch with dart:html.HttpRequest so we control the headers
      //         and responseType — avoids <img> CORS limitations entirely.
      final request = await html.HttpRequest.request(
        downloadUrl,
        method: 'GET',
        responseType: 'arraybuffer',
        requestHeaders: idToken != null
            ? {'Authorization': 'Firebase $idToken'}
            : {},
      );

      // responseText is null for arraybuffer; use response (a ByteBuffer)
      final buffer = request.response;
      if (buffer == null) return null;

      // Convert JS ByteBuffer → Dart Uint8List
      return Uint8List.view(buffer as ByteBuffer);
    }
  } catch (e) {
    debugPrint('_coverBytesProvider [${ kIsWeb ? "web" : "native"}]: $e');
    return null;
  }
});

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  final double width;
  final double height;
  final ThemeData theme;

  const _LoadingIndicator({
    required this.width,
    required this.height,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: (width * 0.35).clamp(12.0, 24.0),
          height: (width * 0.35).clamp(12.0, 24.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double width;
  final ThemeData theme;

  const _Placeholder({required this.width, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: width * 0.45,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
        ),
      ),
    );
  }
}