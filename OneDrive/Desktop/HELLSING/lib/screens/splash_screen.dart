
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import 'onboarding_screen.dart';
import 'app_shell.dart';
import 'package:video_player/video_player.dart';

/// Full-screen animated splash — cold launch only.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static bool _hasPlayed = false;

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  late AnimationController _fadeController;
  late AnimationController _textController;
  late AnimationController _glitchController;
  late Animation<double> _fadeAnim;

  bool _showText = false;
  bool _glitching = false;
  final String _appName = 'YAMADA';
  int _visibleLetters = 0;

  @override
  void initState() {
    super.initState();

    if (_hasPlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateAway());
      return;
    }
    _hasPlayed = true;

    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');
    _videoController.initialize().then((_) {
      if (mounted) setState(() => _isVideoInitialized = true);
      _videoController.play();
      _videoController.setVolume(0.0); // mute splash

      // Navigate away when the video concludes or hits 3 seconds
      _videoController.addListener(() {
        if (!mounted) return;
        if (_videoController.value.isInitialized) {
          final position = _videoController.value.position;
          final duration = _videoController.value.duration;
          if (position >= duration || position >= const Duration(seconds: 3)) {
            _navigateAway();
          }
        }
      });
    }).catchError((e) {
      // Fallback if video is missing or fails to load
      _startFallbackSequence();
    });

    _fadeController = AnimationController(
// ... rest of fallback logic remains the same
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _startFallbackSequence() async {
    // Phase 1: Fade in devil
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));

    // Phase 2: Stamp letters
    setState(() => _showText = true);
    for (int i = 1; i <= _appName.length; i++) {
      await Future.delayed(const Duration(milliseconds: 140));
      if (mounted) setState(() => _visibleLetters = i);
    }

    await Future.delayed(const Duration(milliseconds: 400));

    // Phase 3: Glitch tear
    if (mounted) setState(() => _glitching = true);
    _glitchController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) _navigateAway();
  }

  bool _navigated = false;

  void _navigateAway() async {
    if (_navigated) return;
    _navigated = true;
    if (_isVideoInitialized) _videoController.pause();

    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('yamada_onboarding_done') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            onboarded ? const AppShell() : const OnboardingScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    if (!_hasPlayed || _fadeController.duration != null) {
      _fadeController.dispose();
      _textController.dispose();
      _glitchController.dispose();
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPlayed && !_glitching && _visibleLetters == 0 && !_showText) {
      return const SizedBox.shrink();
    }

    final tp = Provider.of<ThemeProvider>(context, listen: false);
    final bg = tp.splashBackground;
    final inkColor = tp.splashInkColor;

    if (_isVideoInitialized && _videoController.value.isInitialized) {
      final width = _videoController.value.size.width;
      final height = _videoController.value.size.height;

      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: width > 0 ? width : 100,
                height: height > 0 ? height : 100,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: _glitching
          ? AnimatedBuilder(
              animation: _glitchController,
              builder: (context, child) {
                final t = _glitchController.value;
                return Stack(
                  children: [
                    // Strip 1 (top third)
                    Positioned(
                      top: 0,
                      left: -40 * t,
                      right: 40 * t,
                      height: MediaQuery.of(context).size.height / 3,
                      child: _buildContent(bg, inkColor),
                    ),
                    // Strip 2 (middle third)
                    Positioned(
                      top: MediaQuery.of(context).size.height / 3,
                      left: 60 * t,
                      right: -60 * t,
                      height: MediaQuery.of(context).size.height / 3,
                      child: _buildContent(bg, inkColor),
                    ),
                    // Strip 3 (bottom third)
                    Positioned(
                      top: 2 * MediaQuery.of(context).size.height / 3,
                      left: -30 * t,
                      right: 30 * t,
                      height: MediaQuery.of(context).size.height / 3,
                      child: _buildContent(bg, inkColor),
                    ),
                    // Chromatic aberration overlay
                    if (t > 0.1)
                      Opacity(
                        opacity: (1 - t) * 0.4,
                        child: Container(
                          color: Colors.red.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                );
              },
            )
          : _buildContent(bg, inkColor),
    );
  }

  Widget _buildContent(Color bg, Color inkColor) {
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Devil figure
            FadeTransition(
              opacity: _fadeAnim,
              child: CustomPaint(
                size: const Size(200, 240),
                painter: _DevilPainter(color: inkColor),
              ),
            ),
            const SizedBox(height: 40),
            // YAMADA text with ink-bleed
            if (_showText)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_appName.length, (i) {
                  if (i >= _visibleLetters) {
                    return SizedBox(
                      width: 42,
                      child: Text(' ',
                          style: TextStyle(
                              fontFamily: 'Anton', fontSize: 48, color: inkColor)),
                    );
                  }
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: -20.0, end: 0.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, offset, child) {
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: Opacity(
                          opacity: (1 + offset / 20).clamp(0.0, 1.0),
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                inkColor,
                                inkColor.withValues(alpha: 0.6),
                                inkColor,
                              ],
                              stops: [
                                0.0,
                                (0.3 + offset.abs() / 40).clamp(0.0, 0.6),
                                1.0,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              _appName[i],
                              style: TextStyle(
                                fontFamily: 'Anton',
                                fontSize: 48,
                                color: inkColor,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

/// Devil/demon figure — stark ink illustration.
/// Black jagged horns, hollow white eyes, minimal lines like a woodblock print.
class _DevilPainter extends CustomPainter {
  final Color color;

  _DevilPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Left horn ──────────────────────────────────────
    final leftHorn = Path()
      ..moveTo(cx - 30, cy - 20)
      ..lineTo(cx - 55, cy - 100)
      ..lineTo(cx - 70, cy - 110)
      ..lineTo(cx - 45, cy - 90)
      ..lineTo(cx - 50, cy - 70)
      ..lineTo(cx - 25, cy - 15);
    canvas.drawPath(leftHorn, fillPaint);

    // ── Right horn ─────────────────────────────────────
    final rightHorn = Path()
      ..moveTo(cx + 30, cy - 20)
      ..lineTo(cx + 55, cy - 100)
      ..lineTo(cx + 70, cy - 110)
      ..lineTo(cx + 45, cy - 90)
      ..lineTo(cx + 50, cy - 70)
      ..lineTo(cx + 25, cy - 15);
    canvas.drawPath(rightHorn, fillPaint);

    // ── Head outline ───────────────────────────────────
    final head = Path()
      ..moveTo(cx - 40, cy - 10)
      ..quadraticBezierTo(cx - 50, cy + 20, cx - 35, cy + 50)
      ..lineTo(cx - 15, cy + 65)
      ..lineTo(cx, cy + 70)
      ..lineTo(cx + 15, cy + 65)
      ..lineTo(cx + 35, cy + 50)
      ..quadraticBezierTo(cx + 50, cy + 20, cx + 40, cy - 10);
    canvas.drawPath(head, paint);

    // ── Hollow eyes (white circles with dark outline) ──
    final eyePaint = Paint()
      ..color = color == const Color(0xFF0A0000) 
          ? const Color(0xFFFFFFFF) 
          : color == const Color(0xFFEBEBEB) 
              ? const Color(0xFF080808) 
              : const Color(0xFFF5F0E8)
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 18, cy + 10), width: 18, height: 22),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 18, cy + 10), width: 18, height: 22),
      paint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 18, cy + 10), width: 18, height: 22),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 18, cy + 10), width: 18, height: 22),
      paint,
    );

    // ── Jaw lines ──────────────────────────────────────
    canvas.drawLine(
        Offset(cx - 20, cy + 45), Offset(cx - 10, cy + 60), paint);
    canvas.drawLine(
        Offset(cx + 20, cy + 45), Offset(cx + 10, cy + 60), paint);

    // ── Cracked forehead lines (woodblock style) ───────
    canvas.drawLine(
        Offset(cx - 5, cy - 15), Offset(cx - 12, cy + 2), paint);
    canvas.drawLine(
        Offset(cx + 5, cy - 15), Offset(cx + 12, cy + 2), paint);
    canvas.drawLine(Offset(cx, cy - 18), Offset(cx, cy - 5), paint);

    // ── Cheekbone slash lines ──────────────────────────
    final thinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(cx - 35, cy + 20), Offset(cx - 25, cy + 35), thinPaint);
    canvas.drawLine(
        Offset(cx + 35, cy + 20), Offset(cx + 25, cy + 35), thinPaint);

    // ── Rising darkness below (vertical lines fading down) ──
    for (int i = -3; i <= 3; i++) {
      final x = cx + i * 12.0;
      final fadePaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(x, cy + 75),
        Offset(x + (i * 2), cy + 110),
        fadePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DevilPainter old) => old.color != color;
}
