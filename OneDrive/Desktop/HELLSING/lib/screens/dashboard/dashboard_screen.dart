import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/hive_database.dart';
import '../../services/gamification_service.dart';
import '../../theme/yamada_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/heatmap.dart';
import '../../widgets/xp_bar.dart';
import '../../widgets/identity_score.dart';
import '../../widgets/stats_row.dart';
import '../../widgets/hero_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalXp = 0;
  int _level = 1;
  double _levelProgress = 0;
  int _streak = 0;
  double _identityScore = 0;
  String _username = 'OPERATIVE';
  bool _isEditingUsername = false;
  late TextEditingController _usernameController;
  Map<DateTime, double> _heatmapData = {};

  String _quote = 'STAY LOCKED.';
  String? _heroImagePath;
  bool _isEditingQuote = false;
  late TextEditingController _quoteController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _username);
    _quoteController = TextEditingController(text: _quote);
    _loadData();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('yamada_username') ?? 'OPERATIVE';
      _usernameController.text = _username;
      _quote = prefs.getString('yamada_quote') ?? 'STAY LOCKED.';
      _heroImagePath = prefs.getString('yamada_hero_image');
      _quoteController.text = _quote;
    });
  }

  Future<void> _loadData() async {
    final gamification = GamificationService();

    final xp = await gamification.getTotalXp();
    final level = GamificationService.levelFromXp(xp);
    final progress = GamificationService.levelProgress(xp);
    final streak = await gamification.calculateStreak();
    final identity = await gamification.calculateIdentityScore();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sixMonthsAgo = today.subtract(const Duration(days: 182));

    final allTasks = YamadaDatabase.getAllTasks();
    final allHabits = YamadaDatabase.getAllHabits();
    final allFocus = YamadaDatabase.getAllFocusSessions();

    final Map<DateTime, double> heatData = {};

    // Generate daily XP based on Hive logs
    for (int i = 0; i < 182; i++) {
      final date = today.subtract(Duration(days: i));
      
      int dailyXp = 0;
      final tasksDone = allTasks.where((t) => t.isCompleted && t.dueDate != null && t.dueDate!.year == date.year && t.dueDate!.month == date.month && t.dueDate!.day == date.day).length;
      final habitsDone = allHabits.where((h) => h.lastCompleted != null && h.lastCompleted!.year == date.year && h.lastCompleted!.month == date.month && h.lastCompleted!.day == date.day).length;
      final focusMins = allFocus.where((f) => f.completed && f.startTime.year == date.year && f.startTime.month == date.month && f.startTime.day == date.day).fold(0, (sum, f) => sum + f.durationMinutes);

      dailyXp += tasksDone * 20; // Avg
      dailyXp += habitsDone * 15;
      dailyXp += focusMins * 2;

      if (dailyXp > 0) {
        final intensity = (dailyXp / 100.0).clamp(0.0, 1.0);
        heatData[date] = intensity;
      }
    }

    if (mounted) {
      setState(() {
        _totalXp = xp;
        _level = level;
        _levelProgress = progress;
        _streak = streak;
        _identityScore = identity;
        _heatmapData = heatData;
      });
    }
  }

  Future<void> _changeHeroImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'hero_image.png');
      await File(picked.path).copy(dest);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('yamada_hero_image', dest);

      setState(() {
        _heroImagePath = dest;
      });
    }
  }

  Future<void> _saveQuote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yamada_quote', _quoteController.text);
    setState(() {
      _quote = _quoteController.text;
      _isEditingQuote = false;
    });
  }

  Future<void> _saveUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yamada_username', _usernameController.text);
    setState(() {
      _username = _usernameController.text;
      _isEditingUsername = false;
    });
  }

  void _showInlineThemeSwitcher() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: YamadaTheme.crimson,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => _ThemeSwitcherSheet(tp: tp),
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroSection(
              username: _username,
              isEditingUsername: _isEditingUsername,
              usernameController: _usernameController,
              onTapUsername: () => setState(() => _isEditingUsername = true),
              onSaveUsername: _saveUsername,
              quote: _quote,
              heroImagePath: _heroImagePath,
              isEditingQuote: _isEditingQuote,
              quoteController: _quoteController,
              onTapProfile: _changeHeroImage,
              onTapQuote: () => setState(() => _isEditingQuote = true),
              onSaveQuote: _saveQuote,
              onTapSettings: _showInlineThemeSwitcher,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  StatsRow(level: _level, streak: _streak, totalXp: _totalXp)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EXPERIENCE', style: YamadaTheme.sectionLabel),
                        const SizedBox(height: 12),
                        XpBar(
                          progress: _levelProgress,
                          currentXp: _totalXp,
                          nextLevelXp: GamificationService.xpForLevel(_level + 1),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 20),

                  IdentityScoreWidget(score: _identityScore)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVITY // 26 WEEKS', style: YamadaTheme.sectionLabel),
                        const SizedBox(height: 12),
                        ActivityHeatmap(data: _heatmapData),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISCIPLINE MODE', style: YamadaTheme.sectionLabel),
                        const SizedBox(height: 12),
                        _buildDisciplineBar(),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplineBar() {
    final disciplineLevel = (_identityScore / 2.5).clamp(0.0, 4.0).floor() + 1;
    final labels = ['RECRUIT', 'SOLDIER', 'OPERATOR', 'COMMANDER', 'WARLORD'];
    final label = labels[disciplineLevel.clamp(0, 4)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: YamadaTheme.dataMedium),
            Text('LV.$disciplineLevel', style: YamadaTheme.dataLarge),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: YamadaTheme.ink, width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (disciplineLevel / 5).clamp(0.0, 1.0),
            child: Container(color: YamadaTheme.ink),
          ),
        ),
      ],
    );
  }
}

class _ThemeSwitcherSheet extends StatelessWidget {
  final ThemeProvider tp;
  const _ThemeSwitcherSheet({required this.tp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('THEME', style: YamadaTheme.heading3),
          const SizedBox(height: 16),
          _opt(context, 'BLOOD', YamadaThemeMode.blood, const Color(0xFFCB1E1E)),
          const SizedBox(height: 8),
          _opt(context, 'BONE', YamadaThemeMode.bone, const Color(0xFFF5F0E8)),
          const SizedBox(height: 8),
          _opt(context, 'VOID', YamadaThemeMode.void_, const Color(0xFF080808)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _opt(BuildContext ctx, String name, YamadaThemeMode mode, Color preview) {
    final isActive = tp.mode == mode;
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        tp.setTheme(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? YamadaTheme.ink.withValues(alpha: 0.1) : null,
          border: YamadaTheme.hardBorder,
        ),
        child: Row(
          children: [
            Container(width: 24, height: 24, color: preview),
            const SizedBox(width: 14),
            Text(name, style: YamadaTheme.bodyBold),
            const Spacer(),
            if (isActive) Icon(Icons.check, color: YamadaTheme.ink, size: 20),
          ],
        ),
      ),
    );
  }
}
