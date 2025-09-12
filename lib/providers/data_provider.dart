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
  List<ClassModel> _classes = [];
  List<Schedule> _schedules = [];
  List<ScheduleSlot> _scheduleSlots = [];
  List<TeacherSubject> _teacherSubjects = [];
  List<TeacherConstraint> _teacherConstraints = [];

  // Track institute-wide teacher busy slots and weekly hours to avoid clashes across classes
  final Map<String, Set<String>> _teacherBusySlots = {}; // teacherId -> set of 'day-hour'
  final Map<String, int> _teacherWeeklyHours = {}; // teacherId -> hours scheduled this week

  List<Teacher> get teachers => _teachers;
  List<Subject> get subjects => _subjects;
  List<ClassModel> get classes => _classes;
  List<Schedule> get schedules => _schedules;
  List<ScheduleSlot> get scheduleSlots => _scheduleSlots;
  List<TeacherSubject> get teacherSubjects => _teacherSubjects;
  List<TeacherConstraint> get teacherConstraints => _teacherConstraints;

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
    final response = await _supabase.from('teachers').select();
    _teachers = response.map((json) => Teacher.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> addTeacher(Teacher teacher) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final teacherInsert = {
      'name': teacher.name,
      'email': teacher.email,
      'created_at': teacher.createdAt.toIso8601String(),
      'updated_at': teacher.updatedAt.toIso8601String(),
    };
    final response = await _supabase.from('teachers').insert(teacherInsert).select().single();
    _teachers.add(Teacher.fromJson(response));
    notifyListeners();
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await _supabase.from('teachers').update(teacher.toJson()).eq('id', teacher.id);
    final index = _teachers.indexWhere((t) => t.id == teacher.id);
    if (index != -1) {
      _teachers[index] = teacher;
      notifyListeners();
    }
  }

  Future<void> deleteTeacher(String id) async {
    await _supabase.from('teachers').delete().eq('id', id);
    _teachers.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Similar methods for subjects, classes, etc.

  Future<void> fetchSubjects() async {
    final response = await _supabase.from('subjects').select();
    _subjects = response.map((json) => Subject.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> addSubject(Subject subject) async {
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
    final response = await _supabase.from('subjects').insert(subjectInsert).select().single();
    _subjects.add(Subject.fromJson(response));
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    await _supabase.from('subjects').update(subject.toJson()).eq('id', subject.id);
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      notifyListeners();
    }
  }

  Future<void> deleteSubject(String id) async {
    await _supabase.from('subjects').delete().eq('id', id);
    _subjects.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Add similar for classes, schedules, etc.

  Future<void> fetchClasses() async {
    final response = await _supabase.from('classes').select();
    _classes = response.map((json) => ClassModel.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> addClass(ClassModel classModel) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final classInsert = {
      'name': classModel.name,
      'section': classModel.section,
      'grade': classModel.grade,
      'created_at': classModel.createdAt.toIso8601String(),
      'updated_at': classModel.updatedAt.toIso8601String(),
    };
    final response = await _supabase.from('classes').insert(classInsert).select().single();
    _classes.add(ClassModel.fromJson(response));
    notifyListeners();
  }

  Future<void> updateClass(ClassModel classModel) async {
    await _supabase.from('classes').update(classModel.toJson()).eq('id', classModel.id);
    final index = _classes.indexWhere((c) => c.id == classModel.id);
    if (index != -1) {
      _classes[index] = classModel;
      notifyListeners();
    }
  }

  Future<void> deleteClass(String id) async {
    await _supabase.from('classes').delete().eq('id', id);
    _classes.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // For schedules and slots, similar.

  Future<void> fetchSchedules() async {
    final response = await _supabase.from('schedules').select();
    _schedules = response.map((json) => Schedule.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> fetchScheduleSlots(String scheduleId) async {
    if (scheduleId.isEmpty) {
      // Fetch slots for the most recent schedule
      await fetchSchedules(); // Ensure schedules are loaded
      if (_schedules.isNotEmpty) {
        // Get the most recent schedule
        final latestSchedule = _schedules.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
        final response = await _supabase.from('schedule_slots').select().eq('schedule_id', latestSchedule.id);
        _scheduleSlots = response.map((json) => ScheduleSlot.fromJson(json)).toList();
      } else {
        _scheduleSlots = [];
      }
    } else {
      // Fetch slots for specific schedule
      final response = await _supabase.from('schedule_slots').select().eq('schedule_id', scheduleId);
      _scheduleSlots = response.map((json) => ScheduleSlot.fromJson(json)).toList();
    }
  // Loading from backend means we have a clean state
  _isScheduleDirty = false;
  notifyListeners();
  }

  Future<void> fetchTeacherConstraints() async {
    final response = await _supabase.from('teacher_constraints').select();
    _teacherConstraints = response.map((json) => TeacherConstraint.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> fetchTeacherSubjects() async {
    final response = await _supabase.from('teacher_subjects').select();
    _teacherSubjects = response.map((json) => TeacherSubject.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> addTeacherConstraint(TeacherConstraint constraint) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final constraintInsert = {
      'teacher_id': constraint.teacherId,
      'day_of_week': constraint.dayOfWeek,
      'hour_slot': constraint.hourSlot,
      'created_at': constraint.createdAt.toIso8601String(),
    };
    final response = await _supabase.from('teacher_constraints').insert(constraintInsert).select().single();
    _teacherConstraints.add(TeacherConstraint.fromJson(response));
    notifyListeners();
  }

  Future<void> deleteTeacherConstraint(String id) async {
    await _supabase.from('teacher_constraints').delete().eq('id', id);
    _teacherConstraints.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> addTeacherSubject(TeacherSubject teacherSubject) async {
    // Create JSON without id for new records (let Supabase generate UUID)
    final teacherSubjectInsert = {
      'teacher_id': teacherSubject.teacherId,
      'subject_id': teacherSubject.subjectId,
      'class_id': teacherSubject.classId,
      'created_at': teacherSubject.createdAt.toIso8601String(),
    };
    final response = await _supabase.from('teacher_subjects').insert(teacherSubjectInsert).select().single();
    _teacherSubjects.add(TeacherSubject.fromJson(response));
    notifyListeners();
  }

  Future<void> deleteTeacherSubject(String id) async {
    await _supabase.from('teacher_subjects').delete().eq('id', id);
    _teacherSubjects.removeWhere((ts) => ts.id == id);
    notifyListeners();
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
      final List<ScheduleSlot> generatedSlots = _generateIntelligentSchedule(
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
      print('Error generating schedule: $e');
      rethrow;
    }
  }

  List<ScheduleSlot> _generateIntelligentSchedule({
    required String scheduleId,
    required String classId,
  }) {
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

  Future<void> clearAllSchedules() async {
    try {
  // Delete all schedule slots (PostgREST requires a filter)
  // Use a safe filter that matches all rows: id IS NOT NULL
  await _supabase.from('schedule_slots').delete().not('id', 'is', null);
      _scheduleSlots.clear();
      
  // Delete all schedules
  await _supabase.from('schedules').delete().not('id', 'is', null);
      _schedules.clear();
  // Clearing server state resets local dirty flag
  _isScheduleDirty = false;
  notifyListeners();
    } catch (e) {
      print('Error clearing all schedules: $e');
      rethrow;
    }
  }

  Future<String> generateInstituteSchedule() async {
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

      // Generate schedule for each class and associate with the NEW schedule
      for (final classModel in _classes) {
        final List<ScheduleSlot> generatedSlots = _generateIntelligentSchedule(
          scheduleId: masterSchedule.id,
          classId: classModel.id,
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
      
  // Newly generated schedule was saved to DB -> clean
  _isScheduleDirty = false;
  notifyListeners();
  return masterSchedule.id;
    } catch (e) {
      print('Error generating institute schedule: $e');
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
      print('Error clearing schedule for class: $e');
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
      print('Error loading schedule: $e');
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
      print('Error deleting saved schedule: $e');
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
      print('Error updating schedule name: $e');
      rethrow;
    }
  }
}
