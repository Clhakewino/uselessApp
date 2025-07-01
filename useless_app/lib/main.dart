import 'dart:math';
import 'package:flutter/material.dart';

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

// --- FireworkEvent, FusePainter, ParticleData, ParticleWidget (rimangono sostanzialmente invariati dalla versione precedente senza commenti) ---
// (Per brevità, non li includo di nuovo qui, ma assumi che siano come nella versione precedente "senza commenti"
// con la correzione `late final fuseAnimation;` e l'uso corretto di vsync.)

class FireworkEvent {
  final Key id;
  final AnimationController fuseController;
  late final Animation<double> fuseAnimation;
  final Offset fuseStartPoint;
  final Offset fuseControlPoint;
  final Offset fuseEndPoint;

  final List<ParticleData> particles = [];
  bool hasExploded = false;
  final VoidCallback onRequestVisualUpdate;
  final Function(Key) onEventComplete;
  final Random random;
  final TickerProvider vsync;
  bool _isDisposed = false;

  FireworkEvent({
    required this.vsync,
    required this.random,
    required this.onRequestVisualUpdate,
    required this.onEventComplete,
    required Offset initialFireworkOrigin, // Modificato per chiarezza
    required Size screenSize,
  })  : id = UniqueKey(),
        fuseStartPoint = initialFireworkOrigin, // Usa la nuova origine
        fuseEndPoint = Offset(
          random.nextDouble() * screenSize.width,
          random.nextDouble() * screenSize.height * 0.7,
        ),
        fuseControlPoint = Offset(
          (initialFireworkOrigin.dx + (random.nextDouble() * screenSize.width)) / 2 +
              (random.nextDouble() - 0.5) * screenSize.width * 0.3,
          (initialFireworkOrigin.dy + (random.nextDouble() * screenSize.height * 0.7)) / 2 -
              random.nextDouble() * screenSize.height * 0.3,
        ),
        fuseController = AnimationController(
          duration: Duration(milliseconds: 1000 + random.nextInt(800)),
          vsync: vsync,
        ) {
    fuseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fuseController, curve: Curves.easeInOut),
    )..addListener(onRequestVisualUpdate);
    fuseController.addStatusListener(_onFuseStatusChanged);
  }

  void start() {
    if (_isDisposed) return;
    fuseController.forward();
  }

  void _onFuseStatusChanged(AnimationStatus status) {
    if (_isDisposed) return;
    if (status == AnimationStatus.completed) {
      if (!hasExploded) _createParticleExplosion();
      _checkCompletion();
    }
  }

  void _createParticleExplosion() {
    if (_isDisposed || hasExploded) return;
    hasExploded = true;
    for (int i = 0; i < 35 + random.nextInt(25); i++) {
      final particleCtrl = AnimationController(
        duration: Duration(milliseconds: 600 + random.nextInt(700)),
        vsync: vsync,
      );
      final particle = ParticleData(
        key: UniqueKey(),
        controller: particleCtrl,
        initialGlobalPosition: fuseEndPoint,
        random: random,
        onRequestVisualUpdate: onRequestVisualUpdate,
        onComplete: (particleKey) {
          if (_isDisposed) {
            try { particleCtrl.dispose(); } catch (e) {/*ignore*/}
            return;
          }
          particles.removeWhere((p) => p.key == particleKey);
          try { particleCtrl.dispose(); } catch (e) {/*ignore*/}
          _checkCompletion();
          if (!_isDisposed) onRequestVisualUpdate();
        },
      );
      particles.add(particle);
      if (!_isDisposed) particleCtrl.forward();
      else { try { particleCtrl.dispose(); } catch (e) {/*ignore*/} }
    }
    if (!_isDisposed) onRequestVisualUpdate();
  }

  void _checkCompletion() {
    if (_isDisposed) return;
    if (fuseController.status == AnimationStatus.completed && particles.isEmpty) {
      onEventComplete(id);
    }
  }

  Widget? buildFuseWidget() {
    if (_isDisposed || (fuseController.status == AnimationStatus.completed && hasExploded)) {
      return null;
    }
    return CustomPaint(
      painter: FusePainter(
        startPoint: fuseStartPoint,
        controlPoint: fuseControlPoint,
        endPoint: fuseEndPoint,
        progress: fuseAnimation.value,
      ),
      child: Container(),
    );
  }

  List<Widget> buildParticleWidgets() {
    if (_isDisposed) return [];
    return particles.map((p) => ParticleWidget(particleData: p)).toList();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      fuseController.removeListener(onRequestVisualUpdate);
      fuseController.removeStatusListener(_onFuseStatusChanged);
      fuseController.dispose();
    } catch (e) {/*ignore*/}
    for (var p in List.from(particles)) {
      try { p.controller.dispose(); } catch (e) {/*ignore*/}
    }
    particles.clear();
  }
}

class FusePainter extends CustomPainter {
  final Offset startPoint;
  final Offset controlPoint;
  final Offset endPoint;
  final double progress;

  FusePainter({
    required this.startPoint,
    required this.controlPoint,
    required this.endPoint,
    required this.progress,
  });

