import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'Fireworks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Firework App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const InitialScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------- InitialScreen Widget & State --------------------
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> with TickerProviderStateMixin {
  final List<FireworkEvent> _fireworks = [];
  final Random _random = Random();
  final GlobalKey _buttonKey = GlobalKey();
  bool _isButtonPressed = false;
  int _counter = 0;
  Timer? _fireworkTimer;
  Timer? _holdDelayTimer;

  void _startFireworkTimer() {
    _fireworkTimer?.cancel();
    _fireworkTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _launchNewFirework();
    });
  }

  void _stopFireworkTimer() {
    _fireworkTimer?.cancel();
    _fireworkTimer = null;
  }

  void _cancelHoldDelayTimer() {
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('firework_counter') ?? 0;
    });
  }

  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firework_counter', _counter);
  }

  void _launchNewFirework() {
    final RenderBox? buttonRenderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonRenderBox == null || !mounted) return;

    final buttonSize = buttonRenderBox.size;
    final buttonCenterGlobal = buttonRenderBox.localToGlobal(buttonSize.center(Offset.zero));
    final fireworkOrigin = Offset(buttonCenterGlobal.dx, buttonCenterGlobal.dy + buttonSize.height * 0.3);
    final screenSize = MediaQuery.of(context).size;

    // --- LOGICA PARTICELLE DINAMICHE ---
    int activeFireworks = _fireworks.length;
    int particleCount;
    if (activeFireworks <= 0) {
      particleCount = 40;
    } else if (activeFireworks == 1) {
      particleCount = 20;
    } else {
      particleCount = 10;
    }

    setState(() {
      _counter++;
    });
    _saveCounter();

    final firework = FireworkEvent(
      vsync: this,
      random: _random,
      onRequestVisualUpdate: () {
        if (mounted) setState(() {});
      },
      onEventComplete: (eventId) {
        if (!mounted) return;
        setState(() {
          _fireworks.removeWhere((f) => f.id == eventId);
        });
      },
      initialFireworkOrigin: fireworkOrigin,
      screenSize: screenSize,
      particleCount: particleCount,
    );
    setState(() {
      _fireworks.add(firework);
      firework.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double buttonDepth = _isButtonPressed ? 2.0 : 8.0;
    final double buttonScale = _isButtonPressed ? 0.96 : 1.0;
    final Color topColor = _isButtonPressed ? Colors.red.shade700 : Colors.red.shade500;
    final Color bottomColor = _isButtonPressed ? Colors.red.shade900 : Colors.red.shade700;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ..._fireworks
              .map((f) => f.buildFuseWidget())
              .where((w) => w != null)
              .cast<Widget>(),
          Center(
            child: GestureDetector(
              key: _buttonKey,
              onTapDown: (_) {
                setState(() {
                  _isButtonPressed = true;
                });
                _launchNewFirework();
                _holdDelayTimer = Timer(const Duration(milliseconds: 500), () {
                  if (_isButtonPressed) {
                    _startFireworkTimer();
                  }
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isButtonPressed = false;
                });
                _stopFireworkTimer();
                _cancelHoldDelayTimer();
              },
              onTapCancel: () {
                setState(() {
                  _isButtonPressed = false;
                });
                _stopFireworkTimer();
                _cancelHoldDelayTimer();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(buttonScale),
                transformAlignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [topColor, bottomColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: Offset(buttonDepth, buttonDepth),
                      blurRadius: buttonDepth * 1.5,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.red.shade200.withValues(alpha: 0.7),
                      offset: Offset(-buttonDepth / 2, -buttonDepth / 2),
                      blurRadius: buttonDepth,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: Offset.zero,
                      blurRadius: 5,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: const Text(
                  'Iglie!',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 2.0,
                          color: Colors.black38,
                        ),
                      ]
                  ),
                ),
              ),
            ),
          ),
          ..._fireworks.expand((f) => f.buildParticleWidgets()),
          Positioned(
            left: 16,
            bottom: 16,
            child: Text(
              '$_counter',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopFireworkTimer();
    _cancelHoldDelayTimer();
    for (var f in _fireworks) {
      f.dispose();
    }
    super.dispose();
  }
}