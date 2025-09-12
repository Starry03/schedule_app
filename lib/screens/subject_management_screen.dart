import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/subject.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  late DataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _dataProvider.fetchSubjects();
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
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subjects', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: () => _showAddSubjectDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: ListView.builder(
              itemCount: dataProvider.subjects.length,
              itemBuilder: (context, index) {
                final subject = dataProvider.subjects[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  subject.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subject.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Weekly: ${subject.weeklyHours} • Max daily: ${subject.maxDailyHours}', style: Theme.of(context).textTheme.bodySmall),
                                  if (subject.preferConsecutive)
                                    Text('Prefers consecutive', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Row(children: const [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Theme.of(context).colorScheme.error), const SizedBox(width: 8), Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error))])),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showEditSubjectDialog(subject);
                                    break;
                                  case 'delete':
                                    _confirmDelete(subject);
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditSubjectDialog(),
    );
  }

  void _showEditSubjectDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AddEditSubjectDialog(subject: subject),
    );
  }

  void _confirmDelete(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete ${subject.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteSubject(subject.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddEditSubjectDialog extends StatefulWidget {
  final Subject? subject;

  const AddEditSubjectDialog({super.key, this.subject});

  @override
  State<AddEditSubjectDialog> createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<AddEditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weeklyHoursController = TextEditingController();
  final _maxDailyHoursController = TextEditingController();
  final _maxConsecutiveHoursController = TextEditingController();
  bool _preferConsecutive = false;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _weeklyHoursController.text = widget.subject!.weeklyHours.toString();
      _maxDailyHoursController.text = widget.subject!.maxDailyHours.toString();
      _maxConsecutiveHoursController.text = widget.subject!.maxConsecutiveHours.toString();
      _preferConsecutive = widget.subject!.preferConsecutive;
    } else {
      _weeklyHoursController.text = '1';
      _maxDailyHoursController.text = '2';
      _maxConsecutiveHoursController.text = '2';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subject == null ? 'Add Subject' : 'Edit Subject'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weeklyHoursController,
                decoration: const InputDecoration(
                  labelText: 'Weekly Hours',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weekly hours';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 1 || hours > 30) {
                    return 'Please enter a valid number (1-30)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxDailyHoursController,
                decoration: const InputDecoration(
                  labelText: 'Max Daily Hours',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter max daily hours';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 1 || hours > 6) {
                    return 'Please enter a valid number (1-6)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxConsecutiveHoursController,
                decoration: const InputDecoration(
                  labelText: 'Max Consecutive Hours',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter max consecutive hours';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 1 || hours > 6) {
                    return 'Please enter a valid number (1-6)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Prefer Consecutive Hours'),
                subtitle: const Text('Schedule hours back-to-back when possible'),
                value: _preferConsecutive,
                onChanged: (value) {
                  setState(() {
                    _preferConsecutive = value;
                  });
                },
              ),
            ],
          ),
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
    final subject = Subject(
      id: widget.subject?.id ?? '',
      name: _nameController.text,
      weeklyHours: int.parse(_weeklyHoursController.text),
      maxDailyHours: int.parse(_maxDailyHoursController.text),
      maxConsecutiveHours: int.parse(_maxConsecutiveHoursController.text),
      preferConsecutive: _preferConsecutive,
      createdAt: widget.subject?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.subject == null) {
      dataProvider.addSubject(subject);
    } else {
      dataProvider.updateSubject(subject);
    }

    Navigator.pop(context);
  }
}
