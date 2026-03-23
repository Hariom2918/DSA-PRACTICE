import 'package:hive_flutter/hive_flutter.dart';

import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/note_model.dart';
import '../models/focus_session_model.dart';
import '../models/user_settings_model.dart';

class YamadaDatabase {
  static const String tasksBoxName = 'tasks';
  static const String habitsBoxName = 'habits';
  static const String notesBoxName = 'notes';
  static const String focusBoxName = 'focus_sessions';
  static const String settingsBoxName = 'user_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(FocusSessionModelAdapter());
    Hive.registerAdapter(UserSettingsModelAdapter());

    // Open Boxes
    await Hive.openBox<TaskModel>(tasksBoxName);
    await Hive.openBox<HabitModel>(habitsBoxName);
    await Hive.openBox<NoteModel>(notesBoxName);
    await Hive.openBox<FocusSessionModel>(focusBoxName);
    await Hive.openBox<UserSettingsModel>(settingsBoxName);

    // Initialize default UserSettings if empty
    final settingsBox = Hive.box<UserSettingsModel>(settingsBoxName);
    if (settingsBox.isEmpty) {
      await settingsBox.put('default', UserSettingsModel());
    }
  }

  // == REPOSITORIES == // 

  // Tasks
  static Box<TaskModel> get tasksBox => Hive.box<TaskModel>(tasksBoxName);
  
  static Future<void> addTask(TaskModel task) async {
    await tasksBox.put(task.id, task);
  }

  static Future<void> updateTask(TaskModel task) async {
    await tasksBox.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await tasksBox.delete(id);
  }

  static List<TaskModel> getAllTasks() {
    return tasksBox.values.where((t) => !t.isArchived).toList();
  }

  static List<TaskModel> getArchivedTasks() {
    return tasksBox.values.where((t) => t.isArchived).toList();
  }

  // Habits
  static Box<HabitModel> get habitsBox => Hive.box<HabitModel>(habitsBoxName);

  static Future<void> addHabit(HabitModel habit) async {
    await habitsBox.put(habit.id, habit);
  }

  static Future<void> updateHabit(HabitModel habit) async {
    await habitsBox.put(habit.id, habit);
  }

  static Future<void> deleteHabit(String id) async {
    await habitsBox.delete(id);
  }

  static List<HabitModel> getAllHabits() {
    return habitsBox.values.toList();
  }

  // Notes
  static Box<NoteModel> get notesBox => Hive.box<NoteModel>(notesBoxName);

  static Future<void> addNote(NoteModel note) async {
    await notesBox.put(note.id, note);
  }

  static Future<void> updateNote(NoteModel note) async {
    await notesBox.put(note.id, note);
  }

  static Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
  }

  static List<NoteModel> getAllNotes() {
    return notesBox.values.toList();
  }

  // Focus Sessions
  static Box<FocusSessionModel> get focusBox => Hive.box<FocusSessionModel>(focusBoxName);

  static Future<void> addFocusSession(FocusSessionModel session) async {
    await focusBox.put(session.id, session);
  }

  static List<FocusSessionModel> getAllFocusSessions() {
    return focusBox.values.toList();
  }

  // User Settings
  static Box<UserSettingsModel> get settingsBox => Hive.box<UserSettingsModel>(settingsBoxName);

  static UserSettingsModel getUserSettings() {
    return settingsBox.get('default') ?? UserSettingsModel();
  }

  static Future<void> updateUserSettings(UserSettingsModel settings) async {
    await settingsBox.put('default', settings);
  }
}
