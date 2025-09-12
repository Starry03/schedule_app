import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/teacher.dart';
import '../models/teacher_subject.dart';
import '../models/teacher_constraint.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  late DataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
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
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Teacher Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddTeacherDialog,
                  icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                  label: Text('Add Teacher', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: ListView.builder(
              itemCount: dataProvider.teachers.length,
              itemBuilder: (context, index) {
                final teacher = dataProvider.teachers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        teacher.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    title: Text(teacher.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacher.email ?? 'No email'),
                        Text('Ore Extra: ${teacher.extraHours}', 
                             style: TextStyle(
                               color: Theme.of(context).colorScheme.primary,
                               fontWeight: FontWeight.w500,
                             )),
                      ],
                    ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'subjects',
                    child: const Row(
                      children: [
                        Icon(Icons.school),
                        SizedBox(width: 8),
                        Text('Materie'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'constraints',
                    child: const Row(
                      children: [
                        Icon(Icons.block),
                        SizedBox(width: 8),
                        Text('Vincoli'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditTeacherDialog(teacher);
                      break;
                    case 'subjects':
                      _showTeacherSubjectsDialog(teacher);
                      break;
                    case 'constraints':
                      _showConstraintsDialog(teacher);
                      break;
                    case 'delete':
                      _confirmDelete(teacher);
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

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditTeacherDialog(),
    );
  }

  void _showEditTeacherDialog(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AddEditTeacherDialog(teacher: teacher),
    );
  }

  void _showConstraintsDialog(Teacher teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherConstraintsScreen(teacher: teacher),
      ),
    );
  }

  void _showTeacherSubjectsDialog(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => _TeacherSubjectsDialog(
        teacher: teacher,
        dataProvider: _dataProvider,
      ),
    );
  }

  void _confirmDelete(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteTeacher(teacher.id);
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

class AddEditTeacherDialog extends StatefulWidget {
  final Teacher? teacher;

  const AddEditTeacherDialog({super.key, this.teacher});

  @override
  State<AddEditTeacherDialog> createState() => _AddEditTeacherDialogState();
}

class _AddEditTeacherDialogState extends State<AddEditTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _extraHoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _nameController.text = widget.teacher!.name;
      _emailController.text = widget.teacher!.email ?? '';
      _extraHoursController.text = widget.teacher!.extraHours.toString();
    } else {
      _extraHoursController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Add Teacher' : 'Edit Teacher'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _extraHoursController,
              decoration: const InputDecoration(
                labelText: 'Ore Extra',
                border: OutlineInputBorder(),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter extra hours';
                }
                final hours = int.tryParse(value);
                if (hours == null || hours < 0) {
                  return 'Please enter a valid number (0 or greater)';
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
    final teacher = Teacher(
      id: widget.teacher?.id ?? '',
      name: _nameController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      createdAt: widget.teacher?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      extraHours: int.parse(_extraHoursController.text),
    );

    if (widget.teacher == null) {
      dataProvider.addTeacher(teacher);
    } else {
      dataProvider.updateTeacher(teacher);
    }

    Navigator.pop(context);
  }
}

class TeacherConstraintsScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherConstraintsScreen({super.key, required this.teacher});

  @override
  State<TeacherConstraintsScreen> createState() => _TeacherConstraintsScreenState();
}

class _TeacherConstraintsScreenState extends State<TeacherConstraintsScreen> {
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final List<String> hours = ['1h', '2h', '3h', '4h', '5h', '6h'];
  Set<String> blockedSlots = {};
  // Map of slotKey -> constraintId for existing persisted constraints for this teacher
  final Map<String, String> _existingConstraintIds = {};

  @override
  void initState() {
    super.initState();
    _loadConstraints();
  }

  void _loadConstraints() {
    // Load existing constraints for this teacher and populate blockedSlots
    // Convert to blockedSlots format: "dayIndex-hourIndex" where indexes are 0-based
    final dp = Provider.of<DataProvider>(context, listen: false);
    // Ensure latest constraints are loaded from backend
    dp.fetchTeacherConstraints().then((_) {
      final constraints = dp.teacherConstraints.where((c) => c.teacherId == widget.teacher.id).toList();
      final newBlocked = <String>{};
      _existingConstraintIds.clear();
      for (final c in constraints) {
        final slotKey = '${c.dayOfWeek - 1}-${c.hourSlot - 1}';
        newBlocked.add(slotKey);
        _existingConstraintIds[slotKey] = c.id;
      }
      setState(() {
        blockedSlots = newBlocked;
      });
    }).catchError((e) {
      // If fetch fails, just leave blockedSlots empty and show a message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nel caricamento dei vincoli: $e')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Themed header instead of AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.teacher.name} - Constraints',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.black),
                  onPressed: _saveConstraints,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tap slots to block/unblock availability',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('')),
                  ...days.map((day) => DataColumn(label: Text(day))),
                ],
                rows: hours.asMap().entries.map((entry) {
                  final hourIndex = entry.key;
                  final hour = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(hour)),
                      ...days.asMap().entries.map((dayEntry) {
                        final dayIndex = dayEntry.key;
                        final slotKey = '$dayIndex-$hourIndex';
                        final isBlocked = blockedSlots.contains(slotKey);
                        
                        return DataCell(
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isBlocked) {
                                  blockedSlots.remove(slotKey);
                                } else {
                                  blockedSlots.add(slotKey);
                                }
                              });
                            },
                            child: Container(
                              width: 80,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isBlocked ? Colors.grey.shade400 : Colors.grey.shade100,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Icon(
                                  isBlocked ? Icons.block : Icons.check,
                                  color: isBlocked ? Colors.black : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveConstraints() {
    // Save constraints to database: compute diffs between current blockedSlots and existing ones
    final dp = Provider.of<DataProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvataggio vincoli...')));

    () async {
      try {
        final currentKeys = blockedSlots;
        final previousKeys = _existingConstraintIds.keys.toSet();

        // To delete: present before, removed now
        final toDelete = previousKeys.difference(currentKeys);
        for (final key in toDelete) {
          final id = _existingConstraintIds[key];
          if (id != null && id.isNotEmpty) {
            await dp.deleteTeacherConstraint(id);
          }
        }

        // To add: newly blocked that didn't exist before
        final toAdd = currentKeys.difference(previousKeys);
        for (final key in toAdd) {
          final parts = key.split('-');
          if (parts.length != 2) continue;
          final dayIndex = int.tryParse(parts[0]) ?? 0;
          final hourIndex = int.tryParse(parts[1]) ?? 0;
          final constraint = TeacherConstraint(
            id: '',
            teacherId: widget.teacher.id,
            dayOfWeek: dayIndex + 1, // convert to 1-based
            hourSlot: hourIndex + 1,
            createdAt: DateTime.now(),
          );
          await dp.addTeacherConstraint(constraint);
        }

        // Refresh local cache from backend
        await dp.fetchTeacherConstraints();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vincoli salvati con successo')));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante il salvataggio: $e')));
      }
    }();
  }
}

class _TeacherSubjectsDialog extends StatefulWidget {
  final dynamic teacher;
  final DataProvider dataProvider;

  const _TeacherSubjectsDialog({
    required this.teacher,
    required this.dataProvider,
  });

  @override
  State<_TeacherSubjectsDialog> createState() => _TeacherSubjectsDialogState();
}

class _TeacherSubjectsDialogState extends State<_TeacherSubjectsDialog> {
  late List<TeacherSubject> teacherSubjects;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await widget.dataProvider.fetchTeacherSubjects();
    await widget.dataProvider.fetchSubjects();
    await widget.dataProvider.fetchClasses();
    
    setState(() {
      teacherSubjects = widget.dataProvider.teacherSubjects
          .where((ts) => ts.teacherId == widget.teacher.id)
          .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Materie di ${widget.teacher.name}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: teacherSubjects.isEmpty
                        ? const Center(child: Text('Nessuna materia assegnata'))
                        : ListView.builder(
                            itemCount: teacherSubjects.length,
                            itemBuilder: (context, index) {
                              final ts = teacherSubjects[index];
                              final subject = widget.dataProvider.subjects
                                  .where((s) => s.id == ts.subjectId).firstOrNull;
                              final classModel = widget.dataProvider.classes
                                  .where((c) => c.id == ts.classId).firstOrNull;
                              
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.school,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  title: Text(subject?.name ?? 'Materia sconosciuta'),
                                  subtitle: Text(
                                    'Classe: ${classModel?.name ?? 'Sconosciuta'}\n'
                                    'Ore settimanali: ${subject?.weeklyHours ?? 0} • '
                                    'Max consecutive: ${subject?.maxConsecutiveHours ?? 0}',
                                  ),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                    onPressed: () async {
                                      await widget.dataProvider.deleteTeacherSubject(ts.id);
                                      _loadData();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSubjectDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi Materia'),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTeacherSubjectDialog(
        teacher: widget.teacher,
        dataProvider: widget.dataProvider,
        onAdded: _loadData,
      ),
    );
  }
}

class _AddTeacherSubjectDialog extends StatefulWidget {
  final dynamic teacher;
  final DataProvider dataProvider;
  final VoidCallback onAdded;

  const _AddTeacherSubjectDialog({
    required this.teacher,
    required this.dataProvider,
    required this.onAdded,
  });

  @override
  State<_AddTeacherSubjectDialog> createState() => _AddTeacherSubjectDialogState();
}

class _AddTeacherSubjectDialogState extends State<_AddTeacherSubjectDialog> {
  String? selectedSubjectId;
  Set<String> selectedClassIds = <String>{};

  @override
  Widget build(BuildContext context) {
    // Filtra le classi già assegnate per la materia selezionata
    final existingAssignments = widget.dataProvider.teacherSubjects
        .where((ts) => ts.teacherId == widget.teacher.id && ts.subjectId == selectedSubjectId)
        .map((ts) => ts.classId)
        .toSet();
    
    final availableClasses = widget.dataProvider.classes
        .where((c) => !existingAssignments.contains(c.id))
        .toList();

    return AlertDialog(
      title: const Text('Aggiungi Materia'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selezione materia
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Materia'),
              value: selectedSubjectId,
              items: widget.dataProvider.subjects
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedSubjectId = value;
                selectedClassIds.clear(); // Reset selezione classi
              }),
            ),
            const SizedBox(height: 16),
            
            // Lista classi disponibili
            if (selectedSubjectId != null) ...[
              const Text(
                'Seleziona le classi:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: availableClasses.isEmpty
                    ? const Center(child: Text('Tutte le classi sono già assegnate per questa materia'))
                    : ListView.builder(
                        itemCount: availableClasses.length,
                        itemBuilder: (context, index) {
                          final classModel = availableClasses[index];
                          final isSelected = selectedClassIds.contains(classModel.id);
                          
                          return CheckboxListTile(
                            title: Text(classModel.name),
                            subtitle: Text('Grado: ${classModel.grade} - Sezione: ${classModel.section}'),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedClassIds.add(classModel.id);
                                } else {
                                  selectedClassIds.remove(classModel.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Seleziona prima una materia'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: (selectedSubjectId == null || selectedClassIds.isEmpty)
              ? null
              : () async {
                  // Aggiungi un TeacherSubject per ogni classe selezionata
                  for (final classId in selectedClassIds) {
                    final teacherSubject = TeacherSubject(
                      id: '',
                      teacherId: widget.teacher.id,
                      subjectId: selectedSubjectId!,
                      classId: classId,
                      createdAt: DateTime.now(),
                    );
                    await widget.dataProvider.addTeacherSubject(teacherSubject);
                  }
                  Navigator.pop(context);
                  widget.onAdded();
                },
          child: Text('Aggiungi (${selectedClassIds.length})'),
        ),
      ],
    );
  }
}
