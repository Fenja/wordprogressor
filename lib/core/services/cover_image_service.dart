import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Result of a cover image pick + save operation.
class CoverImageResult {
  /// Local file path (always set after a successful pick on native).
  final String? localPath;

  /// Raw bytes (used on web where file paths don't exist).
  final Uint8List? bytes;

  /// Firebase Storage download URL (set after successful upload).
  final String? remoteUrl;

  const CoverImageResult({this.localPath, this.bytes, this.remoteUrl});

  bool get hasImage => localPath != null || bytes != null || remoteUrl != null;
}

/// Manages cover image lifecycle:
///   1. Pick from gallery or camera via image_picker.
///   2. Save a local copy in the app's documents directory (native only).
///   3. Optionally upload to Firebase Storage and return the download URL.
class CoverImageService {
  final ImagePicker _picker;
  final FirebaseStorage? _storage;

  CoverImageService({
    ImagePicker? picker,
    FirebaseStorage? storage,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage;

  // ── Pick ──────────────────────────────────────────────────────────────────

  /// Opens the image picker and returns the picked file.
  /// Returns null if the user cancels.
  Future<XFile?> pickFromGallery() => _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 1200,
    imageQuality: 85,
  );

  Future<XFile?> pickFromCamera() => _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 800,
    maxHeight: 1200,
    imageQuality: 85,
  );

  // ── Save locally ──────────────────────────────────────────────────────────

  /// Copies [file] into the app's documents directory under
  /// `covers/<projectId>.jpg` and returns the absolute path.
  ///
  /// On web, returns null — use [file.readAsBytes()] instead.
  Future<String?> saveLocally(XFile file, String projectId) async {
    if (kIsWeb) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docsDir.path, 'covers'));
    if (!coversDir.existsSync()) {
      coversDir.createSync(recursive: true);
    }

    final ext = p.extension(file.path).toLowerCase();
    final destPath = p.join(coversDir.path, '$projectId$ext');
    await File(file.path).copy(destPath);
    return destPath;
  }

  /// Deletes the local cover file for [projectId] if it exists.
  Future<void> deleteLocal(String projectId) async {
    if (kIsWeb) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = p.join(docsDir.path, 'covers');
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
      final file = File(p.join(coversDir, '$projectId$ext'));
      if (file.existsSync()) file.deleteSync();
    }
  }

  // ── Upload to Firebase Storage ────────────────────────────────────────────

  /// Uploads [file] to `covers/{uid}/{projectId}.jpg` in Firebase Storage.
  /// Returns the public download URL on success, null on failure.
  ///
  /// Requires Firebase Storage to be enabled in the Firebase Console.
  Future<String?> uploadToStorage({
    required XFile file,
    required String projectId,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final storage = _storage ?? FirebaseStorage.instance;
      final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
      final ref = storage.ref('covers/$userId/$projectId$ext');

      final UploadTask task;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        task = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        task = ref.putFile(File(file.path));
      }

      // Report progress
      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('CoverImageService.uploadToStorage failed: $e');
      return null;
    }
  }

  /// Deletes the cover from Firebase Storage.
  Future<void> deleteFromStorage(String projectId, String userId) async {
    try {
      final storage = _storage ?? FirebaseStorage.instance;
      for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
        try {
          await storage.ref('covers/$userId/$projectId$ext').delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('CoverImageService.deleteFromStorage failed: $e');
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final coverImageServiceProvider = Provider<CoverImageService>(
      (ref) => CoverImageService(),
);