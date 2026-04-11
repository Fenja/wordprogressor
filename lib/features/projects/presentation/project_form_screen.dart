import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../domain/project_model.dart';
import '../data/project_repository.dart';
import '../providers/project_providers.dart';

const _uuid = Uuid();

class ProjectFormScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const ProjectFormScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _synopsisCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _wordGoalCtrl;
  late TextEditingController _chapterCtrl;
  late TextEditingController _tagInputCtrl;

  String _genre = kGenres.first;
  String _language = 'Deutsch';
  ProjectStatus _status = ProjectStatus.draft;
  DateTime _startedAt = DateTime.now();
  DateTime? _deadline;
  List<String> _tags = [];
  bool _isLoading = false;
  ProjectModel? _existing;

  bool get _isEdit => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _synopsisCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _wordGoalCtrl = TextEditingController(text: '80000');
    _chapterCtrl = TextEditingController(text: '0');
    _tagInputCtrl = TextEditingController();

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProject());
    }
  }

  Future<void> _loadProject() async {
    final project =
        await ref.read(projectRepositoryProvider).getProject(widget.projectId!);
    if (project == null || !mounted) return;
    setState(() {
      _existing = project;
      _titleCtrl.text = project.title;
      _synopsisCtrl.text = project.synopsis ?? '';
      _notesCtrl.text = project.notes ?? '';
      _wordGoalCtrl.text = project.wordCountGoal.toString();
      _chapterCtrl.text = project.chapterCountTotal.toString();
      _genre = project.genre;
      _language = project.language;
      _status = project.status;
      _startedAt = project.startedAt;
      _deadline = project.deadline;
      _tags = List.from(project.tags);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _notesCtrl.dispose();
    _wordGoalCtrl.dispose();
    _chapterCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final repo = ref.read(projectRepositoryProvider);
    final now = DateTime.now();

    final model = ProjectModel(
      id: _existing?.id ?? _uuid.v4(),
      title: _titleCtrl.text.trim(),
      genre: _genre,
      status: _status,
      synopsis:
          _synopsisCtrl.text.trim().isEmpty ? null : _synopsisCtrl.text.trim(),
      tags: _tags,
      wordCountGoal: int.tryParse(_wordGoalCtrl.text) ?? 0,
      wordCountCurrent: _existing?.wordCountCurrent ?? 0,
      chapterCountTotal: int.tryParse(_chapterCtrl.text) ?? 0,
      chapterCountDone: _existing?.chapterCountDone ?? 0,
      language: _language,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      deadline: _deadline,
      startedAt: _startedAt,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEdit) {
        await repo.updateProject(model);
      } else {
        await repo.createProject(model);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Projekt bearbeiten' : 'Neues Projekt'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            _Section(label: 'Grunddaten', children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  hintText: 'z.B. Das Schweigen des Mondes',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Titel ist erforderlich' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _genre,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: kGenres
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _genre = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProjectStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ProjectStatus.values
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _synopsisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Synopsis',
                  hintText: 'Kurze Zusammenfassung des Projekts',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
            ]),
            _Section(label: 'Fortschrift & Ziele', children: [
              TextFormField(
                controller: _wordGoalCtrl,
                decoration: const InputDecoration(
                    labelText: 'Wortanzahl-Ziel', suffixText: 'Wörter'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chapterCtrl,
                decoration: const InputDecoration(
                    labelText: 'Kapitelanzahl (geplant)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _DatePicker(
                label: 'Begonnen am',
                date: _startedAt,
                onChanged: (d) => setState(() => _startedAt = d),
              ),
            ]),
            _Section(label: 'Deadline', children: [
              _DeadlinePicker(
                deadline: _deadline,
                onChanged: (d) => setState(() => _deadline = d),
                onClear: () => setState(() => _deadline = null),
              ),
            ]),
            _Section(label: 'Tags', children: [
              _TagInput(
                tags: _tags,
                controller: _tagInputCtrl,
                onAdd: (tag) => setState(() {
                  if (!_tags.contains(tag)) _tags.add(tag);
                }),
                onRemove: (tag) => setState(() => _tags.remove(tag)),
              ),
            ]),
            _Section(label: 'Notizen', children: [
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notizen',
                  hintText: 'Recherche, Ideen, Fragen…',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Form Section Widget ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 10),
          ...children,
          const SizedBox(height: 4),
          const Divider(),
        ],
      ),
    );
  }
}

// ── Date Picker ──────────────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DatePicker(
      {required this.label, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateFormat('dd. MMMM yyyy', 'de').format(date)),
      ),
    );
  }
}

// ── Deadline Picker ──────────────────────────────────────────────────────

class _DeadlinePicker extends StatelessWidget {
  final DateTime? deadline;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;
  const _DeadlinePicker(
      {required this.deadline,
      required this.onChanged,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                helpText: 'Deadline wählen',
              );
              if (picked != null) onChanged(picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Deadline'),
              child: Text(
                deadline != null
                    ? DateFormat('dd. MMMM yyyy', 'de').format(deadline!)
                    : 'Keine Deadline gesetzt',
                style: TextStyle(
                  color: deadline != null
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (deadline != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded),
            tooltip: 'Deadline entfernen',
          ),
        ],
      ],
    );
  }
}

// ── Tag Input ────────────────────────────────────────────────────────────

class _TagInput extends StatelessWidget {
  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  const _TagInput(
      {required this.tags,
      required this.controller,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Tag hinzufügen…',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                onSubmitted: (v) {
                  final tag = v.trim();
                  if (tag.isNotEmpty) {
                    onAdd(tag);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty) {
                  onAdd(tag);
                  controller.clear();
                }
              },
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Tag hinzufügen',
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map((t) => Chip(
                      label: Text(t),
                      labelStyle: const TextStyle(fontSize: 12),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => onRemove(t),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
