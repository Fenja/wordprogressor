import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/cover_image_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/project_repository.dart';

/// Compact cover image picker used inside the project form.
///
/// FIX: The upload now completes BEFORE calling onRemoteUrlChanged, and
/// if the project already exists in the DB, the coverRemoteUrl is written
/// directly via the repository — not only held in form state. This ensures
/// the URL is persisted even if the user navigates away before hitting Save.
class CoverImagePicker extends ConsumerStatefulWidget {
  final String projectId;
  final Uint8List? initialBytes;
  final String? initialLocalPath;
  final String? initialRemoteUrl;
  final void Function(String? localPath) onLocalPathChanged;
  final void Function(Uint8List? bytes) onBytesChanged;
  final void Function(String? remoteUrl) onRemoteUrlChanged;

  const CoverImagePicker({
    super.key,
    required this.projectId,
    this.initialBytes,
    this.initialLocalPath,
    this.initialRemoteUrl,
    required this.onLocalPathChanged,
    required this.onBytesChanged,
    required this.onRemoteUrlChanged,
  });

  @override
  ConsumerState<CoverImagePicker> createState() => _CoverImagePickerState();
}

class _CoverImagePickerState extends ConsumerState<CoverImagePicker> {
  String? _localPath;
  String? _remoteUrl;
  Uint8List? _webBytes;
  bool _uploading = false;
  double _uploadProgress = 0;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _webBytes = widget.initialBytes;
    _localPath = widget.initialLocalPath;
    _remoteUrl = widget.initialRemoteUrl;
  }

  bool get _hasCover =>
      _localPath != null || _webBytes != null || _remoteUrl != null;

  // ── Pick ───────────────────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    final service = ref.read(coverImageServiceProvider);
    final file = source == ImageSource.gallery
        ? await service.pickFromGallery()
        : await service.pickFromCamera();

    if (file == null || !mounted) return;

    setState(() {
      _uploadError = null;
      _uploading = false;
      _uploadProgress = 0;
    });

    if (kIsWeb) {
      // Web: read bytes for local preview
      final bytes = await file.readAsBytes();
      setState(() {
        _webBytes = bytes;
        _localPath = null;
        // Keep old remoteUrl visible until new upload completes
      });
      widget.onBytesChanged(bytes);
      widget.onLocalPathChanged(null);
    } else {
      // Native: save local copy for immediate display
      final localPath = await service.saveLocally(file, widget.projectId);
      setState(() {
        _localPath = localPath;
        _webBytes = null;
      });
      widget.onLocalPathChanged(localPath);
    }

    // Upload to Firebase Storage (if user is logged in)
    await _upload(file);
  }

  Future<void> _upload(XFile file) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // Not logged in — local path already notified, no remote URL
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _uploadError = null;
    });

    try {
      final url = await ref.read(coverImageServiceProvider).uploadToStorage(
        file: file,
        projectId: widget.projectId,
        userId: user.uid,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (!mounted) return;

      if (url != null) {
        setState(() => _remoteUrl = url);

        // Notify parent form so it's included in the next Save
        widget.onRemoteUrlChanged(url);

        // CRITICAL FIX: Also write the remoteUrl directly to the DB now.
        // The form may not be saved immediately, but the URL must be
        // persisted before it is lost (e.g. user navigates away).
        final existing = await ref
            .read(projectRepositoryProvider)
            .getProject(widget.projectId);
        if (existing != null) {
          await ref.read(projectRepositoryProvider).updateProject(
            existing.copyWith(
              coverRemoteUrl: url,
              coverLocalPath: _localPath ?? existing.coverLocalPath,
            ),
          );
        }
      } else {
        setState(() => _uploadError = 'Upload fehlgeschlagen');
      }
    } catch (e) {
      if (mounted) setState(() => _uploadError = 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    final service = ref.read(coverImageServiceProvider);
    await service.deleteLocal(widget.projectId);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      await service.deleteFromStorage(widget.projectId, user.uid);
    }

    // Clear from DB immediately
    final existing = await ref
        .read(projectRepositoryProvider)
        .getProject(widget.projectId);
    if (existing != null) {
      await ref.read(projectRepositoryProvider).updateProject(
        existing.copyWith(coverLocalPath: null, coverRemoteUrl: null),
      );
    }

    setState(() {
      _localPath = null;
      _webBytes  = null;
      _remoteUrl = null;
    });
    widget.onLocalPathChanged(null);
    widget.onBytesChanged(null);
    widget.onRemoteUrlChanged(null);
  }

  // ── Source picker sheet ────────────────────────────────────────────────────

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Aus Galerie wählen'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Foto aufnehmen'),
                  onTap: () {
                    Navigator.pop(context);
                    _pick(ImageSource.camera);
                  },
                ),
              if (_hasCover)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(
                    'Coverbild entfernen',
                    style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _delete();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showPickSheet,
          child: Container(
            width: 120,
            height: 168, // ~book cover ratio
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 0.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildPreview(theme),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: _buildStatus(theme),
        ),
      ],
    );
  }

  Widget _buildStatus(ThemeData theme) {
    if (_uploading) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LinearProgressIndicator(value: _uploadProgress),
        const SizedBox(height: 4),
        Text(
          'Wird hochgeladen (${(_uploadProgress * 100).round()}%)…',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ]);
    }
    if (_uploadError != null) {
      return Row(children: [
        Icon(Icons.warning_amber_rounded,
            size: 12, color: theme.colorScheme.error),
        const SizedBox(width: 4),
        Expanded(
          child: Text(_uploadError!,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ),
      ]);
    }
    if (_remoteUrl != null) {
      return Row(children: [
        Icon(Icons.cloud_done_outlined,
            size: 12, color: Colors.green.shade600),
        const SizedBox(width: 4),
        Text('Gespeichert',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: Colors.green.shade600)),
      ]);
    }
    return Text(
      _hasCover ? 'Tippen zum Ändern' : 'Coverbild hinzufügen',
      style: theme.textTheme.labelSmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPreview(ThemeData theme) {
    // Web: in-memory bytes
    if (_webBytes != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.memory(_webBytes!, fit: BoxFit.cover),
        _EditOverlay(),
      ]);
    }
    // Native: local file
    if (_localPath != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.file(File(_localPath!), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              // Local file missing — fall through to remote
              if (_remoteUrl != null) return _buildRemotePreview(theme);
              return _Placeholder(theme: theme);
            }),
        _EditOverlay(),
      ]);
    }
    // Remote URL
    if (_remoteUrl != null) {
      return Stack(fit: StackFit.expand, children: [
        _buildRemotePreview(theme),
        _EditOverlay(),
      ]);
    }
    return _Placeholder(theme: theme);
  }

  Widget _buildRemotePreview(ThemeData theme) {
    return Image.network(
      _remoteUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))),
        );
      },
      errorBuilder: (_, __, ___) => _Placeholder(theme: theme),
    );
  }
}

class _EditOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
          ),
        ),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ThemeData theme;
  const _Placeholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
        const SizedBox(height: 6),
        Text('Cover\nhinzufügen',
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            textAlign: TextAlign.center),
      ],
    );
  }
}