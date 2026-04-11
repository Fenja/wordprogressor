import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';

const _uuid = Uuid();

class MilestonesScreen extends ConsumerWidget {
  final String projectId;
  const MilestonesScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final milestonesStream = db.watchMilestonesForProject(projectId);

    return Scaffold(
      appBar: AppBar(title: const Text('Meilensteine')),
      body: StreamBuilder(
        stream: milestonesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final milestones = snapshot.data ?? [];
          if (milestones.isEmpty) {
            return _EmptyMilestones(
              onAdd: () => _showAddSheet(context, ref, projectId),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: milestones.length,
            onReorder: (oldIdx, newIdx) async {
              if (newIdx > oldIdx) newIdx--;
              // Update sort orders
              final reordered = List.from(milestones);
              final moved = reordered.removeAt(oldIdx);
              reordered.insert(newIdx, moved);
              for (var i = 0; i < reordered.length; i++) {
                final m = reordered[i] as Milestone;
                await db.upsertMilestone(MilestonesCompanion(
                  id: Value(m.id),
                  projectId: Value(m.projectId),
                  title: Value(m.title),
                  dueDate: Value(m.dueDate),
                  sortOrder: Value(i),
                  createdAt: Value(m.createdAt),
                  updatedAt: Value(DateTime.now()),
                ));
              }
            },
            itemBuilder: (context, i) {
              final m = milestones[i];
              return _MilestoneRow(
                key: ValueKey(m.id),
                milestone: m,
                onToggle: () => db.toggleMilestone(m.id, !m.isCompleted),
                onDelete: () => db.deleteMilestone(m.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, projectId),
        icon: const Icon(Icons.flag_rounded),
        label: const Text('Meilenstein'),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MilestoneFormSheet(projectId: projectId),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MilestoneRow({
    super.key,
    required this.milestone,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd. MMM yyyy', 'de');
    final isOverdue =
        !milestone.isCompleted && milestone.dueDate.isBefore(DateTime.now());

    return Semantics(
      label:
          '${milestone.title}, ${milestone.isCompleted ? 'erledigt' : 'offen'}, fällig am ${fmt.format(milestone.dueDate)}',
      child: ListTile(
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: milestone.isCompleted
                  ? Colors.green.shade600
                  : Colors.transparent,
              border: Border.all(
                color: milestone.isCompleted
                    ? Colors.green.shade600
                    : isOverdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: milestone.isCompleted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          milestone.title,
          style: TextStyle(
            decoration:
                milestone.isCompleted ? TextDecoration.lineThrough : null,
            color: milestone.isCompleted
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        subtitle: Text(
          fmt.format(milestone.dueDate),
          style: TextStyle(
            fontSize: 12,
            color: isOverdue
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOverdue)
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: theme.colorScheme.error),
            ReorderableDragStartListener(
              index: 0,
              child: const Icon(Icons.drag_handle_rounded),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: onDelete,
              tooltip: 'Meilenstein löschen',
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneFormSheet extends ConsumerStatefulWidget {
  final String projectId;
  const _MilestoneFormSheet({required this.projectId});

  @override
  ConsumerState<_MilestoneFormSheet> createState() =>
      _MilestoneFormSheetState();
}

class _MilestoneFormSheetState extends ConsumerState<_MilestoneFormSheet> {
  final _titleCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    await db.upsertMilestone(MilestonesCompanion.insert(
      id: _uuid.v4(),
      projectId: widget.projectId,
      title: _titleCtrl.text.trim(),
      dueDate: _dueDate,
      createdAt: now,
      updatedAt: now,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Neuer Meilenstein',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titel *'),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    helpText: 'Fälligkeitsdatum',
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fällig am'),
                  child: Text(DateFormat('dd. MMMM yyyy', 'de').format(_dueDate)),
                ),
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
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: const Text('Hinzufügen'),
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

class _EmptyMilestones extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyMilestones({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Noch keine Meilensteine',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Teile dein Projekt in überschaubare Schritte auf.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Meilenstein hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
