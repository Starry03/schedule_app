import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher.dart';
import '../models/subject.dart';
import '../models/class_model.dart';
import '../models/schedule.dart';
import '../models/schedule_slot.dart';
import '../models/teacher_subject.dart';
import '../models/teacher_constraint.dart';

class DataProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  
  // Connection status tracking
  bool _isOnline = true;
  String? _lastError;

  bool get isOnline => _isOnline;
  String? get lastError => _lastError;
  List<ClassModel> _classes = [];
  List<Schedule> _schedules = [];
  List<ScheduleSlot> _scheduleSlots = [];
  List<TeacherSubject> _teacherSubjects = [];
  List<TeacherConstraint> _teacherConstraints = [];

  // Track institute-wide teacher busy slots and weekly hours to avoid clashes across classes
  final Map<String, Set<String>> _teacherBusySlots = {}; // teacherId -> set of 'day-hour'
  final Map<String, int> _teacherWeeklyHours = {}; // teacherId -> hours scheduled this week

  List<Teacher> get teachers => _teachers..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  List<Subject> get subjects => _subjects..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  List<ClassModel> get classes => _classes..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  List<Schedule> get schedules => _schedules;
  List<ScheduleSlot> get scheduleSlots => _scheduleSlots;
  List<TeacherSubject> get teacherSubjects => _teacherSubjects;
  List<TeacherConstraint> get teacherConstraints => _teacherConstraints;

  // Helper method to handle network errors consistently
  Future<T?> _handleNetworkCall<T>(Future<T> Function() networkCall, String operationName) async {
    try {
      _lastError = null;
      final result = await networkCall();
      
      // If we reach here, the call was successful
      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
      
      return result;
    } catch (error) {
      _isOnline = false;
      
      String errorMessage;
      if (error.toString().contains('Failed to connect') || 
          error.toString().contains('Network is unreachable') ||
          error.toString().contains('Connection refused') ||
          error.toString().contains('SocketException')) {
        errorMessage = 'Impossibile connettersi al server. Verifica la connessione internet.';
      } else if (error.toString().contains('timeout')) {
        errorMessage = 'Timeout nella connessione al server. Riprova più tardi.';
      } else {
        errorMessage = 'Errore durante $operationName: ${error.toString()}';
      }
      
      _lastError = errorMessage;
      notifyListeners();
      
      // Log the error for debugging
      debugPrint('Network error in $operationName: $error');
      
      return null;
    }
  }

  // Track whether the currently loaded schedule has unsaved local changes
  bool _isScheduleDirty = false;
  bool get isScheduleDirty => _isScheduleDirty;

  void markScheduleDirty() {
    _isScheduleDirty = true;
    notifyListeners();
  }

  void markScheduleClean() {
    _isScheduleDirty = false;
    notifyListeners();
  }

  Future<void> fetchTeachers() async {
    final response = await _handleNetworkCall(
      () => _supabase.from('teachers').select(),
      'caricamento insegnanti'
    );
    
    if (response != null) {
      _teachers = response.map((json) => Teacher.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<bool> addTeacher(Teacher teacher) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final teacherInsert = {
      'name': teacher.name,
      'email': teacher.email,
      'created_at': teacher.createdAt.toIso8601String(),
      'updated_at': teacher.updatedAt.toIso8601String(),
      'extra_hours': teacher.extraHours,
    };
    
    final response = await _handleNetworkCall(
      () => _supabase.from('teachers').insert(teacherInsert).select().single(),
      'aggiunta insegnante'
    );
    
    if (response != null) {
      _teachers.add(Teacher.fromJson(response));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateTeacher(Teacher teacher) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('teachers').update(teacher.toJson()).eq('id', teacher.id),
      'aggiornamento insegnante'
    );
    
    if (result != null) {
      final index = _teachers.indexWhere((t) => t.id == teacher.id);
      if (index != -1) {
        _teachers[index] = teacher;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteTeacher(String id) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('teachers').delete().eq('id', id),
      'eliminazione insegnante'
    );
    
    if (result != null) {
      _teachers.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Similar methods for subjects, classes, etc.

  Future<void> fetchSubjects() async {
    final response = await _handleNetworkCall(
      () => _supabase.from('subjects').select(),
      'caricamento materie'
    );
    
    if (response != null) {
      _subjects = response.map((json) => Subject.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<bool> addSubject(Subject subject) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final subjectInsert = {
      'name': subject.name,
      'weekly_hours': subject.weeklyHours,
      'max_daily_hours': subject.maxDailyHours,
      'max_consecutive_hours': subject.maxConsecutiveHours,
      'prefer_consecutive': subject.preferConsecutive,
      'created_at': subject.createdAt.toIso8601String(),
      'updated_at': subject.updatedAt.toIso8601String(),
    };
    
    final response = await _handleNetworkCall(
      () => _supabase.from('subjects').insert(subjectInsert).select().single(),
      'aggiunta materia'
    );
    
    if (response != null) {
      _subjects.add(Subject.fromJson(response));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateSubject(Subject subject) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('subjects').update(subject.toJson()).eq('id', subject.id),
      'aggiornamento materia'
    );
    
    if (result != null) {
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteSubject(String id) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('subjects').delete().eq('id', id),
      'eliminazione materia'
    );
    
    if (result != null) {
      _subjects.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Add similar for classes, schedules, etc.

  Future<void> fetchClasses() async {
    final response = await _handleNetworkCall(
      () => _supabase.from('classes').select(),
      'caricamento classi'
    );
    
    if (response != null) {
      _classes = response.map((json) => ClassModel.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<bool> addClass(ClassModel classModel) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final classInsert = {
      'name': classModel.name,
      'section': classModel.section,
      'grade': classModel.grade,
      'created_at': classModel.createdAt.toIso8601String(),
      'updated_at': classModel.updatedAt.toIso8601String(),
    };
    
    final response = await _handleNetworkCall(
      () => _supabase.from('classes').insert(classInsert).select().single(),
      'aggiunta classe'
    );
    
    if (response != null) {
      _classes.add(ClassModel.fromJson(response));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateClass(ClassModel classModel) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('classes').update(classModel.toJson()).eq('id', classModel.id),
      'aggiornamento classe'
    );
    
    if (result != null) {
      final index = _classes.indexWhere((c) => c.id == classModel.id);
      if (index != -1) {
        _classes[index] = classModel;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteClass(String id) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('classes').delete().eq('id', id),
      'eliminazione classe'
    );
    
    if (result != null) {
      _classes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // For schedules and slots, similar.

  Future<void> fetchSchedules() async {
    final response = await _handleNetworkCall(
      () => _supabase.from('schedules').select(),
      'caricamento orari'
    );
    
    if (response != null) {
      _schedules = response.map((json) => Schedule.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> fetchScheduleSlots(String scheduleId) async {
    if (scheduleId.isEmpty) {
      // Fetch slots for the most recent schedule
      await fetchSchedules(); // Ensure schedules are loaded
      if (_schedules.isNotEmpty) {
        // Get the most recent schedule
        final latestSchedule = _schedules.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
        final response = await _handleNetworkCall(
          () => _supabase.from('schedule_slots').select().eq('schedule_id', latestSchedule.id),
          'caricamento slot orario'
        );
        
        if (response != null) {
          _scheduleSlots = response.map((json) => ScheduleSlot.fromJson(json)).toList();
        } else {
          _scheduleSlots = [];
        }
      } else {
        _scheduleSlots = [];
      }
    } else {
      // Fetch slots for specific schedule
      final response = await _handleNetworkCall(
        () => _supabase.from('schedule_slots').select().eq('schedule_id', scheduleId),
        'caricamento slot orario specifico'
      );
      
      if (response != null) {
        _scheduleSlots = response.map((json) => ScheduleSlot.fromJson(json)).toList();
      } else {
        _scheduleSlots = [];
      }
    }
    // Loading from backend means we have a clean state
    _isScheduleDirty = false;
    notifyListeners();
  }

  /// Persist a list of schedule slots to the database for the given schedule.
  /// If scheduleId is null, the slots' scheduleId fields are used. This will
  /// replace any existing slots for that schedule.
  Future<void> saveScheduleSlots(List<ScheduleSlot> slots, {String? scheduleId}) async {
    if (slots.isEmpty) return;
    final targetScheduleId = scheduleId ?? slots.first.scheduleId;
    if (targetScheduleId.isEmpty) return;
    try {
      // Delete existing slots for this schedule
      await _supabase.from('schedule_slots').delete().eq('schedule_id', targetScheduleId);
      _scheduleSlots.removeWhere((s) => s.scheduleId == targetScheduleId);

      // Insert provided slots
      for (final slot in slots.where((s) => s.scheduleId == targetScheduleId)) {
        final slotInsert = {
          'schedule_id': slot.scheduleId,
          'teacher_id': slot.teacherId,
          'subject_id': slot.subjectId,
          'class_id': slot.classId,
          'day_of_week': slot.dayOfWeek,
          'hour_slot': slot.hourSlot,
          'created_at': slot.createdAt.toIso8601String(),
        };
        final slotResponse = await _supabase.from('schedule_slots').insert(slotInsert).select().single();
        _scheduleSlots.add(ScheduleSlot.fromJson(slotResponse));
      }

      _isScheduleDirty = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving schedule slots: $e');
      rethrow;
    }
  }

  Future<void> fetchTeacherConstraints() async {
    final response = await _handleNetworkCall(
      () => _supabase.from('teacher_constraints').select(),
      'caricamento vincoli insegnanti'
    );
    
    if (response != null) {
      _teacherConstraints = response.map((json) => TeacherConstraint.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> fetchTeacherSubjects() async {
    final response = await _handleNetworkCall(
      () => _supabase.from('teacher_subjects').select(),
      'caricamento materie insegnanti'
    );
    
    if (response != null) {
      _teacherSubjects = response.map((json) => TeacherSubject.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<bool> addTeacherConstraint(TeacherConstraint constraint) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final constraintInsert = {
      'teacher_id': constraint.teacherId,
      'day_of_week': constraint.dayOfWeek,
      'hour_slot': constraint.hourSlot,
      'created_at': constraint.createdAt.toIso8601String(),
    };
    
    final response = await _handleNetworkCall(
      () => _supabase.from('teacher_constraints').insert(constraintInsert).select().single(),
      'aggiunta vincolo insegnante'
    );
    
    if (response != null) {
      _teacherConstraints.add(TeacherConstraint.fromJson(response));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteTeacherConstraint(String id) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('teacher_constraints').delete().eq('id', id),
      'eliminazione vincolo insegnante'
    );
    
    if (result != null) {
      _teacherConstraints.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addTeacherSubject(TeacherSubject teacherSubject) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final teacherSubjectInsert = {
      'teacher_id': teacherSubject.teacherId,
      'subject_id': teacherSubject.subjectId,
      'class_id': teacherSubject.classId,
      'created_at': teacherSubject.createdAt.toIso8601String(),
    };
    
    final response = await _handleNetworkCall(
      () => _supabase.from('teacher_subjects').insert(teacherSubjectInsert).select().single(),
      'aggiunta materia insegnante'
    );
    
    if (response != null) {
      _teacherSubjects.add(TeacherSubject.fromJson(response));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteTeacherSubject(String id) async {
    final result = await _handleNetworkCall(
      () => _supabase.from('teacher_subjects').delete().eq('id', id),
      'eliminazione materia insegnante'
    );
    
    if (result != null) {
      _teacherSubjects.removeWhere((ts) => ts.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> generateScheduleForClass(String classId) async {
    try {
      // 1. Create a new schedule for the class
      final now = DateTime.now();
      final scheduleInsert = {
        'name': 'Generated Schedule for Class ${now.millisecondsSinceEpoch}',
        // Use seconds-since-epoch to fit Postgres 32-bit integer
        'generation_seed': now.millisecondsSinceEpoch ~/ 1000,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final scheduleResponse = await _supabase.from('schedules').insert(scheduleInsert).select().single();
      final newSchedule = Schedule.fromJson(scheduleResponse);
      _schedules.add(newSchedule);

      // 2. Ensure data is loaded
      await fetchTeacherSubjects();
      await fetchTeacherConstraints();
      await fetchSubjects();
      await fetchTeachers();

      // 3. Generate schedule slots using intelligent algorithm scoped to this class
      final List<ScheduleSlot> generatedSlots = await _generateIntelligentSchedule(
        scheduleId: newSchedule.id,
        classId: classId,
      );

  // 4. Save slots to database
      for (final slot in generatedSlots) {
        final slotInsert = {
          'schedule_id': slot.scheduleId,
          'teacher_id': slot.teacherId,
          'subject_id': slot.subjectId,
          'class_id': slot.classId,
          'day_of_week': slot.dayOfWeek,
          'hour_slot': slot.hourSlot,
          'created_at': slot.createdAt.toIso8601String(),
        };
        final slotResponse = await _supabase.from('schedule_slots').insert(slotInsert).select().single();
        _scheduleSlots.add(ScheduleSlot.fromJson(slotResponse));
      }

  // After successful save the schedule is clean
  _isScheduleDirty = false;
  notifyListeners();
    } catch (e) {
      debugPrint('Error generating schedule: $e');
      rethrow;
    }
  }

  Future<List<ScheduleSlot>> _generateIntelligentSchedule({
    required String scheduleId,
    required String classId,
    int maxVarHours = 6,
    bool autoBreakEnabled = false,
  }) async {
    final List<ScheduleSlot> slots = [];
    final Map<String, int> teacherHoursPerWeek = _teacherWeeklyHours; // shared across classes
    final Map<String, Set<String>> teacherBlockedSlots = {};

    // Initialize teacher constraints
    for (final constraint in _teacherConstraints) {
      final slotKey = '${constraint.dayOfWeek}-${constraint.hourSlot}';
      teacherBlockedSlots.putIfAbsent(constraint.teacherId, () => <String>{}).add(slotKey);
    }

    // Track teacher hours per week
    for (final teacher in _teachers) {
      teacherHoursPerWeek.putIfAbsent(teacher.id, () => 0);
    }

    // Filter teacher-subjects for this class and shuffle
    final classTeacherSubjects = _teacherSubjects.where((ts) => ts.classId == classId).toList()
      ..shuffle();

    // Quick access to subjects data
    final Map<String, Subject> subjectById = {for (final s in _subjects) s.id: s};

    // Per-class occupancy to avoid double booking the same class slot
    final Set<String> classOccupiedSlots = <String>{}; // 'day-hour'

    // Per-subject daily count for this class to respect max_daily_hours
    final Map<String, Map<int, int>> subjectDailyCount = {}; // subjectId -> {day -> count}

    bool canPlace({
      required String teacherId,
      required int day,
      required int hour,
      required String subjectId,
    }) {
      final key = '$day-$hour';
      if (classOccupiedSlots.contains(key)) return false;
      if (_teacherBusySlots[teacherId]?.contains(key) ?? false) return false;
      if (teacherBlockedSlots[teacherId]?.contains(key) ?? false) return false;
      if ((teacherHoursPerWeek[teacherId] ?? 0) >= 18) return false;
      // Enforce max variable hours per day for this teacher
      // Count both slots already placed for this class and global busy slots for the teacher
      int teacherCurrentDayCount = 0;
      for (final s in slots) {
        if (s.teacherId == teacherId && s.dayOfWeek == day) teacherCurrentDayCount++;
      }
      if (_teacherBusySlots.containsKey(teacherId)) {
        for (final busy in _teacherBusySlots[teacherId]!) {
          final parts = busy.split('-');
          if (parts.length >= 1) {
            final d = int.tryParse(parts[0]) ?? 0;
            if (d == day) teacherCurrentDayCount++;
          }
        }
      }
      if (teacherCurrentDayCount >= maxVarHours) return false;

      // If auto-break is enabled, avoid placing more than 2 consecutive hours for a teacher
      if (autoBreakEnabled) {
        bool hasTeacherAtHour(String teacherId, int day, int h) {
          final inSlots = slots.any((ss) => ss.teacherId == teacherId && ss.dayOfWeek == day && ss.hourSlot == h);
          final inBusy = _teacherBusySlots[teacherId]?.contains('$day-$h') ?? false;
          return inSlots || inBusy;
        }

        int consecutiveBefore = 0;
        int h = hour - 1;
        while (h >= 1 && consecutiveBefore < 2) {
          if (hasTeacherAtHour(teacherId, day, h)) { consecutiveBefore++; h--; continue; }
          break;
        }
        int consecutiveAfter = 0;
        h = hour + 1;
        while (h <= 6 && consecutiveAfter < 2) {
          if (hasTeacherAtHour(teacherId, day, h)) { consecutiveAfter++; h++; continue; }
          break;
        }
        if ((consecutiveBefore + consecutiveAfter) >= 2) return false;
      }
      final subj = subjectById[subjectId];
      if (subj == null) return false;
      final perDay = subjectDailyCount.putIfAbsent(subjectId, () => {});
      final currentDayCount = perDay[day] ?? 0;
  if (currentDayCount >= subj.maxDailyHours) return false;
      return true;
    }

    void place({
      required TeacherSubject ts,
      required int day,
      required int hour,
    }) {
      final key = '$day-$hour';
      slots.add(ScheduleSlot(
        id: '',
        scheduleId: scheduleId,
        teacherId: ts.teacherId,
        subjectId: ts.subjectId,
        classId: classId,
        dayOfWeek: day,
        hourSlot: hour,
        createdAt: DateTime.now(),
      ));
      classOccupiedSlots.add(key);
      _teacherBusySlots.putIfAbsent(ts.teacherId, () => <String>{}).add(key);
      teacherHoursPerWeek[ts.teacherId] = (teacherHoursPerWeek[ts.teacherId] ?? 0) + 1;
      final perDay = subjectDailyCount.putIfAbsent(ts.subjectId, () => {});
      perDay[day] = (perDay[day] ?? 0) + 1;
    }

    for (final ts in classTeacherSubjects) {
      final subj = subjectById[ts.subjectId];
      if (subj == null) continue;
      int remaining = subj.weeklyHours;
      
      // Yield to UI thread occasionally during heavy computation
      await Future.delayed(Duration.zero);
      
      // Try to place hours, favor consecutive blocks if requested
      for (int day = 1; day <= 5 && remaining > 0; day++) {
  if (subj.preferConsecutive && remaining > 1) {
          // Attempt consecutive placement up to max_consecutive_hours
          final maxRun = subj.maxConsecutiveHours.clamp(1, 6);
          for (int hour = 1; hour <= 6 && remaining > 0; hour++) {
            // Try largest possible run first
            int tryLen = remaining.clamp(1, maxRun);
            bool placedRun = false;
            while (tryLen > 1 && !placedRun) {
              if (hour + tryLen - 1 <= 6) {
                bool allFit = true;
                for (int h = hour; h < hour + tryLen; h++) {
                  if (!canPlace(teacherId: ts.teacherId, day: day, hour: h, subjectId: ts.subjectId)) {
                    allFit = false; break;
                  }
                }
                final perDay = subjectDailyCount.putIfAbsent(ts.subjectId, () => {});
                final currentDayCount = perDay[day] ?? 0;
                if (allFit && (currentDayCount + tryLen <= subj.maxDailyHours)) {
                  for (int h = hour; h < hour + tryLen; h++) {
                    place(ts: ts, day: day, hour: h);
                    remaining--;
                  }
                  placedRun = true;
                }
              }
              tryLen--;
            }
            // If we placed a run, advance hour accordingly
            if (placedRun) {
              hour += 5; // break out of hour loop for this day
            }
          }
        }
        // Fallback or continue placing single hours
        for (int hour = 1; hour <= 6 && remaining > 0; hour++) {
          if (canPlace(teacherId: ts.teacherId, day: day, hour: hour, subjectId: ts.subjectId)) {
            place(ts: ts, day: day, hour: hour);
            remaining--;
          }
        }
      }
    }

    return slots;
  }

  List<ScheduleSlot> _distributeInstituteExtraHours({
    required String scheduleId,
    int maxVarHours = 6,
    bool autoBreakEnabled = false,
  }) {
    final List<ScheduleSlot> extraSlots = [];
    
    // Create a list of teachers who have extra hours to distribute
    final List<Teacher> teachersWithExtraHours = _teachers
        .where((teacher) => teacher.extraHours > 0)
        .toList();

    if (teachersWithExtraHours.isEmpty) return extraSlots;

    // Initialize teacher constraints
    final Map<String, Set<String>> teacherBlockedSlots = {};
    for (final constraint in _teacherConstraints) {
      final slotKey = '${constraint.dayOfWeek}-${constraint.hourSlot}';
      teacherBlockedSlots.putIfAbsent(constraint.teacherId, () => <String>{}).add(slotKey);
    }

    // Shuffle for fair distribution
    teachersWithExtraHours.shuffle();

    for (final teacher in teachersWithExtraHours) {
      int extraHoursToPlace = teacher.extraHours;
      final currentWeeklyHours = _teacherWeeklyHours[teacher.id] ?? 0;

      // The teacher should not exceed their normal weekly commitment (18 hours) + extra hours
      final maxTotalHours = 18 + teacher.extraHours;
      final remainingCapacity = maxTotalHours - currentWeeklyHours;
      
      // Only place the actual extra hours they have, not more
      extraHoursToPlace = extraHoursToPlace.clamp(0, remainingCapacity.clamp(0, teacher.extraHours));

      // Try to place extra hours across the week
      for (int day = 1; day <= 5 && extraHoursToPlace > 0; day++) {
        for (int hour = 1; hour <= 6 && extraHoursToPlace > 0; hour++) {
          if (_canPlaceInstituteExtraHour(
            teacherId: teacher.id,
            day: day,
            hour: hour,
            teacherBlockedSlots: teacherBlockedSlots,
            maxVarHours: maxVarHours,
            autoBreakEnabled: autoBreakEnabled,
          )) {
            // Place the extra hour - use "Extra" class for extra hours
            final extraSlot = ScheduleSlot(
              id: '',
              scheduleId: scheduleId,
              teacherId: teacher.id,
              subjectId: _getOrCreateSupportSubjectId(), // Special subject for extra hours
              classId: _getOrCreateExtraClassId(), // Special "Extra" class for extra hours
              dayOfWeek: day,
              hourSlot: hour,
              createdAt: DateTime.now(),
            );

            extraSlots.add(extraSlot);
            _teacherBusySlots.putIfAbsent(teacher.id, () => <String>{}).add('$day-$hour');
            _teacherWeeklyHours[teacher.id] = (_teacherWeeklyHours[teacher.id] ?? 0) + 1;
            extraHoursToPlace--;
          }
        }
      }
    }
    
    return extraSlots;
  }

  bool _canPlaceInstituteExtraHour({
    required String teacherId,
    required int day,
    required int hour,
    required Map<String, Set<String>> teacherBlockedSlots,
    int maxVarHours = 6,
    bool autoBreakEnabled = false,
  }) {
    final key = '$day-$hour';
    
  // Check if the teacher is already busy at this time (institute-wide)
    if (_teacherBusySlots[teacherId]?.contains(key) ?? false) return false;
    
    // Check teacher constraints (blocked slots)
    if (teacherBlockedSlots[teacherId]?.contains(key) ?? false) return false;

    // Enforce per-day max variable hours
    int currentDayCount = 0;
    if (_teacherBusySlots.containsKey(teacherId)) {
      for (final s in _teacherBusySlots[teacherId]!) {
        final parts = s.split('-');
        if (parts.length == 2) {
          final d = int.tryParse(parts[0]) ?? 0;
          if (d == day) currentDayCount++;
        }
      }
    }
    if (currentDayCount >= maxVarHours) return false;

    // If autoBreakEnabled enforce not more than 2 consecutive hours
    if (autoBreakEnabled) {
      int consec = 0;
      // check before
      for (int h = hour - 1; h >= 1 && consec < 2; h--) {
        if (_teacherBusySlots[teacherId]?.contains('$day-$h') ?? false) consec++; else break;
      }
      // check after
      for (int h = hour + 1; h <= 6 && consec < 2; h++) {
        if (_teacherBusySlots[teacherId]?.contains('$day-$h') ?? false) consec++; else break;
      }
      if (consec >= 2) return false;
    }

    // Additional check: ensure teacher doesn't exceed weekly limit
    final currentWeeklyHours = _teacherWeeklyHours[teacherId] ?? 0;
    final teacher = _teachers.firstWhere((t) => t.id == teacherId, orElse: () => throw Exception('Teacher not found'));
    final maxAllowedHours = 18 + teacher.extraHours;
    
    if (currentWeeklyHours >= maxAllowedHours) return false;

    return true;
  }

  String _getOrCreateSupportSubjectId() {
    // Try to find an existing "Support" or "Extra" subject
    try {
      final existingSupport = _subjects.firstWhere((s) => 
          s.name.toLowerCase().contains('support') || 
          s.name.toLowerCase().contains('extra') ||
          s.name.toLowerCase().contains('supplenza') ||
          s.name.toLowerCase().contains('sostegno') ||
          s.name.toLowerCase().contains('ora libera')
      );
      return existingSupport.id;
    } catch (_) {
      // If no support subject exists, use the first available subject as fallback
      // In a real implementation, you might want to create a dedicated "Supplenza" subject
      return _subjects.isNotEmpty ? _subjects.first.id : '';
    }
  }

  // Helper method to create a support subject if needed (for future enhancement)
  String _getOrCreateExtraClassId() {
    // Try to find an existing "Extra" class
    try {
      final existingExtra = _classes.firstWhere((c) => 
          c.name.toLowerCase() == 'extra' ||
          c.name.toLowerCase().contains('extra') ||
          c.name.toLowerCase().contains('supplenza')
      );
      return existingExtra.id;
    } catch (_) {
      // If no "Extra" class exists, use the first available class as fallback
      // In a real implementation, you might want to create a dedicated "Extra" class
      return _classes.isNotEmpty ? _classes.first.id : '';
    }
  }

  Future<bool> clearAllSchedules() async {
    // Delete all schedule slots first
    final slotsResult = await _handleNetworkCall(
      () => _supabase.from('schedule_slots').delete().not('id', 'is', null),
      'cancellazione slot orario'
    );
    
    if (slotsResult == null) return false;
    
    // Delete all schedules
    final schedulesResult = await _handleNetworkCall(
      () => _supabase.from('schedules').delete().not('id', 'is', null),
      'cancellazione orari'
    );
    
    if (schedulesResult != null) {
      _scheduleSlots.clear();
      _schedules.clear();
      // Clearing server state resets local dirty flag
      _isScheduleDirty = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String> generateInstituteSchedule() async {
    return generateInstituteScheduleWithProgress(null);
  }

  Future<String> generateInstituteScheduleWithProgress(Function(double)? onProgress, {int? maxVariableHours, bool? autoBreakEnabled}) async {
    try {
      // Fetch all necessary data
  await fetchClasses();
  await fetchTeacherSubjects();
  await fetchTeacherConstraints();
  await fetchTeachers();
  await fetchSubjects();

  // Reset institute-wide busy maps
  _teacherBusySlots.clear();
  _teacherWeeklyHours.clear();

  if (onProgress != null) onProgress(0.1); // 10% progress

      // Create a NEW schedule for the institute every time
      final now = DateTime.now();
      final newSchedule = Schedule(
        id: '', // Temporary empty ID, will be set from DB response
        name: 'Orario Istituto ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}',
        generationSeed: now.millisecondsSinceEpoch ~/ 1000,
        createdAt: now,
        updatedAt: now,
      );

      final masterScheduleResponse = await _supabase.from('schedules').insert(newSchedule.toInsertJson()).select().single();
      final masterSchedule = Schedule.fromJson(masterScheduleResponse);
      _schedules.add(masterSchedule);

      // Clear any existing slots for this schedule (fresh start)
      await _supabase.from('schedule_slots').delete().eq('schedule_id', masterSchedule.id);
      _scheduleSlots.removeWhere((slot) => slot.scheduleId == masterSchedule.id);

  if (onProgress != null) onProgress(0.2); // 20% progress

      // Respect generation settings passed by caller (defaults below)
      final int maxPerDay = maxVariableHours ?? 6;
      final bool enforceAutoBreak = autoBreakEnabled ?? false;

      // Generate schedule for each class and associate with the NEW schedule
      final totalClasses = _classes.length;
      for (int i = 0; i < _classes.length; i++) {
        final classModel = _classes[i];
        
        // Yield to UI thread periodically
        if (i % 2 == 0) {
          await Future.delayed(Duration(milliseconds: 10));
          if (onProgress != null) {
            onProgress(0.2 + (i / totalClasses) * 0.6); // 20% to 80% for class generation
          }
        }
        
        final List<ScheduleSlot> generatedSlots = await _generateIntelligentSchedule(
          scheduleId: masterSchedule.id,
          classId: classModel.id,
          maxVarHours: maxPerDay,
          autoBreakEnabled: enforceAutoBreak,
        );

        // Save slots to database
        for (final slot in generatedSlots) {
          final slotInsert = {
            'schedule_id': slot.scheduleId,
            'teacher_id': slot.teacherId,
            'subject_id': slot.subjectId,
            'class_id': slot.classId,
            'day_of_week': slot.dayOfWeek,
            'hour_slot': slot.hourSlot,
            'created_at': slot.createdAt.toIso8601String(),
          };
          final slotResponse = await _supabase.from('schedule_slots').insert(slotInsert).select().single();
          _scheduleSlots.add(ScheduleSlot.fromJson(slotResponse));
        }
      }
      
  if (onProgress != null) onProgress(0.85); // 85% progress
  
      // AFTER all regular class schedules are generated, distribute extra hours ONCE
      final List<ScheduleSlot> extraHoursSlots = _distributeInstituteExtraHours(
        scheduleId: masterSchedule.id,
        maxVarHours: maxPerDay,
        autoBreakEnabled: enforceAutoBreak,
      );
      
      // Save extra hours slots to database
      for (final slot in extraHoursSlots) {
        final slotInsert = {
          'schedule_id': slot.scheduleId,
          'teacher_id': slot.teacherId,
          'subject_id': slot.subjectId,
          'class_id': slot.classId,
          'day_of_week': slot.dayOfWeek,
          'hour_slot': slot.hourSlot,
          'created_at': slot.createdAt.toIso8601String(),
        };
        final slotResponse = await _supabase.from('schedule_slots').insert(slotInsert).select().single();
        _scheduleSlots.add(ScheduleSlot.fromJson(slotResponse));
      }
      
  if (onProgress != null) onProgress(1.0); // 100% progress
  
  // Newly generated schedule was saved to DB -> clean
  _isScheduleDirty = false;
  notifyListeners();
  return masterSchedule.id;
    } catch (e) {
      debugPrint('Error generating institute schedule: $e');
      rethrow;
    }
  }

  Future<void> clearScheduleForClass(String classId) async {
    try {
      // Delete schedule slots for specific class
      await _supabase.from('schedule_slots').delete().eq('class_id', classId);
      _scheduleSlots.removeWhere((slot) => slot.classId == classId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing schedule for class: $e');
      rethrow;
    }
  }

  Future<void> loadSchedule(String scheduleId) async {
    try {
      // Clear current schedule slots
      _scheduleSlots.clear();
      
      // Load schedule slots for the specific schedule
      await fetchScheduleSlots(scheduleId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      rethrow;
    }
  }

  List<Schedule> getSavedSchedules() {
    // Return all schedules, sorted by creation date (newest first)
    return _schedules.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Schedule? getCurrentSchedule() {
    if (_schedules.isEmpty) return null;
    return _schedules.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  Future<void> deleteSavedSchedule(String scheduleId) async {
    try {
      // Delete schedule slots
      await _supabase.from('schedule_slots').delete().eq('schedule_id', scheduleId);
      _scheduleSlots.removeWhere((slot) => slot.scheduleId == scheduleId);
      
      // Delete schedule
      await _supabase.from('schedules').delete().eq('id', scheduleId);
      _schedules.removeWhere((s) => s.id == scheduleId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting saved schedule: $e');
      rethrow;
    }
  }

  Future<void> updateScheduleName(String scheduleId, String newName) async {
    try {
      await _supabase.from('schedules').update({
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', scheduleId);
      
      // Update local cache
      final index = _schedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        _schedules[index] = _schedules[index].copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating schedule name: $e');
      rethrow;
    }
  }
}
