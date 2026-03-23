import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_database.dart';
import '../models/user_settings_model.dart';
import '../models/habit_model.dart';
import '../theme/yamada_theme.dart';
import 'app_shell.dart';

/// 3-screen onboarding: name, wake/sleep times, preset habits.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: Name
  final _nameController = TextEditingController();

  // Page 2: Wake/Sleep
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);

  // Page 3: Preset habits
  final List<String> _presets = [
    'WORKOUT',
    'READ 30 MIN',
    'MEDITATE',
    'COLD SHOWER',
    'NO PHONE FIRST HOUR',
    'JOURNAL',
    'DRINK 3L WATER',
    'SLEEP BY 11 PM',
  ];
  final Set<int> _selectedPresets = {};

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _nameController.text.trim().isEmpty
        ? 'OPERATIVE'
        : _nameController.text.trim().toUpperCase();

    await prefs.setString('yamada_username', name);
    await prefs.setBool('yamada_onboarding_done', true);
    await prefs.setString(
        'yamada_wake_time', '${_wakeTime.hour}:${_wakeTime.minute.toString().padLeft(2, '0')}');
    await prefs.setString(
        'yamada_sleep_time', '${_sleepTime.hour}:${_sleepTime.minute.toString().padLeft(2, '0')}');

    if (!mounted) return;

    // Save user settings to DB
    final settings = UserSettingsModel(
      name: name,
      wakeTime: '${_wakeTime.hour}:${_wakeTime.minute.toString().padLeft(2, '0')}',
      sleepTime: '${_sleepTime.hour}:${_sleepTime.minute.toString().padLeft(2, '0')}',
      onboardingDone: true,
      focusCustomDuration: 25,
      soundMode: 'SILENCE',
    );
    await YamadaDatabase.updateUserSettings(settings);

    // Create selected preset habits
    for (final idx in _selectedPresets) {
      final habit = HabitModel(
        id: const Uuid().v4(),
        title: _presets[idx],
        frequency: 'daily',
        priority: 'standard',
        createdAt: DateTime.now(),
      );
      await YamadaDatabase.addHabit(habit);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? YamadaTheme.ink
                        : YamadaTheme.ink.withValues(alpha: 0.3),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildNamePage(), _buildTimePage(), _buildHabitsPage()],
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _nextPage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  color: YamadaTheme.ink,
                  alignment: Alignment.center,
                  child: Text(
                    _currentPage == 2 ? 'BEGIN' : 'NEXT',
                    style: YamadaTheme.bodyBold.copyWith(
                      color: YamadaTheme.crimson,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IDENTIFY\nYOURSELF.', style: YamadaTheme.heading1),
          const SizedBox(height: 8),
          Text('WHAT DO THEY CALL YOU?',
              style: YamadaTheme.sectionLabel.copyWith(color: YamadaTheme.inkLight)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: YamadaTheme.heading3,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'YOUR NAME',
              hintStyle: YamadaTheme.heading3.copyWith(color: YamadaTheme.inkGhost),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: YamadaTheme.ink, width: 3),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: YamadaTheme.ink, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SET YOUR\nBATTLE HOURS.', style: YamadaTheme.heading1),
          const SizedBox(height: 8),
          Text('NOTIFICATIONS ONLY DURING WAKING HOURS',
              style: YamadaTheme.sectionLabel.copyWith(color: YamadaTheme.inkLight)),
          const SizedBox(height: 32),
          _timeRow('WAKE TIME', _wakeTime, (t) => setState(() => _wakeTime = t)),
          const SizedBox(height: 16),
          _timeRow('SLEEP TIME', _sleepTime, (t) => setState(() => _sleepTime = t)),
        ],
      ),
    );
  }

  Widget _timeRow(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: YamadaTheme.hardBorder),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: YamadaTheme.sectionLabel),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: YamadaTheme.dataLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('ARM\nYOURSELF.', style: YamadaTheme.heading1),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('SELECT STARTING HABITS',
                style: YamadaTheme.sectionLabel.copyWith(color: YamadaTheme.inkLight)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _presets.length,
              itemBuilder: (context, i) {
                final selected = _selectedPresets.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedPresets.remove(i);
                    } else {
                      _selectedPresets.add(i);
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? YamadaTheme.ink : null,
                      border: YamadaTheme.hardBorder,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? YamadaTheme.crimson : YamadaTheme.ink,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? Icon(Icons.check, size: 16,
                                  color: YamadaTheme.crimson)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _presets[i],
                          style: YamadaTheme.bodyBold.copyWith(
                            color: selected ? YamadaTheme.crimson : YamadaTheme.ink,
                          ),
                        ),
                      ],
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
}
