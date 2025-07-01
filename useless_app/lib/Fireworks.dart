import 'dart:math';
import 'package:flutter/material.dart';

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

  final Color fuseColor;

  static List<Color> fuseColors = [
    Colors.yellowAccent,
    Color(0xFF0382F1),
    Colors.white,
    Color(0xFFE800EF),
    Color(0xFFED0A0A),
  ];

  final int particleCount;

  AnimationController? _trailFadeController;
  Animation<double>? _trailFadeAnimation;
  bool _showTrail = true;

  FireworkEvent({
    required this.vsync,
    required this.random,
    required this.onRequestVisualUpdate,
    required this.onEventComplete,
    required Offset initialFireworkOrigin,
    required Size screenSize,
    required this.particleCount,
  })  : id = UniqueKey(),
        fuseColor = fuseColors[random.nextInt(fuseColors.length)],
        fuseStartPoint = initialFireworkOrigin,
        fuseEndPoint = Offset(
          (0.05 + random.nextDouble() * 0.9) * screenSize.width,
          random.nextDouble() * screenSize.height * 0.80 + 100.0,
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
      if (!hasExploded) {
        _createParticleExplosion();
        _startTrailFade();
      }
      _checkCompletion();
    }
  }

  void _startTrailFade() {
    if (_trailFadeController != null) return;
    final fadeDuration = Duration(
      milliseconds: 500 + random.nextInt(1000),
    );
    _trailFadeController = AnimationController(
      duration: fadeDuration,
      vsync: vsync,
    );
    _trailFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _trailFadeController!, curve: Curves.easeOut),
    )..addListener(onRequestVisualUpdate);
    _trailFadeController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showTrail = false;
        onRequestVisualUpdate();
        _checkCompletion();
      }
    });
    _trailFadeController!.forward();
  }

  void _createParticleExplosion() {
    if (_isDisposed || hasExploded) return;
    hasExploded = true;
    for (int i = 0; i < particleCount; i++) {
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
          particles.removeWhere((p) => p.key == particleKey);
          try { particleCtrl.dispose(); } catch (e) {/*ignore*/}
          if (!_isDisposed) onRequestVisualUpdate();
          _checkCompletion();
        },
        color: ParticleData.particleColors[random.nextInt(ParticleData.particleColors.length)],
      );
      particles.add(particle);
      if (!_isDisposed) {
        particleCtrl.forward();
      }
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
    if (_isDisposed) return null;
    // Mostra la scia solo se non è stata completamente dissolta
    if (!_showTrail) return null;
    double fade = 1.0;
    if (fuseController.status == AnimationStatus.completed && _trailFadeAnimation != null) {
      fade = _trailFadeAnimation!.value;
      if (fade <= 0.01) return null;
    }
    return CustomPaint(
      painter: FusePainter(
        startPoint: fuseStartPoint,
        controlPoint: fuseControlPoint,
        endPoint: fuseEndPoint,
        progress: fuseAnimation.value,
        fuseColor: fuseColor,
        fade: fade,
        showFullTrail: fuseController.status == AnimationStatus.completed,
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
    if (_trailFadeController != null) {
      try {
        _trailFadeController!.dispose();
      } catch (e) {/*ignore*/}
    }
    for (var p in List.from(particles)) {
      try { p.controller.dispose(); } catch (e) {/*ignore*/}
    }
    particles.clear();
  }
}

// Modifica FusePainter per supportare la dissolvenza e la scia completa dopo l'esplosione
class FusePainter extends CustomPainter {
  final Offset startPoint;
  final Offset controlPoint;
  final Offset endPoint;
  final double progress;
  final Color fuseColor;
  final double fade;
  final bool showFullTrail;

  FusePainter({
    required this.startPoint,
    required this.controlPoint,
    required this.endPoint,
    required this.progress,
    required this.fuseColor,
    this.fade = 1.0,
    this.showFullTrail = false,
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
    double drawProgress = showFullTrail ? 1.0 : progress;
    if (drawProgress <= 0.001) return;

    int steps = 20;
    double fadeLength = 0.35;
    double fadeStart = drawProgress * (1 - fadeLength);
    double fadeEnd = drawProgress;

    for (int i = 0; i < steps; i++) {
      double t0 = (i / steps) * drawProgress;
      double t1 = ((i + 1) / steps) * drawProgress;
      if (t1 > drawProgress) t1 = drawProgress;
      if (t0 >= t1) continue;

      Offset p0 = _getQuadraticBezierPoint(startPoint, controlPoint, endPoint, t0);
      Offset p1 = _getQuadraticBezierPoint(startPoint, controlPoint, endPoint, t1);

      double alpha;
      if (t1 >= fadeStart) {
        double fadeT = ((t1 - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);
        alpha = (1.0 - fadeT) * 0.85 * fade;
      } else {
        alpha = 0.85 * fade;
      }

      final paint = Paint()
        ..color = fuseColor.withValues(alpha: alpha)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p0, p1, paint);
    }

    // Disegna la scintilla solo se la miccia non è completamente esplosa
    if (!showFullTrail) {
      Offset currentFuseTip = _getQuadraticBezierPoint(startPoint, controlPoint, endPoint, progress);
      final sparkPaint = Paint()..color = Colors.white.withValues(alpha: fade)..style = PaintingStyle.fill;
      canvas.drawCircle(currentFuseTip, 5.0, sparkPaint);
      final outerSparkPaint = Paint()..color = fuseColor.withValues(alpha: 0.7 * fade)..style = PaintingStyle.fill;
      canvas.drawCircle(currentFuseTip, 8.0, outerSparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FusePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.controlPoint != controlPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.progress != progress ||
        oldDelegate.fade != fade ||
        oldDelegate.showFullTrail != showFullTrail;
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

  static const List<Color> particleColors = [
    Colors.yellow,
    Colors.cyan,
    Colors.pink,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.white,
  ];

  ParticleData({
    required this.key,
    required this.controller,
    required this.initialGlobalPosition,
    required this.random,
    required this.onRequestVisualUpdate,
    required this.onComplete,
    required this.color,
  })  : size = 3.5 + random.nextDouble() * 6.0 {
    opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    final angle = random.nextDouble() * 2 * pi;
    final distance = 70.0 + random.nextDouble() * 130.0;
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
            opacity: particleData.opacityAnimation.value.clamp(0.7, 1.0),
            child: Container(
              width: particleData.size,
              height: particleData.size,
              decoration: BoxDecoration(
                color: particleData.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: particleData.color.withValues(alpha: 0.8),
                    blurRadius: particleData.size * 0.8,
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