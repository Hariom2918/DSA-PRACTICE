import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate Logo', (WidgetTester tester) async {
    final painter = _DevilPainter(color: const Color(0xFF0A0000));
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Fill background
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), Paint()..color = const Color(0xFFCB1E1E));
    
    // Scale and center the drawing
    canvas.save();
    // Center of 200x240 is 100, 120. Scale is 3.5. So center becomes 350, 420.
    // Target center is 512, 512. Translate by 512 - 350 = 162, 512 - 420 = 92
    canvas.translate(162, 92);
    canvas.scale(3.5);
    painter.paint(canvas, const Size(200, 240));
    canvas.restore();
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(1024, 1024);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    File('assets/logo.png').writeAsBytesSync(bytes);
  });
}

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

    // ── Hollow eyes (white/red circles with dark outline) ──
    final eyePaint = Paint()
      ..color = const Color(0xFFCB1E1E) // Match background so they look hollow on red background
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
        ..color = color.withOpacity(0.3)
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
