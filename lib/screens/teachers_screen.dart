import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/teacher.dart';

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
