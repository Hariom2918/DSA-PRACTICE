
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/yamada_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/command_bar.dart';
import 'dashboard/dashboard_screen.dart';
import 'missions/missions_screen.dart';
import 'habits/habits_screen.dart';
import 'notes/notes_screen.dart';
import 'focus/focus_screen.dart';
import 'analytics/analytics_screen.dart';
import 'dart:ui' as ui;

/// Main app shell with bottom navigation, command bar, enhanced glitch transitions,
/// theme switcher, and quick-add FAB.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  // Glitch transition state
  bool _isTransitioning = false;
  int _nextIndex = 0;
  late AnimationController _glitchController;
  late Animation<double> _glitchAnimation;

  // Theme flash state
  bool _showThemeFlash = false;

  // Per-tab glitch tint colors
  static const List<Color> _tabTints = [
    Color(0xFFFF0000), // Dashboard: red
    Color(0xFFFFAA00), // Missions: amber
    Color(0xFF00FF44), // Habits: green
    Color(0xFF0066FF), // Notes: blue
    Color(0xFFEBEBEB), // Focus: white
    Color(0xFFFF00FF), // Stats: magenta
  ];

  @override
  void initState() {
    super.initState();
    _screens = const [
      DashboardScreen(),
      MissionsScreen(),
      HabitsScreen(),
      NotesScreen(),
      FocusScreen(),
      AnalyticsScreen(),
    ];

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _glitchAnimation = CurvedAnimation(
      parent: _glitchController,
      curve: Curves.easeInOut,
    );

    _glitchController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
          _isTransitioning = false;
        });
        _glitchController.reset();
      }
    });
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex || _isTransitioning) return;
    HapticFeedback.lightImpact();

    setState(() {
      _nextIndex = index;
      _isTransitioning = true;
    });
    _glitchController.forward();
  }

  /// Navigate to a specific tab (used by command bar)
  void navigateToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      _onTabTapped(index);
    }
  }

  // Removed quick add FAB


  void _showThemeSwitcher() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: YamadaTheme.crimson,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('THEME', style: YamadaTheme.heading3),
            const SizedBox(height: 16),
            _themeOption(ctx, tp, 'BLOOD', YamadaThemeMode.blood,
                const Color(0xFFCB1E1E), const Color(0xFF0A0000)),
            const SizedBox(height: 8),
            _themeOption(ctx, tp, 'BONE', YamadaThemeMode.bone,
                const Color(0xFFF5F0E8), const Color(0xFF1A1008)),
            const SizedBox(height: 8),
            _themeOption(ctx, tp, 'VOID', YamadaThemeMode.void_,
                const Color(0xFF080808), const Color(0xFFEBEBEB)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, ThemeProvider tp, String name,
      YamadaThemeMode mode, Color bg, Color text) {
    final isActive = tp.mode == mode;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        if (tp.mode == mode) return;

        // Flash animation
        setState(() => _showThemeFlash = true);
        await Future.delayed(const Duration(milliseconds: 150));
        await tp.setTheme(mode);
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _showThemeFlash = false);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? bg : null,
          border: Border.all(color: text, width: 2),
        ),
        child: Row(
          children: [
            Container(width: 24, height: 24, color: bg,
              decoration: BoxDecoration(border: Border.all(color: text, width: 1)),
            ),
            const SizedBox(width: 14),
            Text(name,
                style: YamadaTheme.bodyBold.copyWith(
                  color: isActive ? text : YamadaTheme.ink,
                )),
            const Spacer(),
            if (isActive)
              Icon(Icons.check, color: text, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: YamadaTheme.crimson,
          body: _buildBody(),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommandBar(appShell: this),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: YamadaTheme.ink, width: 3),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _isTransitioning ? _nextIndex : _currentIndex,
                  onTap: _onTabTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'HQ',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.flag),
                      label: 'MISSIONS',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_fire_department),
                      label: 'HABITS',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.edit_note),
                      label: 'BRAIN',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.center_focus_strong),
                      label: 'FOCUS',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics),
                      label: 'STATS',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Theme flash overlay
        if (_showThemeFlash)
          Positioned.fill(
            child: Container(color: tp.flashColor),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _glitchAnimation,
      builder: (context, child) {
        if (!_isTransitioning) {
          return _screens[_currentIndex];
        }

        // Rapid frame stuttering (quantize time to 12fps steps)
        final t = _glitchAnimation.value;
        final quantizedT = (t * 12).floor() / 12;
        final showNew = quantizedT > 0.5;
        final screen = showNew ? _screens[_nextIndex] : _screens[_currentIndex];
        final tint = _tabTints[_nextIndex];
        
        // Intensity curve: peaks sharply in the middle, drops off but leaves residual
        final rawIntensity = showNew ? (1 - quantizedT) * 2 : quantizedT * 2;
        final intensity = (t > 0.8) ? (1 - t) * 0.2 : rawIntensity; // Residual glitch at end

        // Quick white flash at the exact switch point
        final flashOpacity = (t > 0.45 && t < 0.55) ? 1.0 : 0.0;

        // Brief static noise overlay
        final scanlinePhase = (quantizedT * 20).floor() % 2;
        final scanlineOpacity = (intensity > 0.1 && scanlinePhase == 0) ? 0.2 : 0.0;

        // Content warp: sharp scaling
        final scale = showNew
            ? 0.95 + (quantizedT - 0.5) * 2 * 0.05
            : 1.0 - (quantizedT * 0.05);

        return Stack(
          children: [
            // Layer 0: The base multi-layered ghosting effect
            ...List.generate(3, (i) {
              final ghostOffset = intensity * 35 * (i - 1);
              final ghostOpacity = (0.4 - (i * 0.15)).clamp(0.0, 1.0);
              
              return Positioned.fill(
                child: Transform.translate(
                  offset: Offset(ghostOffset, 0),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: intensity * 30 * (i + 1), 
                      sigmaY: 3 * intensity
                    ),
                    child: Opacity(
                      opacity: (showNew
                          ? ((quantizedT - 0.5) * 2).clamp(0.0, 1.0)
                          : (1.0 - quantizedT * 2).clamp(0.0, 1.0)) * (i == 0 ? 1.0 : ghostOpacity),
                      child: screen,
                    ),
                  ),
                ),
              );
            }),

            // Layer 1: Core Slice Shift (Aggressive horizontal displacement)
            if (intensity > 0.15)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0, (quantizedT * 7 % 1) * 2 - 1),
                  heightFactor: 0.1 + (quantizedT % 0.15),
                  child: Transform.translate(
                    offset: Offset(intensity * 60 * (quantizedT % 0.3 > 0.15 ? 1 : -1), 0),
                    child: screen,
                  ),
                ),
              ),

            // Layer 2: RGB Channel Separation (Red/Blue Tearing)
            if (intensity > 0.02) ...[
              // Red channel tearing left
              ...List.generate(3, (index) {
                final yAlign = -1.0 + (index * 0.8) + (quantizedT * 0.6);
                return Positioned.fill(
                  child: Align(
                    alignment: Alignment(0, yAlign),
                    heightFactor: 0.15,
                    child: Transform.translate(
                      offset: Offset(-intensity * 70 * (index + 1), 0),
                      child: Opacity(
                        opacity: 0.4,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(Color(0xFFFF0000), BlendMode.plus),
                          child: screen,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Blue channel tearing right
              ...List.generate(3, (index) {
                final yAlign = -0.9 + (index * 0.8) - (quantizedT * 0.5);
                return Positioned.fill(
                  child: Align(
                    alignment: Alignment(0, yAlign),
                    heightFactor: 0.15,
                    child: Transform.translate(
                      offset: Offset(intensity * 90 * (index + 1), 0),
                      child: Opacity(
                        opacity: 0.4,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(Color(0xFF0000FF), BlendMode.plus),
                          child: screen,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Layer 3: White Flash for impact
            if (flashOpacity > 0)
              Positioned.fill(
                child: Container(color: Colors.white.withValues(alpha: flashOpacity)),
              ),

            // Layer 4: Static Noise / Scanline strobe
            if (scanlineOpacity > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tint.withValues(alpha: 0.0),
                        tint.withValues(alpha: 0.6),
                        tint.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
