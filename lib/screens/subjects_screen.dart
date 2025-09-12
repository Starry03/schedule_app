import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/subject.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      body: ListView.builder(
        itemCount: dataProvider.subjects.length,
        itemBuilder: (context, index) {
          final subject = dataProvider.subjects[index];
          return ListTile(
            title: Text(subject.name),
            subtitle: Text('Weekly Hours: ${subject.weeklyHours}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editSubject(subject),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSubject(subject.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) => const AddEditSubjectDialog(),
    );
  }

  void _editSubject(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AddEditSubjectDialog(subject: subject),
    );
  }

  void _deleteSubject(String id) {
    Provider.of<DataProvider>(context, listen: false).deleteSubject(id);
  }
}

class AddEditSubjectDialog extends StatefulWidget {
  final Subject? subject;

  const AddEditSubjectDialog({super.key, this.subject});

  @override
  State<AddEditSubjectDialog> createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<AddEditSubjectDialog> {
  final _nameController = TextEditingController();
  final _weeklyHoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _weeklyHoursController.text = widget.subject!.weeklyHours.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subject == null ? 'Add Subject' : 'Edit Subject'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _weeklyHoursController,
            decoration: const InputDecoration(labelText: 'Weekly Hours'),
            keyboardType: TextInputType.number,
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
    final subject = Subject(
      id: widget.subject?.id ?? '',
      name: _nameController.text,
      weeklyHours: int.parse(_weeklyHoursController.text),
      preferConsecutive: false,
      maxConsecutiveHours: 2,
      maxDailyHours: 2,
      createdAt: widget.subject?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.subject == null) {
      dataProvider.addSubject(subject);
    } else {
      dataProvider.updateSubject(subject);
    }
    Navigator.of(context).pop();
  }
}
