import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'Fireworks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'buttonsManager.dart';
import 'landscape.dart';
import 'Login.dart';
import 'services/auth.dart';
import 'Sounds.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    print('Errore inizializzazione Firebase: $e');
    print(s);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Useless App',
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

class _InitialScreenState extends State<InitialScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<FireworkEvent> _fireworks = [];
  final Random _random = Random();
  final GlobalKey _buttonKey = GlobalKey();
  bool _isButtonPressed = false;
  int _counter = 0;
  Timer? _fireworkTimer;
  Timer? _holdDelayTimer;
  bool _isHolding = false;
  Offset? _lastTapPosition;
  final Auth _auth = Auth();
  StreamSubscription? _authSub;

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
    WidgetsBinding.instance.addObserver(this);
    _loadCounter().then((_) {
      if (mounted) setState(() {});
    });
    // Ascolta cambi login/logout per caricare counter da Firestore SOLO al login e azzera al logout
    _authSub = _auth.authStateChanges.listen((user) async {
      if (user != null) {
        final remoteCounter = await _auth.getCounterFromFirestore();
        if (remoteCounter != null && remoteCounter > _counter) {
          setState(() {
            _counter = remoteCounter;
          });
          await _saveCounter();
        } else if (remoteCounter == null) {
          // Primo login, salva il counter locale su Firestore
          await _auth.saveCounterToFirestore(_counter);
        }
      } else {
        // Logout: azzera il counter sia in memoria che localmente
        setState(() {
          _counter = 0;
        });
        await _saveCounter();
      }
    });
    Sounds.playBackgroundMusic();
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

    // Salva su Firebase ogni 100
    if (_auth.currentUser != null && _counter % 100 == 0) {
      _auth.saveCounterToFirestore(_counter);
    }

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

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Confirm logout',
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
    if (result == true) {
      await _auth.signOut();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              // --- BLOCCA FUOCHI SE TAP SU LEADERBOARD ---
              final RenderBox? box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
              bool tappedLeaderboard = false;
              if (box != null) {
                final Offset local = box.globalToLocal(event.position);
                if (local.dx >= 0 &&
                    local.dy >= 0 &&
                    local.dx <= box.size.width &&
                    local.dy <= box.size.height) {
                  tappedLeaderboard = true;
                }
              }
              if (tappedLeaderboard) {
                // Tap sul pulsante leaderboard: non lanciare fuochi
                return;
              }
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
                particleCount = 20;
              } else if (activeFireworks == 1) {
                particleCount = 10;
              } else {
                particleCount = 4;
              }

              setState(() {
                _counter++;
              });
              _saveCounter();

              // Salva su Firebase ogni 100
              if (_auth.currentUser != null && _counter % 100 == 0) {
                _auth.saveCounterToFirestore(_counter);
              }

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
          // --- Bottone leaderboard a sinistra e login a destra ---
          Positioned(
            top: 48,
            left: 16,
            child: GestureDetector(
              key: _buttonKey,
              behavior: HitTestBehavior.translucent,
              onTap: () {
                ButtonsManager.onLeaderboardTap(context);
              },
              child: Image.asset(
                'assets/images/icons/leaderboardIcon.png',
                width: 52,
                height: 52,
              ),
            ),
          ),
          // --- Bottone login/logout a destra ---
          Positioned(
            top: 48,
            right: 16,
            child: StreamBuilder(
              stream: _auth.authStateChanges,
              builder: (context, snapshot) {
                final loggedIn = snapshot.hasData;
                if (loggedIn) {
                  return GestureDetector(
                    onTap: () async {
                      await _showLogoutDialog(context);
                    },
                    child: Image.asset(
                      'assets/images/icons/logoutIcon.png',
                      width: 52,
                      height: 52,
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      ButtonsManager.onLoginTap(context);
                    },
                    child: Image.asset(
                      'assets/images/icons/loginIcon.png',
                      width: 52,
                      height: 52,
                    ),
                  );
                }
              },
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
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    Sounds.stopBackgroundMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      Sounds.pauseBackgroundMusic();
    } else if (state == AppLifecycleState.resumed) {
      Sounds.resumeBackgroundMusic();
    }
  }
}
