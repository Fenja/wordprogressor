import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/project_repository.dart';
import '../../../achievements/domain/achievement_model.dart';
import '../../../achievements/presentation/widgets/achievement_toast.dart';

class LogSessionSheet extends ConsumerStatefulWidget {
  final String projectId;
  const LogSessionSheet({super.key, required this.projectId});

  @override
  ConsumerState<LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends ConsumerState<LogSessionSheet> {
  final _wordsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _wordsCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final words = int.tryParse(_wordsCtrl.text);
    if (words == null || words <= 0) return;

    setState(() => _saving = true);
    try {
      final newlyUnlocked = await ref.read(projectRepositoryProvider).logSession(
            projectId: widget.projectId,
            wordsWritten: words,
            durationMinutes: int.tryParse(_durationCtrl.text) ?? 0,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        // Show achievement toasts after sheet closes
        if (newlyUnlocked.isNotEmpty && context.mounted) {
          // Stagger toasts 600ms apart so they don't overlap
          for (var i = 0; i < newlyUnlocked.length; i++) {
            final def = newlyUnlocked[i] as AchievementDef;
            Future.delayed(Duration(milliseconds: 600 * i), () {
              if (context.mounted) AchievementToast.show(context, def);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schreibsitzung erfassen',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _wordsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Geschriebene Wörter *',
                        suffixText: 'Wörter',
                      ),
                      keyboardType: TextInputType.number,
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dauer',
                        suffixText: 'Min.',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notiz zur Sitzung',
                  hintText: 'Was hast du heute geschrieben?',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
