import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/save_pdf.dart';
import '../providers/theme_provider.dart';
import '../providers/data_provider.dart';
import '../models/schedule_slot.dart';
import '../providers/settings_provider.dart';
import '../models/schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleCell extends StatefulWidget {
  final String keyString;
  final Widget child;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;
  final bool isInvalid;
  final VoidCallback onTap;

  const _ScheduleCell({
    required this.keyString,
    required this.child,
    required this.bgColor,
    required this.borderColor,
    required this.isSelected,
    required this.isInvalid,
    required this.onTap,
  });

  @override
  State<_ScheduleCell> createState() => _ScheduleCellState();
}

class _ScheduleCellState extends State<_ScheduleCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final borderWidth = widget.isSelected ? 2.4 : 0.5;
    final effectiveBorderColor = widget.isInvalid ? Theme.of(context).colorScheme.error : widget.borderColor;
    final boxShadow = _hover ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), blurRadius: 6, spreadRadius: 1)] : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.bgColor,
            border: Border.all(color: effectiveBorderColor, width: borderWidth),
            boxShadow: boxShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DataProvider _dataProvider;
  bool _showSchedulesList = false;
  bool _isGeneratingSchedule = false;
  String? _currentScheduleId;
  String _scheduleName = 'Orario Attuale';
  final TextEditingController _scheduleNameController = TextEditingController();
  // Selection prototype for moving/swapping slots
  String? _selectedSlotKey; // format: teacherId-day-hour
  // Track slots that violate constraints after edits (to highlight before save)
  final Set<String> _invalidSlotKeys = {};
  String? _saveErrorMessage;
  // Track last swap for undo: store indices and previous classIds
  Map<String, dynamic>? _lastSwap;
  // hover now managed per-cell by _ScheduleCell to avoid rebuilding the whole grid

  String _slotKeyFor(String teacherId, int dayIndex, int hourIndex) => '$teacherId-$dayIndex-$hourIndex';

  @override
  void initState() {
    super.initState();
    // Use listen: false in initState
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _dataProvider.fetchClasses();
    _dataProvider.fetchSchedules().then((_) {
      // After fetching schedules, get the current schedule name
      final currentSchedule = _dataProvider.getCurrentSchedule();
      if (currentSchedule != null) {
        setState(() {
          _scheduleName = currentSchedule.name;
          _currentScheduleId = currentSchedule.id;
          _scheduleNameController.text = _scheduleName;
        });
      }
    });
    _dataProvider.fetchTeachers();
    // Fetch slots for currently selected schedule (empty -> latest/generated)
    _dataProvider.fetchScheduleSlots('');
  }

  @override
  void dispose() {
    _scheduleNameController.dispose();
    super.dispose();
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
            child: Container(
              decoration: BoxDecoration(
                gradient: Provider.of<ThemeProvider>(context).primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showSchedulesList ? 'Orari Salvati' : 'Orario Attuale',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_showSchedulesList ? Icons.schedule : Icons.folder, color: Colors.white),
                            tooltip: _showSchedulesList ? 'Mostra Orario Attuale' : 'Mostra Orari Salvati',
                            onPressed: () async {
                              if (!_showSchedulesList) {
                                // Loading saved schedules - refresh from database
                                await _dataProvider.fetchSchedules();
                              }
                              setState(() => _showSchedulesList = !_showSchedulesList);
                            },
                          ),
                          if (!_showSchedulesList) ...[
                            IconButton(
                              icon: _isGeneratingSchedule 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.refresh, color: Colors.white),
                              tooltip: _isGeneratingSchedule ? 'Generando...' : 'Genera Orario',
                              onPressed: _isGeneratingSchedule ? null : () => _generateSchedule(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.white),
                              tooltip: 'Elimina Orario',
                              onPressed: () => _clearSchedule(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                              tooltip: 'Esporta PDF',
                              onPressed: () => _exportToPDF(dataProvider),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (_currentScheduleId != null) ...[
                    const SizedBox(height: 8),
                    Text('Schedule ID: $_currentScheduleId', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85))),
                  ],
                ],
              ),
            ),
          ),
          // Schedule Name Input (only when not showing list)
          if (!_showSchedulesList) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _scheduleNameController,
                        style: Theme.of(context).textTheme.titleMedium,
                        decoration: InputDecoration(
                          hintText: 'Nome orario...',
                          prefixIcon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _scheduleName = value.isNotEmpty ? value : 'Orario Attuale';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _currentScheduleId != null 
                      ? () => _updateScheduleName(_scheduleNameController.text)
                      : null,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Salva'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Content
          Expanded(child: _showSchedulesList ? _buildSchedulesList(dataProvider) : _buildScheduleGrid(dataProvider)),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid(DataProvider dataProvider) {
    // Build a grid with teachers on rows, days/hours on columns
    final days = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì'];
    final hours = ['1', '2', '3', '4', '5', '6'];

    // If no teachers loaded yet
    if (dataProvider.teachers.isEmpty) {
      return const Center(child: Text('Nessun docente disponibile per generare la griglia'));
    }

    // Helper to find slot for a given teacher/day/hour
    ScheduleSlot? slotFor(String teacherId, int dayIndex, int hourIndex) {
      try {
        return dataProvider.scheduleSlots.firstWhere((s) => s.teacherId == teacherId && s.dayOfWeek == dayIndex && s.hourSlot == hourIndex);
      } catch (_) {
        return null;
      }
    }

  // Use _slotKeyFor helper defined on state

    void onSlotTap(String teacherId, int dayIndex, int hourIndex, ScheduleSlot? slot) {
      // Only allow swapping between two filled slots for this prototype
      if (slot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a filled slot to swap.')),
        );
        return;
      }
  final key = _slotKeyFor(teacherId, dayIndex, hourIndex);

      // Validation helpers removed here; validation happens at save time

  debugPrint('onSlotTap: tapped key=$key selected=$_selectedSlotKey');
      if (_selectedSlotKey == null) {
        // Allow selecting any filled slot; defer validation to save time
        setState(() {
          _selectedSlotKey = key;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot selezionato. Tocca un altro slot pieno per scambiare.')),
        );
        return;
      }

      if (_selectedSlotKey == key) {
        // unselect
        setState(() {
          _selectedSlotKey = null;
        });
        return;
      }

      // We have a selected slot and now another one -> attempt swap but validate against DB/algorithm constraints
      final parts = _selectedSlotKey!.split('-');
      if (parts.length != 3) {
        setState(() => _selectedSlotKey = null);
        return;
      }
      final selTeacher = parts[0];
      final selDay = int.tryParse(parts[1]) ?? 0;
      final selHour = int.tryParse(parts[2]) ?? 0;

      // Find indices in dataProvider.scheduleSlots
      int findIndex(String teacherId, int day, int hour) {
        return dataProvider.scheduleSlots.indexWhere((s) => s.teacherId == teacherId && s.dayOfWeek == day && s.hourSlot == hour);
      }

      final idxA = findIndex(selTeacher, selDay, selHour);
      final idxB = findIndex(teacherId, dayIndex, hourIndex);
      if (idxA == -1 || idxB == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot find slots to swap.')),
        );
        setState(() => _selectedSlotKey = null);
        return;
      }

      final a = dataProvider.scheduleSlots[idxA];
      final b = dataProvider.scheduleSlots[idxB];

      debugPrint('Swap indices: idxA=$idxA idxB=$idxB a.class=${a.classId} b.class=${b.classId}');

      // Both slots must be present (filled) to swap; we've already located them (a and b)
      // If swapping identical class assignments, it's a no-op
      if (a.classId == b.classId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun cambiamento: stessi dati.')));
        setState(() => _selectedSlotKey = null);
        return;
      }

      // Save previous state for undo
      _lastSwap = {
        'idxA': idxA,
        'idxB': idxB,
        'aClass': a.classId,
        'bClass': b.classId,
      };

      final tmpClass = a.classId;
      a.classId = b.classId;
      b.classId = tmpClass;
      debugPrint('Swapped: a.class=${a.classId} b.class=${b.classId}');
  debugPrint('Swapped: a.class=${a.classId} b.class=${b.classId}');

      // Mark schedule dirty and notify
      dataProvider.markScheduleDirty();
      setState(() {
        _selectedSlotKey = null;
      });

      // Show snackbar with undo
      final sb = SnackBar(
        content: const Text('Slots scambiati. Ricordati di salvare le modifiche.'),
        action: SnackBarAction(label: 'Annulla', onPressed: () {
          // Undo
          if (_lastSwap != null) {
            final ia = _lastSwap!['idxA'] as int;
            final ib = _lastSwap!['idxB'] as int;
            final prevA = _lastSwap!['aClass'] as String;
            final prevB = _lastSwap!['bClass'] as String;
            dataProvider.scheduleSlots[ia].classId = prevA;
            dataProvider.scheduleSlots[ib].classId = prevB;
            dataProvider.markScheduleDirty();
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap annullato')));
          }
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(sb);
    }

    // Calculate total columns: 1 (teacher) + days * hours

    // Create table rows with single header row
    final List<TableRow> rows = [];

    // Single header row: Teacher column + Day-Hour combinations
    final List<Widget> headerCells = [
      Container(
        height: 60,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
        ),
        child: const Text(
          'Docente',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    ];

    for (var d = 0; d < days.length; d++) {
      for (var h = 0; h < hours.length; h++) {
        headerCells.add(
          Container(
            height: 60,
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (h == 0) Text(
                  days[d],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  hours[h],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    rows.add(TableRow(children: headerCells));

    // Rows for each teacher
    for (final teacher in dataProvider.teachers) {
      final List<Widget> cells = [];
      
      // Teacher name cell
      cells.add(Container(
        height: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            teacher.name, 
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ));

      // Add cells for each day/hour combination
      for (var d = 0; d < days.length; d++) {
        final dayIndex = d + 1;
        
            for (var h = 0; h < hours.length; h++) {
          final hourIndex = h + 1;
          final slot = slotFor(teacher.id, dayIndex, hourIndex);

          Widget cellContent;
          if (slot == null) {
            cellContent = const SizedBox(height: 50);
          } else {
            // Find class safely
            dynamic cls;
            try {
              cls = dataProvider.classes.firstWhere((c) => c.id == slot.classId);
            } catch (_) {
              cls = null;
            }
            final className = cls != null ? cls.name : 'N/A';
            cellContent = Container(
              height: 50,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(4),
              child: Text(
                className, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          final thisKey = _slotKeyFor(teacher.id, dayIndex, hourIndex);
          final isSelected = (_selectedSlotKey != null && _selectedSlotKey == thisKey);
          // Determine background colors using settings (high contrast)
          final settings = Provider.of<SettingsProvider>(context);
          // When highContrast is enabled, alternate column colors per day to improve day-to-day contrast.
          Color chooseColumnBg(int dayIdx, bool filled) {
            if (!settings.highContrast) {
              return filled ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Theme.of(context).cardColor;
            }
            // For high contrast we draw full-column stripes behind the table (see below).
            // Keep filled cells lightly tinted so text remains readable; let empty cells be transparent
            // so the vertical stripe shows through across the entire table height.
            final useAlt = (dayIdx % 2) == 0;
            if (filled) {
              return useAlt
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.14)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.08);
            }
            return Colors.transparent;
          }
          final bgColor = chooseColumnBg(dayIndex, slot != null);
          final borderColor = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.3);

          cells.add(
            _ScheduleCell(
              keyString: thisKey,
              child: cellContent,
              bgColor: bgColor,
              borderColor: borderColor,
              isSelected: isSelected,
              isInvalid: _invalidSlotKeys.contains(thisKey),
              onTap: () => onSlotTap(teacher.id, dayIndex, hourIndex, slot),
            ),
          );
        }
      }

      rows.add(TableRow(children: cells));
    }

    // Wrap table in horizontal + vertical scroll views. When highContrast is enabled
    // draw full-height vertical stripes behind the table to separate days visually.
    final settings = Provider.of<SettingsProvider>(context);

    // Column layout constants (match Table.columnWidths)
    const teacherColWidth = 120.0;
    const slotColWidth = 80.0; // each hour slot column

    // Build the table widget as before
    final tableWidget = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FixedColumnWidth(teacherColWidth), // Teacher column
        for (var i = 1; i < 1 + (days.length * hours.length); i++)
          i: const FixedColumnWidth(slotColWidth),
      },
      children: rows,
    );

    // If highContrast, prepare a stack with full-height stripes underneath the table
    Widget content;
    if (settings.highContrast) {
      // total width: teacher col + all slot cols
      final totalWidth = teacherColWidth + (days.length * hours.length * slotColWidth);

      // Build positioned stripe containers for each day group (each day spans 6 slot columns)
      final List<Widget> stripes = [];
      // Add teacher column background first
      stripes.add(Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: teacherColWidth,
        child: Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ));

      for (var d = 0; d < days.length; d++) {
        final dayIdx = d + 1;
        final dayStartLeft = teacherColWidth + (d * hours.length * slotColWidth);
        // Choose stripe color by day index (3-tone subtle palette)
        final stripeColor = (dayIdx % 3 == 0)
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.06)
            : (dayIdx % 3 == 1)
                ? Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.05)
                : Theme.of(context).colorScheme.surface.withOpacity(0.03);

        stripes.add(Positioned(
          left: dayStartLeft,
          top: 0,
          bottom: 0,
          width: hours.length * slotColWidth,
          child: Container(color: stripeColor),
        ));

        // Add a thin vertical divider at the right edge of the day group to emphasize boundary
        stripes.add(Positioned(
          left: dayStartLeft + hours.length * slotColWidth - 1,
          top: 8,
          bottom: 8,
          width: 1,
          child: Container(color: Theme.of(context).colorScheme.outline.withOpacity(0.35)),
        ));
      }

      // Wrap table in scrollables and place stripes behind it
      content = SizedBox(
        width: totalWidth,
        child: Stack(
          children: [
            // full-height stripes
            ...stripes,
            // Table sits above stripes
            tableWidget,
          ],
        ),
      );
    } else {
      content = tableWidget;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: content,
        ),
      ),
    );
  }

  Widget _buildSchedulesList(DataProvider dataProvider) {
    final savedSchedules = dataProvider.getSavedSchedules();

    if (savedSchedules.isEmpty) {
      return const Center(
        child: Text('Nessun orario salvato'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedSchedules.length,
      itemBuilder: (context, index) {
        final schedule = savedSchedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(schedule.name),
            subtitle: Text(
              'Creato: ${schedule.createdAt.day}/${schedule.createdAt.month}/${schedule.createdAt.year} '
              '${schedule.createdAt.hour}:${schedule.createdAt.minute.toString().padLeft(2, '0')}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.visibility), onPressed: () => _loadSchedule(schedule.id)),
                IconButton(icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error), onPressed: () => _deleteSchedule(schedule.id)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSchedule(String scheduleId) async {
    // If there are unsaved changes, ask user
    if (_dataProvider.isScheduleDirty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Orario non salvato'),
          content: const Text('Hai un orario non salvato. Vuoi salvarlo prima di aprirne un altro?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No, scarta')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sì, salva')),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveCurrentSchedule();
      }
    }

    await _dataProvider.loadSchedule(scheduleId);
    
    // Get the loaded schedule name
    final loadedSchedule = _dataProvider.schedules.firstWhere((s) => s.id == scheduleId, orElse: () => 
        Schedule(id: scheduleId, name: 'Orario Caricato', generationSeed: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()));
    
    setState(() {
      _currentScheduleId = scheduleId;
      _scheduleName = loadedSchedule.name;
      _scheduleNameController.text = _scheduleName;
      _showSchedulesList = false;
    });
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina orario'),
        content: const Text('Sei sicuro di voler eliminare questo orario?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataProvider.deleteSavedSchedule(scheduleId);
      // Refresh list
      await _dataProvider.fetchSchedules();
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveCurrentSchedule() async {
    if (_dataProvider.scheduleSlots.isEmpty) return;

    // Validate all slots against DB constraints and simple algorithmic rules before saving
    _invalidSlotKeys.clear();
    _saveErrorMessage = null;

    // Helper: check DB teacher constraints
    bool hasDbConstraint(String tId, int day, int hour) {
      return _dataProvider.teacherConstraints.any((c) => c.teacherId == tId && c.dayOfWeek == day && c.hourSlot == hour);
    }

    // Helper: whether a given teacher can teach a subject in a given class
    bool teacherCanTeachInClass(String tId, String subjectId, String classId) {
      return _dataProvider.teacherSubjects.any((ts) => ts.teacherId == tId && ts.subjectId == subjectId && ts.classId == classId);
    }

    // Simple algorithmic checks: teacher not exceeding weekly hard cap (18) by current assignments
    final Map<String, int> teacherAssigned = {};
    for (final s in _dataProvider.scheduleSlots) {
      teacherAssigned[s.teacherId] = (teacherAssigned[s.teacherId] ?? 0) + 1;
    }

    for (final s in _dataProvider.scheduleSlots) {
  final key = _slotKeyFor(s.teacherId, s.dayOfWeek, s.hourSlot);
      // DB constraint violation
      if (hasDbConstraint(s.teacherId, s.dayOfWeek, s.hourSlot)) {
        _invalidSlotKeys.add(key);
        continue;
      }
      // Teacher must be able to teach the subject in that class
      if (!teacherCanTeachInClass(s.teacherId, s.subjectId, s.classId)) {
        _invalidSlotKeys.add(key);
        continue;
      }
      // Weekly cap violation
      if ((teacherAssigned[s.teacherId] ?? 0) > 18) {
        _invalidSlotKeys.add(key);
        continue;
      }
    }

    if (_invalidSlotKeys.isNotEmpty) {
      // Prepare a message listing count and prevent save
      _saveErrorMessage = 'Impossibile salvare: ${_invalidSlotKeys.length} slot violano i vincoli. Correggi prima di salvare.';
      // Refresh UI to show highlights
      if (mounted) setState(() {});
      // Show persistent snackbar-like message at bottom
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_saveErrorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    // If all good, proceed to save by sending the slots to the provider
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvataggio in corso...')));
      await _dataProvider.saveScheduleSlots(_dataProvider.scheduleSlots, scheduleId: _currentScheduleId);
      _dataProvider.markScheduleClean();
      if (mounted) setState(() {
        _saveErrorMessage = null;
        _invalidSlotKeys.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orario salvato con successo')));
    } catch (e) {
      if (mounted) setState(() {
        _saveErrorMessage = 'Errore durante il salvataggio: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante il salvataggio: $e')));
    }
  }

  // Generate schedule method
  Future<void> _generateSchedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Genera Orario'),
        content: const Text('Questo genererà un nuovo orario per tutto l\'istituto. Continuare?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Genera')),
        ],
      ),
    );

    if (confirmed != true) return;

    // Start loading state
    setState(() {
      _isGeneratingSchedule = true;
    });

    try {
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Generazione orario in corso...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Run the heavy computation in a separate isolate to prevent UI blocking
      final scheduleId = await _generateScheduleInBackground();
      
      await _dataProvider.fetchSchedules(); // Refresh schedules
      final currentSchedule = _dataProvider.getCurrentSchedule();
      
      setState(() {
        _currentScheduleId = scheduleId;
        if (currentSchedule != null) {
          _scheduleName = currentSchedule.name;
          _scheduleNameController.text = _scheduleName;
        }
      });
      
      await _dataProvider.fetchScheduleSlots(scheduleId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orario generato con successo!')),
      );
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      // If this is a generation conflict summary (thrown by DataProvider), show a dialog with details
      if (err.contains('conflicts')) {
        final parts = err.split('\n');
        // Remove the first line if it's the generic header
        final details = parts.length > 1 ? parts.sublist(1) : parts;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conflitti nella generazione'),
            content: SingleChildScrollView(
              child: ListBody(
                children: details.map((d) => Text(d)).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante la generazione: $e')),
        );
      }
    } finally {
      // Stop loading state
      if (mounted) {
        setState(() {
          _isGeneratingSchedule = false;
        });
      }
    }
  }

  Future<String> _generateScheduleInBackground() async {
    // Use the progress-enabled method with yielding points
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return await _dataProvider.generateInstituteScheduleWithProgress((progress) {
      // Could show progress in the future, for now just ensure UI responsiveness
      debugPrint('Schedule generation progress: ${(progress * 100).toInt()}%');
    }, maxVariableHours: settings.maxVariableHours, autoBreakEnabled: settings.autoBreakEnabled);
  }

  // Delete schedule method
  Future<void> _clearSchedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Orario'),
        content: const Text('Questo rimuoverà tutti gli slot dell\'orario. Continuare?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dataProvider.clearAllSchedules();
      await _dataProvider.fetchScheduleSlots('');
      setState(() {
        _currentScheduleId = null;
        _scheduleName = 'Orario Attuale';
        _scheduleNameController.text = _scheduleName;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orario eliminato con successo!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  // Update schedule name method
  Future<void> _updateScheduleName(String newName) async {
    if (newName.trim().isEmpty || _currentScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome non valido o nessun orario caricato')),
      );
      return;
    }
    
    try {
      await _dataProvider.updateScheduleName(_currentScheduleId!, newName.trim());
      
      setState(() {
        _scheduleName = newName.trim();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nome orario aggiornato: ${newName.trim()}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'aggiornamento: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Export to PDF method
  Future<void> _exportToPDF(DataProvider dataProvider) async {
    // Check if we have the necessary data, try to reload if missing
    if (dataProvider.teachers.isEmpty || dataProvider.classes.isEmpty || dataProvider.scheduleSlots.isEmpty) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caricamento dati in corso...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      try {
        // Try to reload missing data
        if (dataProvider.teachers.isEmpty) {
          await dataProvider.fetchTeachers();
        }
        if (dataProvider.classes.isEmpty) {
          await dataProvider.fetchClasses();
        }
        if (dataProvider.teacherConstraints.isEmpty) {
          await dataProvider.fetchTeacherConstraints();
        }
        if (dataProvider.scheduleSlots.isEmpty && _currentScheduleId != null) {
          await dataProvider.fetchScheduleSlots(_currentScheduleId!);
        }
        
        // Check again after trying to reload
        if (dataProvider.teachers.isEmpty || dataProvider.classes.isEmpty || dataProvider.scheduleSlots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !dataProvider.isOnline ? 
                'Server offline: ${dataProvider.lastError ?? "Impossibile connettersi"}' :
                dataProvider.teachers.isEmpty ? 'Nessun insegnante trovato nel database' :
                dataProvider.classes.isEmpty ? 'Nessuna classe trovata nel database' :
                'Nessun orario generato da esportare'
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il caricamento dei dati: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    try {
      final pdf = pw.Document();
      String sanitize(String s, {int maxLen = 60}) {
        var out = s.replaceAll(RegExp(r'[\x00-\x1F]'), '');
        out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (out.isEmpty) return ' ';
        if (out.length > maxLen) return out.substring(0, maxLen - 1);
        return out;
      }
      final days = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì'];

      // Helper to find slot for a given teacher/day/hour
      ScheduleSlot? slotFor(String teacherId, int dayIndex, int hourIndex) {
        try {
          return dataProvider.scheduleSlots.firstWhere(
            (s) => s.teacherId == teacherId && s.dayOfWeek == dayIndex && s.hourSlot == hourIndex
          );
        } catch (_) {
          return null;
        }
      }

      // Use MultiPage to allow automatic pagination for large tables
        // compute first column width based on longest name (including header)
        final pageAvailable = PdfPageFormat.a4.landscape.availableWidth;
        final maxNameLen = ([ 'Docente', ...dataProvider.teachers.map((t) => sanitize(t.name)) ]..removeWhere((s) => s.isEmpty)).fold<int>(0, (p, e) => e.length > p ? e.length : p);
        final baseCharWidth = 5.6; // approximate width per character in points
        final desiredFirstCol = (maxNameLen * baseCharWidth) + 16; // padding
  final maxFirstCol = pageAvailable * 0.38; // don't use more than 38% of page width
  double firstColWidth = desiredFirstCol > maxFirstCol ? maxFirstCol : desiredFirstCol;
  // Ensure a sensible minimum so the header 'Docente' won't wrap
  const hardMinFirstCol = 70.0;
  final headerText = 'Docente';
  final headerMin = (headerText.length * baseCharWidth) + 16;
  final minFirstCol = headerMin > hardMinFirstCol ? headerMin : hardMinFirstCol;
  if (firstColWidth < minFirstCol) firstColWidth = minFirstCol;
        // compute teacher font size: shrink proportionally if needed
        double teacherFontSize = 9.0;
        if (desiredFirstCol > firstColWidth) {
          final ratio = firstColWidth / desiredFirstCol;
          teacherFontSize = (9.0 * ratio).clamp(6.0, 9.0);
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context ctx) {
              return [
                pw.Text(
                  sanitize(_scheduleName),
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              pw.SizedBox(height: 12),
              // Create header aligned to the table column widths
              // First column is fixed (firstColWidth), the remaining width is shared
              // equally among 30 slot columns; each day spans 6 of those columns so
              // dayGroupWidth equals (pageAvailable - firstColWidth) / 5
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                child: pw.Row(
                  children: [
                    // Teacher column - fixed width to match table
                    pw.Container(
                      width: firstColWidth,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(right: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'Docente',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                    // Day groups - compute width per day so it aligns with the 6 slot columns
                    for (var d = 0; d < days.length; d++) pw.Container(
                      width: (pageAvailable - firstColWidth) / 5,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(right: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                      ),
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Text(
                              days[d],
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                              textAlign: pw.TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          // Invisible row of 6 columns to draw the vertical separators so they align with the table
                          pw.Container(
                            height: 0.5,
                            child: pw.Row(
                              children: List.generate(6, (i) => pw.Expanded(
                                child: pw.Container(
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(right: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                                  ),
                                ),
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              // Single large table: 1 'Docente' column + 30 slot columns (6 hours × 5 days)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: <int, pw.TableColumnWidth>{
                  0: pw.FixedColumnWidth(firstColWidth),
                  for (int i = 1; i <= 30; i++) i: pw.FlexColumnWidth(1),
                },
                children: [
                  // Rows per teacher
                  for (final teacher in dataProvider.teachers)
                    pw.TableRow(
                      children: [
                        pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6), alignment: pw.Alignment.center, child: pw.Text(sanitize(teacher.name, maxLen: 24), style: pw.TextStyle(fontSize: teacherFontSize, fontWeight: pw.FontWeight.bold), softWrap: false, overflow: pw.TextOverflow.clip)),
                        // 30 slot cells
                        for (var d = 0; d < days.length; d++) for (var h = 0; h < 6; h++)
                          (() {
                            final dayIndex = d + 1;
                            final hourIndex = h + 1;
                            final slot = slotFor(teacher.id, dayIndex, hourIndex);
                            final hasConstraint = dataProvider.teacherConstraints.any((c) => c.teacherId == teacher.id && c.dayOfWeek == dayIndex && c.hourSlot == hourIndex);
                            String className = ' ';
                            if (slot != null) {
                              try {
                                final cls = dataProvider.classes.firstWhere((c) => c.id == slot.classId);
                                className = cls.name;
                              } catch (_) {
                                className = 'N/A';
                              }
                            }
                            final safeClassName = sanitize(className, maxLen: 18);
                            return pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4), decoration: hasConstraint ? pw.BoxDecoration(color: PdfColor.fromInt(0xFFCCEEFF)) : pw.BoxDecoration(), alignment: pw.Alignment.center, child: pw.Text(safeClassName, style: pw.TextStyle(fontSize: 8), softWrap: false, overflow: pw.TextOverflow.clip));
                          })(),
                      ],
                    ),
                ],
              ),
            ];
          },
        ),
      );

      final fileName = '${_scheduleName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Save the PDF using a cross-platform helper. On web this triggers a
      // browser download; on other platforms it writes to a sensible folder.
      try {
        final bytes = await pdf.save();
        final result = await savePdf(bytes, fileName);
        // Detect NaN/layout assertion errors and fall back to a simpler PDF format
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved in ${result['directory']}:\n${result['path']}'),
            duration: const Duration(seconds: 6),
          ),
        );
      } catch (saveError) {
        // Detect NaN/layout assertion errors and fall back to a simpler PDF format
        final msg = saveError.toString();
        if (msg.contains('isNaN') || msg.contains('num.dart') || msg.contains('NaN')) {
          final fallbackPdf = pw.Document();
          fallbackPdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4.landscape,
              build: (pw.Context ctx) {
                return [
                  pw.Text('${sanitize(_scheduleName)} - Fallback export', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  for (final teacher in dataProvider.teachers) pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(sanitize(teacher.name), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      for (var d = 0; d < days.length; d++) pw.Row(children: [
                        pw.Expanded(flex: 1, child: pw.Text(days[d], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            // build classes for this teacher/day as comma-separated
                            List.generate(6, (h) {
                              final dayIndex = d + 1;
                              final hourIndex = h + 1;
                              ScheduleSlot? slot;
                              try {
                                slot = dataProvider.scheduleSlots.firstWhere((s) => s.teacherId == teacher.id && s.dayOfWeek == dayIndex && s.hourSlot == hourIndex);
                              } catch (_) {
                                slot = null;
                              }
                              if (slot == null) return ' - ';
                              try {
                                final cls = dataProvider.classes.firstWhere((c) => c.id == slot!.classId);
                                final hasConstraint = dataProvider.teacherConstraints.any((c) => c.teacherId == teacher.id && c.dayOfWeek == dayIndex && c.hourSlot == hourIndex);
                                return hasConstraint ? '${cls.name}*' : cls.name;
                              } catch (_) {
                                return 'N/A';
                              }
                            }).join(', '),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ])
                    ],
                  ),
                ];
              },
            ),
          );

          final fallbackName = '${_scheduleName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_${DateTime.now().millisecondsSinceEpoch}_fallback.pdf';
          final bytes = await fallbackPdf.save();
          try {
            final result = await savePdf(bytes, fallbackName);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF saved (fallback) in ${result['directory']}:\n${result['path']}'),
                duration: const Duration(seconds: 6),
              ),
            );
          } catch (e) {
            rethrow; // allow outer catch to show error
          }
          return;
        }

        // If it's a different error, rethrow to be handled by outer catch
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'export PDF: $e\nDettagli: ${e.toString()}'),
          duration: const Duration(seconds: 6),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