  Offset _getQuadraticBezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    return Offset(
        uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx,
        uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001 || progress >= 0.999) return;
    final paint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.8)
      ..strokeWidth = 3.0 // leggermente più spessa
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Path pathToDraw = Path()..moveTo(startPoint.dx, startPoint.dy);
    Offset currentFuseTip = _getQuadraticBezierPoint(startPoint, controlPoint, endPoint, progress);
    Offset intermediateControlPoint = Offset.lerp(startPoint, controlPoint, progress)!;
    pathToDraw.quadraticBezierTo(
      intermediateControlPoint.dx,
      intermediateControlPoint.dy,
      currentFuseTip.dx,
      currentFuseTip.dy,
    );
    canvas.drawPath(pathToDraw, paint);
    final sparkPaint = Paint()..color = Colors.yellowAccent..style = PaintingStyle.fill;
    canvas.drawCircle(currentFuseTip, 5.0, sparkPaint); // scintilla più grande
    final outerSparkPaint = Paint()..color = Colors.orange.withOpacity(0.7)..style = PaintingStyle.fill;
    canvas.drawCircle(currentFuseTip, 8.0, outerSparkPaint); // alone più grande
  }

  @override
  bool shouldRepaint(covariant FusePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.controlPoint != controlPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.progress != progress;
  }
}

class ParticleData {
  final Key key;
  final AnimationController controller;
  final Offset initialGlobalPosition;
  final Random random;
  final VoidCallback onRequestVisualUpdate;
  final Function(Key) onComplete;
  late final Animation<double> opacityAnimation;
  late final Animation<Offset> positionAnimation;
  final Color color;
  final double size;

  ParticleData({
    required this.key,
    required this.controller,
    required this.initialGlobalPosition,
    required this.random,
    required this.onRequestVisualUpdate,
    required this.onComplete,
  })  : color = Color.fromARGB(
    255,
    180 + random.nextInt(76), // Colori più vivaci
    100 + random.nextInt(156),
    50 + random.nextInt(156),
  ).withBlue(50 + random.nextInt(100)).withGreen(100 + random.nextInt(155)), // Più varietà
        size = 3.5 + random.nextDouble() * 6.0 { // Particelle leggermente più grandi
    opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    final angle = random.nextDouble() * 2 * pi;
    final distance = 70.0 + random.nextDouble() * 130.0; // Esplosione più ampia
    positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(cos(angle) * distance, sin(angle) * distance),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutQuad));
    controller.addListener(onRequestVisualUpdate);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) onComplete(key);
    });
  }
}

class ParticleWidget extends StatelessWidget {
  final ParticleData particleData;
  const ParticleWidget({required this.particleData, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: particleData.controller,
      builder: (context, child) {
        if (particleData.controller.status == AnimationStatus.dismissed &&
            particleData.opacityAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: particleData.initialGlobalPosition.dx + particleData.positionAnimation.value.dx - (particleData.size / 2),
          top: particleData.initialGlobalPosition.dy + particleData.positionAnimation.value.dy - (particleData.size / 2),

          child: Opacity(
            opacity: particleData.opacityAnimation.value.clamp(0.0, 1.0),
            child: Container(
              width: particleData.size,
              height: particleData.size,
              decoration: BoxDecoration(
                color: particleData.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: particleData.color.withOpacity(0.6), // Ombra più pronunciata
                    blurRadius: particleData.size * 0.8, // Blur relativo alla dimensione
                    spreadRadius: particleData.size * 0.2,
                  )
                ],
              ),
            ),
          ),
        );
      },
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
  FireworkEvent? _currentFirework;
  final Random _random = Random();
  final GlobalKey _buttonKey = GlobalKey();
  bool _isButtonPressed = false;

  void _launchNewFirework() {
    if (_currentFirework != null && !_currentFirework!._isDisposed) {
      _currentFirework!.dispose();
    }

    final RenderBox? buttonRenderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonRenderBox == null || !mounted) return;

    final buttonSize = buttonRenderBox.size;
    final buttonCenterGlobal = buttonRenderBox.localToGlobal(buttonSize.center(Offset.zero));

    // Offset per far partire i fuochi da "dietro" e leggermente più in basso del centro
    final fireworkOrigin = Offset(buttonCenterGlobal.dx, buttonCenterGlobal.dy + buttonSize.height * 0.3);


    final screenSize = MediaQuery.of(context).size;

    setState(() {
      _currentFirework = FireworkEvent(
        vsync: this,
        random: _random,
        onRequestVisualUpdate: () {
          if (mounted) setState(() {});
        },
        onEventComplete: (eventId) {
          if (mounted && _currentFirework?.id == eventId) {
            _currentFirework?.dispose();
            setState(() {
              _currentFirework = null;
            });
          }
        },
        initialFireworkOrigin: fireworkOrigin, // Modificato qui
        screenSize: screenSize,
      );
      _currentFirework!.start();
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
          // 1. Miccia sotto il pulsante
          if (_currentFirework != null && _currentFirework!.buildFuseWidget() != null)
            _currentFirework!.buildFuseWidget()!,
          // 2. Pulsante
          Center(
            child: GestureDetector(
              key: _buttonKey,
              onTapDown: (_) {
                setState(() {
                  _isButtonPressed = true;
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isButtonPressed = false;
                });
                _launchNewFirework();
              },
              onTapCancel: () {
                setState(() {
                  _isButtonPressed = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(buttonScale),
                transformAlignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [topColor, bottomColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(buttonDepth, buttonDepth),
                      blurRadius: buttonDepth * 1.5,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.red.shade200.withOpacity(0.7),
                      offset: Offset(-buttonDepth / 2, -buttonDepth / 2),
                      blurRadius: buttonDepth,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset.zero,
                      blurRadius: 5,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: const Text(
                  'Lancia Fuoco!',
                  style: TextStyle(
                      fontSize: 20,
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
          // 3. Particelle sopra il pulsante
          if (_currentFirework != null) ..._currentFirework!.buildParticleWidgets(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentFirework?.dispose();
    super.dispose();
  }
}