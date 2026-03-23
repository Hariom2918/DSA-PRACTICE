import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/command_service.dart';
import '../services/gamification_service.dart';
import '../theme/yamada_theme.dart';
import '../screens/app_shell.dart';

/// Command bar widget — persistent bottom input for natural language commands.
class CommandBar extends StatefulWidget {
  final AppShellState? appShell;

  const CommandBar({super.key, this.appShell});

  @override
  State<CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends State<CommandBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String? _response;
  bool _isError = false;
  bool _isProcessing = false;
  bool _showTypingIndicator = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _executeCommand() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    // Show typing indicator for 300ms
    setState(() {
      _showTypingIndicator = true;
      _isProcessing = true;
    });
    _controller.clear();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _showTypingIndicator = false);

    final gamification = GamificationService();
    final commandService = CommandService(gamification);

    final result = await commandService.execute(input);

    // Handle navigation actions
    if (result.action == CommandAction.navigateToFocus) {
      widget.appShell?.navigateToTab(4);
    }

    setState(() {
      _response = result.message;
      _isError = result.action == CommandAction.error;
      _isProcessing = false;
    });

    // Auto-collapse response after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _response = null;
          _isError = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Response area
        if (_response != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: YamadaTheme.ink,
            child: Text(
              _response!,
              style: YamadaTheme.body.copyWith(
                color: _isError ? const Color(0xFFFF3333) : YamadaTheme.crimson,
                fontSize: 13,
                fontFamily: YamadaTheme.fontBarlowCondensed,
              ),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),

        // Typing indicator
        if (_showTypingIndicator)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: YamadaTheme.ink,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) =>
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: YamadaTheme.crimson,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(delay: (i * 100).ms, duration: 300.ms)
                    .fadeOut(delay: 200.ms, duration: 300.ms),
              ),
            ),
          ),

        // Command input
        Container(
          decoration: BoxDecoration(
            color: YamadaTheme.crimson,
            border: Border(
              top: BorderSide(color: YamadaTheme.ink, width: 2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text('>', style: YamadaTheme.dataLarge.copyWith(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: YamadaTheme.body.copyWith(
                    fontFamily: YamadaTheme.fontBarlowCondensed,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ENTER COMMAND...',
                    hintStyle: YamadaTheme.body.copyWith(
                      color: YamadaTheme.inkGhost,
                      fontFamily: YamadaTheme.fontBarlowCondensed,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _executeCommand(),
                ),
              ),
              GestureDetector(
                onTap: _isProcessing ? null : _executeCommand,
                child: Container(
                  width: 36,
                  height: 36,
                  color: YamadaTheme.ink,
                  child: _isProcessing
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YamadaTheme.crimson,
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward,
                          color: YamadaTheme.crimson,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
