import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/class_model.dart';
import '../models/teacher_subject.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  late DataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _dataProvider.fetchClasses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final divider = Theme.of(context).dividerColor;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Classes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: onSurface),
                  onPressed: _showAddClassDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dataProvider.classes.length,
              itemBuilder: (context, index) {
                final classModel = dataProvider.classes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        classModel.grade.toString(),
                        style: TextStyle(color: onSurface),
                      ),
                    ),
                    title: Text(classModel.name),
                    subtitle: Text('Grade ${classModel.grade} - Section ${classModel.section}'),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'subjects',
                          child: Row(
                            children: [
                              Icon(Icons.book),
                              SizedBox(width: 8),
                              Text('Assign Subjects'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditClassDialog(classModel);
                            break;
                          case 'subjects':
                            _showSubjectAssignmentDialog(classModel);
                            break;
                          case 'delete':
                            _confirmDelete(classModel);
                            break;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditClassDialog(),
    );
  }

  void _showEditClassDialog(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => AddEditClassDialog(classModel: classModel),
    );
  }

  void _showSubjectAssignmentDialog(ClassModel classModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectAssignmentScreen(classModel: classModel),
      ),
    );
  }

  void _confirmDelete(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete ${classModel.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteClass(classModel.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddEditClassDialog extends StatefulWidget {
  final ClassModel? classModel;

  const AddEditClassDialog({super.key, this.classModel});

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
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
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a class name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a grade';
                }
                final grade = int.tryParse(value);
                if (grade == null || grade < 1 || grade > 12) {
                  return 'Please enter a valid grade (1-12)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sectionController,
              decoration: const InputDecoration(
                labelText: 'Section',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a section';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

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

    Navigator.pop(context);
  }
}

class SubjectAssignmentScreen extends StatefulWidget {
  final ClassModel classModel;

  const SubjectAssignmentScreen({super.key, required this.classModel});

  @override
  State<SubjectAssignmentScreen> createState() => _SubjectAssignmentScreenState();
}

class _SubjectAssignmentScreenState extends State<SubjectAssignmentScreen> {
  @override
  void initState() {
    super.initState();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.fetchSubjects();
    dataProvider.fetchTeachers();
    dataProvider.fetchTeacherSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    final divider = Theme.of(context).dividerColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    // Filter teacher subjects for this specific class
    final classTeacherSubjects = dataProvider.teacherSubjects
        .where((ts) => ts.classId == widget.classModel.id)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.classModel.name} - Subject Assignment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: onSurface),
                  onPressed: _showAssignSubjectDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: classTeacherSubjects.length,
              itemBuilder: (context, index) {
                final teacherSubject = classTeacherSubjects[index];

                String teacherName = 'Unknown Teacher';
                String subjectName = 'Unknown Subject';

                try {
                  final teacher = dataProvider.teachers.firstWhere(
                    (t) => t.id == teacherSubject.teacherId,
                  );
                  teacherName = teacher.name;
                } catch (e) {}

                try {
                  final subject = dataProvider.subjects.firstWhere(
                    (s) => s.id == teacherSubject.subjectId,
                  );
                  subjectName = subject.name;
                } catch (e) {}

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(subjectName),
                    subtitle: Text('Teacher: $teacherName'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmUnassign(teacherSubject),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AssignSubjectDialog(classModel: widget.classModel),
    );
  }

  void _confirmUnassign(teacherSubject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Subject'),
        content: const Text('Are you sure you want to unassign this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false)
                  .deleteTeacherSubject(teacherSubject.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
  }
}

class AssignSubjectDialog extends StatefulWidget {
  final ClassModel classModel;

  const AssignSubjectDialog({super.key, required this.classModel});

  @override
  State<AssignSubjectDialog> createState() => _AssignSubjectDialogState();
}

class _AssignSubjectDialogState extends State<AssignSubjectDialog> {
  String? selectedSubjectId;
  String? selectedTeacherId;

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return AlertDialog(
      title: const Text('Assign Subject'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            value: selectedSubjectId,
            items: dataProvider.subjects.map((subject) {
              return DropdownMenuItem(
                value: subject.id,
                child: Text(subject.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSubjectId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Teacher',
              border: OutlineInputBorder(),
            ),
            value: selectedTeacherId,
            items: dataProvider.teachers.map((teacher) {
              return DropdownMenuItem(
                value: teacher.id,
                child: Text(teacher.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTeacherId = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedSubjectId != null && selectedTeacherId != null
              ? _assign
              : null,
          child: const Text('Assign'),
        ),
      ],
    );
  }

  void _assign() async {
    if (selectedSubjectId == null || selectedTeacherId == null) return;

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      // Create new teacher subject assignment
      final teacherSubjectModel = TeacherSubject(
        id: '',
        teacherId: selectedTeacherId!,
        subjectId: selectedSubjectId!,
        classId: widget.classModel.id,
        createdAt: DateTime.now(),
      );

      await dataProvider.addTeacherSubject(teacherSubjectModel);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject assigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning subject: $e')),
        );
      }
    }
  }
}
