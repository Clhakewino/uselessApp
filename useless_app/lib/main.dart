import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'Fireworks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landscape.dart';

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
  bool _isHolding = false;
  Offset? _lastTapPosition;

  void _startFireworkTimer() {
    _fireworkTimer?.cancel();
    _fireworkTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isHolding && _lastTapPosition != null) {
        _launchNewFirework(at: _lastTapPosition);
      }
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
    _loadCounter().then((_) {
      if (mounted) setState(() {});
    });
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

  void _launchNewFirework({Offset? at}) {
    final screenSize = MediaQuery.of(context).size;
    final fireworkOrigin = at ?? Offset(screenSize.width / 2, screenSize.height / 2);

    int activeFireworks = _fireworks.length;
    int particleCount;
    if (activeFireworks <= 0) {
      particleCount = 30;
    } else if (activeFireworks == 1) {
      particleCount = 15;
    } else {
      particleCount = 6;
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
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _isHolding = true;
          _lastTapPosition = event.localPosition;
          _holdDelayTimer?.cancel();
          _holdDelayTimer = Timer(const Duration(milliseconds: 500), () {
            if (_isHolding && _lastTapPosition != null) {
              _startFireworkTimer();
            }
          });

          // Firework singolo subito al tap
          final tapPosition = event.localPosition;
          final screenSize = MediaQuery.of(context).size;

          int activeFireworks = _fireworks.length;
          int particleCount;
          if (activeFireworks <= 0) {
            particleCount = 30;
          } else if (activeFireworks == 1) {
            particleCount = 15;
          } else {
            particleCount = 6;
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
            initialFireworkOrigin: tapPosition,
            screenSize: screenSize,
            particleCount: particleCount,
          );
          setState(() {
            _fireworks.add(firework);
            firework.start();
          });
        },
        onPointerUp: (_) {
          _isHolding = false;
          _holdDelayTimer?.cancel();
          _stopFireworkTimer();
        },
        onPointerCancel: (_) {
          _isHolding = false;
          _holdDelayTimer?.cancel();
          _stopFireworkTimer();
        },
        onPointerMove: (event) {
          if (_isHolding) {
            _lastTapPosition = event.localPosition;
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            LandscapeBackground(counter: _counter),
            ..._fireworks
                .map((f) => f.buildFuseWidget())
                .where((w) => w != null)
                .cast<Widget>(),
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