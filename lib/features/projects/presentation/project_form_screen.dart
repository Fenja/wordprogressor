import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Controllers
  late TextEditingController _titleCtrl;
  late TextEditingController _synopsisCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _wordGoalCtrl;
  late TextEditingController _wordCurrentCtrl;   // ← new
  late TextEditingController _chapterTotalCtrl;
  late TextEditingController _chapterDoneCtrl;   // ← new
  late TextEditingController _tagInputCtrl;

  // State
  String _genre = kGenres.first;
  String _language = 'Deutsch';
  ProjectStatus _status = ProjectStatus.draft;
  DateTime _startedAt = DateTime.now();
  DateTime? _deadline;
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isLoadingProject = false;
  ProjectModel? _existing;

  bool get _isEdit => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl       = TextEditingController();
    _synopsisCtrl    = TextEditingController();
    _notesCtrl       = TextEditingController();
    _wordGoalCtrl    = TextEditingController(text: '80000');
    _wordCurrentCtrl = TextEditingController(text: '0');
    _chapterTotalCtrl = TextEditingController(text: '0');
    _chapterDoneCtrl = TextEditingController(text: '0');
    _tagInputCtrl    = TextEditingController();

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProject());
    }
  }

  Future<void> _loadProject() async {
    setState(() => _isLoadingProject = true);
    final project = await ref
        .read(projectRepositoryProvider)
        .getProject(widget.projectId!);
    if (project == null || !mounted) return;
    setState(() {
      _existing            = project;
      _titleCtrl.text      = project.title;
      _synopsisCtrl.text   = project.synopsis ?? '';
      _notesCtrl.text      = project.notes ?? '';
      _wordGoalCtrl.text   = project.wordCountGoal.toString();
      _wordCurrentCtrl.text = project.wordCountCurrent.toString();
      _chapterTotalCtrl.text = project.chapterCountTotal.toString();
      _chapterDoneCtrl.text  = project.chapterCountDone.toString();
      _genre               = project.genre;
      _language            = project.language;
      _status              = project.status;
      _startedAt           = project.startedAt;
      _deadline            = project.deadline;
      _tags                = List.from(project.tags);
      _isLoadingProject    = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _notesCtrl.dispose();
    _wordGoalCtrl.dispose();
    _wordCurrentCtrl.dispose();
    _chapterTotalCtrl.dispose();
    _chapterDoneCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final repo = ref.read(projectRepositoryProvider);
    final now  = DateTime.now();

    final wordGoal    = int.tryParse(_wordGoalCtrl.text) ?? 0;
    final wordCurrent = int.tryParse(_wordCurrentCtrl.text) ?? 0;
    final chapTotal   = int.tryParse(_chapterTotalCtrl.text) ?? 0;
    final chapDone    = int.tryParse(_chapterDoneCtrl.text) ?? 0;

    final model = ProjectModel(
      id:               _existing?.id ?? _uuid.v4(),
      title:            _titleCtrl.text.trim(),
      genre:            _genre,
      status:           _status,
      synopsis:         _synopsisCtrl.text.trim().isEmpty
          ? null : _synopsisCtrl.text.trim(),
      tags:             _tags,
      wordCountGoal:    wordGoal,
      wordCountCurrent: wordCurrent,
      chapterCountTotal: chapTotal,
      chapterCountDone:  chapDone.clamp(0, chapTotal > 0 ? chapTotal : chapDone),
      language:         _language,
      notes:            _notesCtrl.text.trim().isEmpty
          ? null : _notesCtrl.text.trim(),
      deadline:         _deadline,
      startedAt:        _startedAt,
      createdAt:        _existing?.createdAt ?? now,
      updatedAt:        now,
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProject) {
      return Scaffold(
        appBar: AppBar(
            title: Text(_isEdit ? 'Projekt bearbeiten' : 'Neues Projekt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Projekt bearbeiten' : 'Neues Projekt'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
            // ── Grunddaten ────────────────────────────────────────────────
            _Section(label: 'Grunddaten', children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  hintText: 'z.B. Das Schweigen des Mondes',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Titel ist erforderlich' : null,
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
                  hintText: 'Kurze Zusammenfassung',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
            ]),

            // ── Ziele ─────────────────────────────────────────────────────
            _Section(label: 'Ziele', children: [
              TextFormField(
                controller: _wordGoalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Wortanzahl-Ziel',
                  suffixText: 'Wörter',
                  helperText: 'Angestrebte Gesamtwortzahl',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n != null && n >= 0) ? null : 'Bitte eine Zahl eingeben';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chapterTotalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kapitel geplant',
                  helperText: 'Geplante Gesamtanzahl der Kapitel',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ]),

            // ── Aktueller Fortschritt (nur im Edit-Modus) ────────────────
            if (_isEdit)
              _Section(
                label: 'Aktueller Fortschritt',
                children: [
                  // Word count current with progress preview
                  _WordProgressField(
                    currentCtrl: _wordCurrentCtrl,
                    goalCtrl: _wordGoalCtrl,
                  ),
                  const SizedBox(height: 12),

                  // Chapter done with validation against total
                  _ChapterProgressField(
                    doneCtrl: _chapterDoneCtrl,
                    totalCtrl: _chapterTotalCtrl,
                  ),

                  // Info note
                  const SizedBox(height: 8),
                  _InfoNote(
                    text: 'Hier kannst du den Fortschritt direkt eintragen. '
                        'Für tägliche Sitzungen nutze den '
                        '„Schreibsitzung"-Button in der Detailansicht.',
                  ),
                ],
              ),

            // ── Deadline & Datum ──────────────────────────────────────────
            _Section(label: 'Deadline', children: [
              _DeadlinePicker(
                deadline: _deadline,
                onChanged: (d) => setState(() => _deadline = d),
                onClear: () => setState(() => _deadline = null),
              ),
              const SizedBox(height: 12),
              _DatePicker(
                label: 'Begonnen am',
                date: _startedAt,
                onChanged: (d) => setState(() => _startedAt = d),
              ),
            ]),

            // ── Tags ──────────────────────────────────────────────────────
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

            // ── Notizen ───────────────────────────────────────────────────
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

// ── Word Progress Field ───────────────────────────────────────────────────────

/// Shows the current word count field with a live progress bar beneath it.
class _WordProgressField extends StatefulWidget {
  final TextEditingController currentCtrl;
  final TextEditingController goalCtrl;

  const _WordProgressField({
    required this.currentCtrl,
    required this.goalCtrl,
  });

  @override
  State<_WordProgressField> createState() => _WordProgressFieldState();
}

class _WordProgressFieldState extends State<_WordProgressField> {
  late int _current;
  late int _goal;

  @override
  void initState() {
    super.initState();
    _current = int.tryParse(widget.currentCtrl.text) ?? 0;
    _goal    = int.tryParse(widget.goalCtrl.text) ?? 0;
    widget.currentCtrl.addListener(_update);
    widget.goalCtrl.addListener(_update);
  }

  void _update() {
    if (!mounted) return;
    setState(() {
      _current = int.tryParse(widget.currentCtrl.text) ?? 0;
      _goal    = int.tryParse(widget.goalCtrl.text) ?? 0;
    });
  }

  @override
  void dispose() {
    widget.currentCtrl.removeListener(_update);
    widget.goalCtrl.removeListener(_update);
    super.dispose();
  }

  double get _pct => (_goal > 0)
      ? (_current / _goal).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct   = (_pct * 100).round();
    final fmt   = NumberFormat('#,###', 'de');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.currentCtrl,
          decoration: InputDecoration(
            labelText: 'Aktuelle Wortanzahl',
            suffixText: 'Wörter',
            helperText: _goal > 0
                ? '$pct % des Ziels (${fmt.format(_goal)} Wörter)'
                : null,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return (n != null && n >= 0) ? null : 'Bitte eine Zahl eingeben';
          },
        ),
        if (_goal > 0) ...[
          const SizedBox(height: 8),
          Semantics(
            label: 'Fortschritt: $pct Prozent',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _pct,
                minHeight: 5,
                backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _pct >= 1.0
                      ? Colors.green.shade600
                      : _pct >= 0.5
                      ? theme.colorScheme.primary
                      : Colors.orange.shade600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Chapter Progress Field ────────────────────────────────────────────────────

/// Shows done/total chapter fields side-by-side with inline validation.
class _ChapterProgressField extends StatefulWidget {
  final TextEditingController doneCtrl;
  final TextEditingController totalCtrl;

  const _ChapterProgressField({
    required this.doneCtrl,
    required this.totalCtrl,
  });

  @override
  State<_ChapterProgressField> createState() => _ChapterProgressFieldState();
}

class _ChapterProgressFieldState extends State<_ChapterProgressField> {
  @override
  void initState() {
    super.initState();
    widget.doneCtrl.addListener(_rebuild);
    widget.totalCtrl.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    widget.doneCtrl.removeListener(_rebuild);
    widget.totalCtrl.removeListener(_rebuild);
    super.dispose();
  }

  int get _done  => int.tryParse(widget.doneCtrl.text) ?? 0;
  int get _total => int.tryParse(widget.totalCtrl.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overLimit = _total > 0 && _done > _total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.doneCtrl,
                decoration: InputDecoration(
                  labelText: 'Fertige Kapitel',
                  errorText: overLimit
                      ? 'Mehr als Gesamtanzahl'
                      : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Ungültig';
                  if (_total > 0 && n > _total) {
                    return 'Max. $_total';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
              child: Text(
                'von',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: widget.totalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kapitel gesamt',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        if (_total > 0 && !overLimit) ...[
          const SizedBox(height: 8),
          Semantics(
            label: '$_done von $_total Kapiteln fertig',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _done / _total,
                minHeight: 5,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_done / $_total Kapitel',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

// ── Info Note ─────────────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form Section ──────────────────────────────────────────────────────────────

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
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
          const SizedBox(height: 4),
          const Divider(),
        ],
      ),
    );
  }
}

// ── Date Picker ───────────────────────────────────────────────────────────────

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

// ── Deadline Picker ───────────────────────────────────────────────────────────

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
                initialDate: deadline ??
                    DateTime.now().add(const Duration(days: 30)),
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

// ── Tag Input ─────────────────────────────────────────────────────────────────

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
              materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
            ))
                .toList(),
          ),
        ],
      ],
    );
  }
}