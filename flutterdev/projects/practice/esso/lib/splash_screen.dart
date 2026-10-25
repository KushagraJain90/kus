
import 'dart:async';

import 'package:flutter/material.dart';


class InkoraSplashScreen extends StatefulWidget {
  const InkoraSplashScreen({
    super.key,
    required this.nextScreen,
  });

  final Widget nextScreen;

  @override
  State<InkoraSplashScreen> createState() =>
      _InkoraSplashScreenState();
}

class _InkoraSplashScreenState extends State<InkoraSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  Timer? _navigationTimer;

  static const List<String> _messages = [
    'Preparing your workspace...',
    'Loading app components...',
    'Organizing your tools...',
    'Almost ready...',
  ];

  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addListener(_updateMessage);
    _controller.forward();

    _navigationTimer = Timer(
      const Duration(milliseconds: 4500),
      _openNextScreen,
    );
  }

  void _updateMessage() {
    final progress = _controller.value;

    final newIndex = progress < 0.25
        ? 0
        : progress < 0.50
        ? 1
        : progress < 0.80
        ? 2
        : 3;

    if (newIndex != _messageIndex && mounted) {
      setState(() => _messageIndex = newIndex);
    }
  }

  void _openNextScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
        widget.nextScreen,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.removeListener(_updateMessage);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = isDark
        ? const Color(0xFF10121A)
        : const Color(0xFFF7F8FC);

    final muted = isDark
        ? const Color(0xFFA8B2CB)
        : const Color(0xFF7585A6);

    final track = isDark
        ? const Color(0xFF2B3040)
        : const Color(0xFFDDE4F0);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // App logo
                Container(
                  width: 126,
                  height: 126,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF20283C)
                        : const Color(0xFFEDF2FF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFCADBFF),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF171B27)
                          : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) {
                          return const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF536DFE),
                            size: 48,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Inkora AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Preparing your experience...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: muted,
                  ),
                ),

                const Spacer(flex: 2),

                // Animated progress bar
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    final percentage =
                    (_progress.value * 100).round();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 9,
                            color: track,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _progress.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3278F6),
                                      Color(0xFF36B9F4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 250,
                                ),
                                child: Text(
                                  _messages[_messageIndex],
                                  key: ValueKey(_messageIndex),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: muted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3278F6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(flex: 2),

                Text(
                  'Your handwritten notes. Smarter evaluation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
