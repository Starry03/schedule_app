import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/class_model.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchClasses();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: dataProvider.classes.length,
          itemBuilder: (context, index) {
            final classModel = dataProvider.classes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  classModel.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Grade: ${classModel.grade}, Section: ${classModel.section}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editClass(classModel),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteClass(classModel.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClass,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addClass() {
    showDialog(
      context: context,
      builder: (context) => const AddEditClassDialog(),
    );
  }

  void _editClass(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => AddEditClassDialog(classModel: classModel),
    );
  }

  void _deleteClass(String id) {
    Provider.of<DataProvider>(context, listen: false).deleteClass(id);
  }
}

class AddEditClassDialog extends StatefulWidget {
  final ClassModel? classModel;

  const AddEditClassDialog({super.key, this.classModel});

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.classModel != null) {
      _nameController.text = widget.classModel!.name;
      _gradeController.text = widget.classModel!.grade.toString();
      _sectionController.text = widget.classModel!.section;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classModel == null ? 'Add Class' : 'Edit Class'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _gradeController,
            decoration: const InputDecoration(labelText: 'Grade'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _sectionController,
            decoration: const InputDecoration(labelText: 'Section'),
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
    final classModel = ClassModel(
      id: widget.classModel?.id ?? '',
      name: _nameController.text,
      grade: int.parse(_gradeController.text),
      section: _sectionController.text,
      createdAt: widget.classModel?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.classModel == null) {
      dataProvider.addClass(classModel);
    } else {
      dataProvider.updateClass(classModel);
    }
    Navigator.of(context).pop();
  }
}
