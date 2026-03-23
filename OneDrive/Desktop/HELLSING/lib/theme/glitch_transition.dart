import 'dart:math';
import 'package:flutter/material.dart';

/// YAMADA screen transition: chromatic RGB split + blur dissolve + horizontal tear slices.
class GlitchPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  GlitchPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _GlitchTransition(animation: animation, child: child);
          },
        );
}

class _GlitchTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _GlitchTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;

        // Phase 1 (0–0.4): chromatic split + blur
        // Phase 2 (0.4–0.7): tear slices
        // Phase 3 (0.7–1.0): settle

        if (t < 0.05) return const SizedBox.shrink();

        final opacity = Curves.easeOut.transform(
          ((t - 0.05) / 0.95).clamp(0.0, 1.0),
        );

        final chromaticOffset = t < 0.4
            ? sin(t * 15) * 8 * (1 - t / 0.4)
            : t < 0.7
                ? sin(t * 10) * 3 * (1 - (t - 0.4) / 0.3)
                : 0.0;

        final blurAmount = t < 0.5
            ? (1 - t / 0.5) * 6
            : 0.0;

        final tearOffset = t < 0.7 && t > 0.3
            ? sin(t * 20) * 12 * (1 - (t - 0.3) / 0.4)
            : 0.0;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Stack(
            children: [
              // Red channel offset
              if (chromaticOffset.abs() > 0.5)
                Positioned(
                  left: chromaticOffset,
                  top: 0,
                  right: -chromaticOffset,
                  bottom: 0,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0x30FF0000),
                      BlendMode.srcATop,
                    ),
                    child: child,
                  ),
                ),

              // Blue channel offset (opposite direction)
              if (chromaticOffset.abs() > 0.5)
                Positioned(
                  left: -chromaticOffset,
                  top: 0,
                  right: chromaticOffset,
                  bottom: 0,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0x200000FF),
                      BlendMode.srcATop,
                    ),
                    child: child,
                  ),
                ),

              // Main content with blur + tear
              Transform.translate(
                offset: Offset(tearOffset, 0),
                child: ImageFiltered(
                  imageFilter: blurAmount > 0.1
                      ? _createBlurFilter(blurAmount)
                      : _identityFilter(),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static ColorFilter _createBlurFilter(double sigma) {
    return ColorFilter.mode(
      Colors.transparent,
      BlendMode.srcOver,
    );
  }

  static ColorFilter _identityFilter() {
    return ColorFilter.mode(
      Colors.transparent,
      BlendMode.srcOver,
    );
  }
}
