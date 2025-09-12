import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/teacher_constraint.dart';
import '../widgets/gradient_app_bar.dart';

class ConstraintsManagementScreen extends StatefulWidget {
  const ConstraintsManagementScreen({super.key});

  @override
  State<ConstraintsManagementScreen> createState() => _ConstraintsManagementScreenState();
}

class _ConstraintsManagementScreenState extends State<ConstraintsManagementScreen> {
  late DataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _dataProvider.fetchTeacherConstraints();
    _dataProvider.fetchTeachers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    return Scaffold(
      appBar: const GradientAppBar(
        title: Text('Constraints Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dataProvider.teacherConstraints.length,
              itemBuilder: (context, index) {
                final c = dataProvider.teacherConstraints[index];
                final teacher = dataProvider.teachers.firstWhere(
                  (t) => t.id == c.teacherId,
                  orElse: () => dataProvider.teachers.isNotEmpty ? dataProvider.teachers.first : (throw Exception('No teachers')),
                );
                final dayNames = ['', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì'];
                final dayName = c.dayOfWeek >= 1 && c.dayOfWeek <= 5 ? dayNames[c.dayOfWeek] : 'Giorno ${c.dayOfWeek}';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(teacher.name),
                    subtitle: Text('$dayName, Ora ${c.hourSlot}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                        await _dataProvider.deleteTeacherConstraint(c.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddConstraintDialog,
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                label: Text('Add Constraint', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddConstraintDialog() {
    final teachers = _dataProvider.teachers;
    showDialog(
      context: context,
      builder: (dialogContext) => _AddConstraintDialog(
        teachers: teachers,
        dataProvider: _dataProvider,
      ),
    );
  }
}

class _AddConstraintDialog extends StatefulWidget {
  final List<dynamic> teachers;
  final DataProvider dataProvider;

  const _AddConstraintDialog({
    required this.teachers,
    required this.dataProvider,
  });

  @override
  State<_AddConstraintDialog> createState() => _AddConstraintDialogState();
}

class _AddConstraintDialogState extends State<_AddConstraintDialog> {
  String? teacherId;
  int day = 1;
  int hour = 1;

  @override
  void initState() {
    super.initState();
    teacherId = widget.teachers.isNotEmpty ? widget.teachers.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Constraint'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: teacherId,
            items: widget.teachers
                .map<DropdownMenuItem<String>>((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) => setState(() => teacherId = v),
            decoration: const InputDecoration(labelText: 'Teacher'),
          ),
          const SizedBox(height: 8),
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
            items: const [1, 2, 3, 4, 5, 6]
                .map((h) => DropdownMenuItem(value: h, child: Text('Ora $h')))
                .toList(),
            onChanged: (v) => setState(() => hour = v ?? 1),
            decoration: const InputDecoration(labelText: 'Ora'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: teacherId == null
              ? null
              : () async {
                  final constraint = TeacherConstraint(
                    id: '',
                    teacherId: teacherId!,
                    dayOfWeek: day,
                    hourSlot: hour,
                    createdAt: DateTime.now(),
                  );
                  await widget.dataProvider.addTeacherConstraint(constraint);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}
