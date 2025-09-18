import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/teacher.dart';
import '../models/teacher_constraint.dart';
import 'teacher_management_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchTeachers();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      body: ListView.builder(
        itemCount: dataProvider.teachers.length,
        itemBuilder: (context, index) {
          final teacher = dataProvider.teachers[index];
          return ListTile(
            title: Text(teacher.name),
            subtitle: Text(teacher.email ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTeacher(teacher),
                ),
                IconButton(
                  tooltip: 'Aggiungi vincolo obbligatorio',
                  icon: const Icon(Icons.add_box),
                  onPressed: () => _showAddMandatoryConstraintForTeacherDialog(teacher),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTeacher(teacher.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTeacher,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTeacher() {
    // Show dialog to add teacher
    showDialog(
      context: context,
      builder: (context) => const AddEditTeacherDialog(),
    );
  }

  void _editTeacher(Teacher teacher) {
    // Show dialog to edit teacher
    showDialog(
      context: context,
      builder: (context) => AddEditTeacherDialog(teacher: teacher),
    );
  }

  void _deleteTeacher(String id) {
    Provider.of<DataProvider>(context, listen: false).deleteTeacher(id);
  }

  void _showAddMandatoryConstraintForTeacherDialog(Teacher teacher) {
    int day = 1;
    int hour = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          title: const Text('Aggiungi vincolo obbligatorio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: day,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Lunedì')),
                  DropdownMenuItem(value: 2, child: Text('Martedì')),
                  DropdownMenuItem(value: 3, child: Text('Mercoledì')),
                  DropdownMenuItem(value: 4, child: Text('Giovedì')),
                  DropdownMenuItem(value: 5, child: Text('Venerdì')),
                ],
                onChanged: (v) => setState(() => day = v ?? 1),
                decoration: const InputDecoration(labelText: 'Giorno'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: hour,
                items: const [1, 2, 3, 4, 5, 6].map((h) => DropdownMenuItem(value: h, child: Text('Ora $h'))).toList(),
                onChanged: (v) => setState(() => hour = v ?? 1),
                decoration: const InputDecoration(labelText: 'Ora'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
                ElevatedButton(
              onPressed: () async {
                final dp = Provider.of<DataProvider>(context, listen: false);
                // Show a simple class picker dialog here (inline) since _ClassSelectDialog is private to another file
                final selectedClass = await showDialog<String?>(
                  context: context,
                  builder: (ctx2) {
                    final classes = dp.classes;
                    return AlertDialog(
                      title: const Text('Seleziona classe (obbligatorio)'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: classes.isEmpty
                            ? const Text('Nessuna classe disponibile')
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: classes.length,
                                itemBuilder: (context, index) {
                                  final c = classes[index];
                                  return ListTile(
                                    title: Text(c.name),
                                    subtitle: Text('Grade ${c.grade} ${c.section}'),
                                    onTap: () => Navigator.of(ctx2).pop(c.id),
                                  );
                                },
                              ),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.of(ctx2).pop(null), child: const Text('Annulla'))],
                    );
                  },
                );
                if (selectedClass == null) return;
                final constraint = TeacherConstraint(
                  id: '',
                  teacherId: teacher.id,
                  dayOfWeek: day,
                  hourSlot: hour,
                  classId: selectedClass,
                  createdAt: DateTime.now(),
                );
                final dp2 = Provider.of<DataProvider>(context, listen: false);
                await dp2.addTeacherConstraint(constraint);
                await dp2.fetchTeacherConstraints();
                if (!mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vincolo obbligatorio aggiunto')));
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditTeacherDialog extends StatefulWidget {
  final Teacher? teacher;

  const AddEditTeacherDialog({super.key, this.teacher});

  @override
  State<AddEditTeacherDialog> createState() => _AddEditTeacherDialogState();
}

class _AddEditTeacherDialogState extends State<AddEditTeacherDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _nameController.text = widget.teacher!.name;
      _emailController.text = widget.teacher!.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Add Teacher' : 'Edit Teacher'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.block),
                  label: const Text('Manage Constraints'),
                  onPressed: () {
                    if (widget.teacher == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salva il docente prima di gestire i vincoli')));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherConstraintsScreen(teacher: widget.teacher!)));
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (widget.teacher == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salva il docente prima di aggiungere vincoli')));
                    return;
                  }
                  _showAddMandatoryConstraintDialog(context, widget.teacher!, Provider.of<DataProvider>(context, listen: false));
                },
                child: const Text('Aggiungi vincolo obbl.'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showAddMandatoryConstraintDialog(BuildContext context, Teacher teacher, DataProvider dataProvider) {
    int day = 1;
    int hour = 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aggiungi vincolo obbligatorio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: day,
              items: const [
                DropdownMenuItem(value: 1, child: Text('Lunedì')),
                DropdownMenuItem(value: 2, child: Text('Martedì')),
                DropdownMenuItem(value: 3, child: Text('Mercoledì')),
                DropdownMenuItem(value: 4, child: Text('Giovedì')),
                DropdownMenuItem(value: 5, child: Text('Venerdì')),
              ],
              onChanged: (v) => day = v ?? 1,
              decoration: const InputDecoration(labelText: 'Giorno'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: hour,
              items: const [1, 2, 3, 4, 5, 6].map((h) => DropdownMenuItem(value: h, child: Text('Ora $h'))).toList(),
              onChanged: (v) => hour = v ?? 1,
              decoration: const InputDecoration(labelText: 'Ora'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              final dp = Provider.of<DataProvider>(context, listen: false);
              final selectedClass = await showDialog<String?>(
                context: context,
                builder: (ctx2) {
                  final classes = dp.classes;
                  return AlertDialog(
                    title: const Text('Seleziona classe (obbligatorio)'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: classes.isEmpty
                          ? const Text('Nessuna classe disponibile')
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: classes.length,
                              itemBuilder: (context, index) {
                                final c = classes[index];
                                return ListTile(
                                  title: Text(c.name),
                                  subtitle: Text('Grade ${c.grade} ${c.section}'),
                                  onTap: () => Navigator.of(ctx2).pop(c.id),
                                );
                              },
                            ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx2).pop(null), child: const Text('Annulla'))],
                  );
                },
              );
              if (selectedClass == null) return;
              final constraint = TeacherConstraint(
                id: '',
                teacherId: teacher.id,
                dayOfWeek: day,
                hourSlot: hour,
                classId: selectedClass,
                createdAt: DateTime.now(),
              );
              await dataProvider.addTeacherConstraint(constraint);
              if (!mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vincolo obbligatorio aggiunto')));
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  // ...existing code...

  void _save() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final teacher = Teacher(
      id: widget.teacher?.id ?? '',
      name: _nameController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      createdAt: widget.teacher?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.teacher == null) {
      dataProvider.addTeacher(teacher);
    } else {
      dataProvider.updateTeacher(teacher);
    }
    Navigator.of(context).pop();
  }
}
