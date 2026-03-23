import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/yamada_theme.dart';

/// Hero section with scanline animation, quote, and profile image.
class HeroSection extends StatelessWidget {
  final String username;
  final bool isEditingUsername;
  final TextEditingController usernameController;
  final VoidCallback onTapUsername;
  final VoidCallback onSaveUsername;
  final String quote;
  final String? heroImagePath;
  final bool isEditingQuote;
  final TextEditingController quoteController;
  final VoidCallback onTapProfile;
  final VoidCallback onTapQuote;
  final VoidCallback onSaveQuote;
  final VoidCallback? onTapSettings;

  const HeroSection({
    super.key,
    required this.username,
    required this.isEditingUsername,
    required this.usernameController,
    required this.onTapUsername,
    required this.onSaveUsername,
    required this.quote,
    required this.heroImagePath,
    required this.isEditingQuote,
    required this.quoteController,
    required this.onTapProfile,
    required this.onTapQuote,
    required this.onSaveQuote,
    this.onTapSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: YamadaTheme.crimson,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                YamadaTheme.crimson,
                YamadaTheme.ink.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),

        // Scanline overlay
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                YamadaTheme.crimson.withValues(alpha: 0.0),
                YamadaTheme.crimson.withValues(alpha: 0.3),
                YamadaTheme.crimson,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings icon (top-right)
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onTapSettings,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                    child: Icon(Icons.tune, color: YamadaTheme.ink, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Username
              if (isEditingUsername)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: usernameController,
                        style: YamadaTheme.heading2,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'YOUR NAME',
                          hintStyle: YamadaTheme.heading2
                              .copyWith(color: YamadaTheme.inkGhost),
                        ),
                        onSubmitted: (_) => onSaveUsername(),
                      ),
                    ),
                    GestureDetector(
                      onTap: onSaveUsername,
                      child: Icon(Icons.check, color: YamadaTheme.ink),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: onTapUsername,
                  child: Text(
                    'STAY LOCKED, $username.',
                    style: YamadaTheme.heading2,
                  ),
                ),

              const SizedBox(height: 4),

              // Quote
              if (isEditingQuote)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quoteController,
                        style: YamadaTheme.body.copyWith(
                            fontStyle: FontStyle.italic),
                        autofocus: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'YOUR QUOTE',
                          hintStyle: YamadaTheme.body
                              .copyWith(color: YamadaTheme.inkGhost),
                        ),
                        onSubmitted: (_) => onSaveQuote(),
                      ),
                    ),
                    GestureDetector(
                      onTap: onSaveQuote,
                      child: Icon(Icons.check, color: YamadaTheme.ink),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: onTapQuote,
                  child: Text(
                    '"$quote"',
                    style: YamadaTheme.body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: YamadaTheme.inkLight,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Profile image swap button
              GestureDetector(
                onTap: onTapProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: YamadaTheme.ink, size: 16),
                      const SizedBox(width: 6),
                      Text('CHANGE BANNER', style: YamadaTheme.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }
}
