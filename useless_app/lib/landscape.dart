import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';

class LandscapeBackground extends StatefulWidget {
  final int counter;
  final int starsPerStep;
  final Size? screenSize;

  const LandscapeBackground({
    Key? key,
    required this.counter,
    this.starsPerStep = 300,
    this.screenSize,
  }) : super(key: key);

  @override
  State<LandscapeBackground> createState() => _LandscapeBackgroundState();
}

class _LandscapeBackgroundState extends State<LandscapeBackground> with SingleTickerProviderStateMixin {
  List<_StarData> _stars = [];
  List<_FlowerData> _flowers = [];
  List<_CloudData> _clouds = [];
  List<_FallingStarData> _fallingStars = [];
  Size? _lastSize;
  int _lastStarCount = 0;
  int _lastFlowerCount = 0;
  int _lastCloudCount = 0;
  late int _sessionSeed;
  Offset? _moonPosition;
  String? _moonAsset;
  double? _moonRotation;

  late AnimationController _cloudAnimController;
  Timer? _fallingStarTimer;

  @override
  void initState() {
    super.initState();

    _sessionSeed = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeGenerateStars(force: true);
      _maybeGenerateFlowers(force: true);
      _maybeGenerateMoon(force: true);
      _maybeGenerateClouds(force: true);
    });

    _cloudAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(() {
        setState(() {});
      });
    _cloudAnimController.repeat();

    _maybeStartFallingStars();
  }

  @override
  void dispose() {
    _cloudAnimController.dispose();
    _fallingStarTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LandscapeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeGenerateStars();
    _maybeGenerateFlowers();
    _maybeGenerateMoon();
    _maybeGenerateClouds();
    _maybeStartFallingStars();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeGenerateStars(force: true);
    _maybeGenerateFlowers(force: true);
    _maybeGenerateMoon(force: true);
    _maybeGenerateClouds(force: true);
    _maybeStartFallingStars();
  }

  void _maybeGenerateStars({bool force = false}) {
    final int starCount = widget.counter ~/ widget.starsPerStep;
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    if (force || _stars.length != starCount || _lastSize != size) {
      _generateStars(starCount, size);
    }
  }

  void _maybeGenerateFlowers({bool force = false}) {
    if (widget.counter < 600) {
      if (_flowers.isNotEmpty) {
        _flowers = [];
        if (mounted) setState(() {});
      }
      return;
    }
    final int flowerCount = 1 + ((widget.counter - 600) ~/ 350);
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    if (force || _flowers.length != flowerCount || _lastSize != size) {
      _generateFlowers(flowerCount, size);
    }
  }

  void _maybeGenerateMoon({bool force = false}) {
    if (widget.counter < 1500) {
      if (_moonPosition != null || _moonAsset != null || _moonRotation != null) {
        _moonPosition = null;
        _moonAsset = null;
        _moonRotation = null;
        if (mounted) setState(() {});
      }
      return;
    }
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    if (_moonPosition == null || _moonAsset == null || _moonRotation == null || force || _lastSize != size) {
      final Random random = Random(_sessionSeed + 999999);
      // Scegli asset random
      final List<String> moonAssets = [
        'assets/images/moon/luna1.png',
        'assets/images/moon/luna2.png',
        'assets/images/moon/luna3.png',
      ];
      _moonAsset = moonAssets[random.nextInt(moonAssets.length)];
      // Posizione random nella metà superiore dello schermo
      final double moonWidth = 90;
      final double moonHeight = 90;
      final double left = random.nextDouble() * (size.width - moonWidth);
      final double top = random.nextDouble() * ((size.height * 0.5) - moonHeight);
      _moonPosition = Offset(left, top);
      _moonRotation = (random.nextDouble() * 30 - 15) * (pi / 180);
      _lastSize = size;
      if (mounted) setState(() {});
    }
  }

  void _maybeGenerateClouds({bool force = false}) {
    int cloudCount = 0;
    if (widget.counter >= 2000) {
      cloudCount = 1 + ((widget.counter - 2000) ~/ 1500);
    }
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    if (force || _clouds.length != cloudCount || _lastSize != size) {
      _generateClouds(cloudCount, size);
    }
  }

  void _generateStars(int starCount, Size size) {
    final Random random = Random(_sessionSeed);
    final double minTop = 0;
    final double maxTop = size.height * 0.8 - 24;
    _stars = List.generate(starCount, (i) {
      final double left = random.nextDouble() * (size.width - 24);
      final double top = minTop + random.nextDouble() * (maxTop - minTop);
      final double starSize = 12.0 + random.nextDouble() * 10.0;
      final int points = [4, 6, 8][random.nextInt(3)];
      final double angle = random.nextDouble() * (pi / 2);
      return _StarData(
        left: left,
        top: top,
        size: starSize,
        points: points,
        angle: angle,
      );
    });
    _lastStarCount = starCount;
    _lastSize = size;
    if (mounted) setState(() {});
  }

  void _generateFlowers(int flowerCount, Size size) {
    final Random random = Random(_sessionSeed + 424242); // seed diverso da stelle
    final List<String> flowerAssets = [
      'assets/images/flawers/fiore1.png',
      'assets/images/flawers/fiore2.png',
      'assets/images/flawers/fiore3.png',
      'assets/images/flawers/fiore4.png',
      'assets/images/flawers/fiore5.png',
    ];
    _flowers = List.generate(flowerCount, (i) {
      int zIndex = random.nextInt(3); // 0 = dietro prato3, 1 = tra prato2 e prato3, 2 = tra prato1 e prato2
      double left = random.nextDouble() * (size.width - 80);
      double bottom;
      if (zIndex == 0) {
        double minBottom = size.height * 0.04;
        double maxBottom = size.height * 0.045;
        bottom = minBottom + random.nextDouble() * (maxBottom - minBottom);
      } else if (zIndex == 1) {
        double minBottom = size.height * 0.02;
        double maxBottom = size.height * 0.03;
        bottom = minBottom + random.nextDouble() * (maxBottom - minBottom);
      } else {
        double minBottom = -10;
        double maxBottom = size.height * 0.00;
        bottom = minBottom + random.nextDouble() * (maxBottom - minBottom);
      }
      double scale = 0.3 + random.nextDouble() * 0.3;
      String asset = flowerAssets[random.nextInt(flowerAssets.length)];
      return _FlowerData(left: left, bottom: bottom, zIndex: zIndex, scale: scale, asset: asset);
    });
    _lastFlowerCount = flowerCount;
    _lastSize = size;
    if (mounted) setState(() {});
  }

  void _generateClouds(int cloudCount, Size size) {
    final Random random = Random(_sessionSeed + 888888);
    final List<String> cloudAssets = [
      'assets/images/clouds/nuvola1.png',
      'assets/images/clouds/nuvola2.png',
      'assets/images/clouds/nuvola3.png',
      'assets/images/clouds/nuvola4.png',
      'assets/images/clouds/nuvola5.png',
    ];
    int visibleClouds = (cloudCount / 2).ceil();
    _clouds = List.generate(cloudCount, (i) {
      String asset = cloudAssets[random.nextInt(cloudAssets.length)];
      double baseWidth = 200.0;
      double scale = 0.7 + random.nextDouble() * 0.3; // tra 0.7 e 1.0
      double width = baseWidth * scale;
      double height = width * (0.45 + random.nextDouble() * 0.2);
      bool fromLeft = random.nextBool();
      double left;
      if (i < visibleClouds) {
        // Già visibile a schermo
        left = random.nextDouble() * (size.width - width);
      } else {
        // Fuori dallo schermo a sinistra o destra
        left = fromLeft ? -width - random.nextDouble() * 100 : size.width + random.nextDouble() * 100;
      }
      double top = random.nextDouble() * ((size.height * 0.5) - height);
      int zIndex = 1;
      double opacity = 0.65 + random.nextDouble() * 0.35;
      double speed = 1.2 + random.nextDouble() * 1.6;
      bool leftToRight = fromLeft;
      return _CloudData(
        left: left,
        top: top,
        width: width,
        height: height,
        asset: asset,
        zIndex: zIndex,
        opacity: opacity,
        speed: speed,
        leftToRight: leftToRight,
        id: random.nextInt(1 << 32),
      );
    });
    _lastCloudCount = cloudCount;
    _lastSize = size;
    if (mounted) setState(() {});
  }

  void _moveClouds(Size size) {
    final double elapsed = _cloudAnimController.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0;
    final double dt = 1 / 60.0; // approx 60fps
    for (int i = 0; i < _clouds.length; i++) {
      final cloud = _clouds[i];
      double dx = cloud.speed * dt * (cloud.leftToRight ? 1 : -1);
      double newLeft = cloud.left + dx;
      bool outOfScreen = cloud.leftToRight
          ? newLeft > size.width
          : newLeft + cloud.width < 0;
      if (outOfScreen) {
        // Rimpiazza la nuvola con una nuova che parte dall'altro lato
        final Random random = Random(_sessionSeed + 888888 + DateTime.now().millisecondsSinceEpoch + i);
        String asset = [
          'assets/images/clouds/nuvola1.png',
          'assets/images/clouds/nuvola2.png',
          'assets/images/clouds/nuvola3.png',
          'assets/images/clouds/nuvola4.png',
          'assets/images/clouds/nuvola5.png',
        ][random.nextInt(5)];
        double baseWidth = 200.0;
        double scale = 0.7 + random.nextDouble() * 0.3;
        double width = baseWidth * scale;
        double height = width * (0.45 + random.nextDouble() * 0.2);
        bool fromLeft = !cloud.leftToRight;
        double left = fromLeft ? -width - random.nextDouble() * 100 : size.width + random.nextDouble() * 100;
        double top = random.nextDouble() * ((size.height * 0.5) - height);
        double opacity = 0.65 + random.nextDouble() * 0.35;
        double speed = 1.2 + random.nextDouble() * 1.6;
        bool leftToRight = fromLeft;
        _clouds[i] = _CloudData(
          left: left,
          top: top,
          width: width,
          height: height,
          asset: asset,
          zIndex: 1,
          opacity: opacity,
          speed: speed,
          leftToRight: leftToRight,
          id: random.nextInt(1 << 32),
        );
      } else {
        _clouds[i] = cloud.copyWith(left: newLeft);
      }
    }
  }

  void _maybeStartFallingStars() {
    // Avvia o ferma il timer in base al counter
    if (widget.counter > 3000) {
      if (_fallingStarTimer == null || !_fallingStarTimer!.isActive) {
        _fallingStarTimer?.cancel();
        _fallingStarTimer = Timer.periodic(const Duration(seconds: 20), (_) {
          if (mounted && widget.counter > 3000) {
            _addFallingStar();
          }
        });
      }
    } else {
      _fallingStarTimer?.cancel();
      _fallingStarTimer = null;
      if (_fallingStars.isNotEmpty) {
        setState(() {
          _fallingStars.clear();
        });
      }
    }
  }

  void _addFallingStar() {
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    final Random random = Random(_sessionSeed + DateTime.now().millisecondsSinceEpoch);
    final double startX = random.nextDouble() * (size.width * 0.5);
    final double startY = random.nextDouble() * (size.height * 0.3);

    // Angolo random tra 45° e 0°
    final double angle = (0) + random.nextDouble() * (pi / 4);

    final double trailLength = size.width * (2.5 + random.nextDouble() * 0.7);
    final double dx = cos(angle) * trailLength;
    final double dy = sin(angle) * trailLength;
    final double endX = startX + dx;
    final double endY = startY + dy;
    final double duration = 1.3 + random.nextDouble() * 0.7; // più veloce: tra 1.3 e 2.0 secondi

    final fallingStar = _FallingStarData(
      start: Offset(startX, startY),
      end: Offset(endX, endY),
      startTime: DateTime.now(),
      duration: duration,
      size: 10 + random.nextDouble() * 6, // più piccola per scia sottile
      angle: angle,
    );
    setState(() {
      _fallingStars.add(fallingStar);
    });

    Future.delayed(Duration(milliseconds: (duration * 1000).toInt() + 300), () {
      _fallingStars.remove(fallingStar);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    _moveClouds(size);

    List<Widget> children = _stars.map((star) {
      return Positioned(
        left: star.left,
        top: star.top,
        child: Transform.rotate(
          angle: star.angle,
          child: CustomPaint(
            size: Size(star.size, star.size),
            painter: _SharpMultiPointStarPainter(points: star.points),
          ),
        ),
      );
    }).toList();

    // --- LUNA ---
    if (_moonPosition != null && _moonAsset != null) {
      children.add(Positioned(
        left: _moonPosition!.dx,
        top: _moonPosition!.dy,
        child: Transform.rotate(
          angle: _moonRotation ?? 0,
          child: Image.asset(
            _moonAsset!,
            width: 90,
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
      ));
    }

    // --- NUVOLE --- (sempre davanti alla luna, ora più scure e animate)
    for (final cloud in _clouds) {
      children.add(Positioned(
        left: cloud.left,
        top: cloud.top,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFFCACACA),
            BlendMode.modulate,
          ),
          child: Opacity(
            opacity: cloud.opacity,
            child: Image.asset(
              cloud.asset,
              width: cloud.width,
              height: cloud.height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ));
    }

    // --- STELLE CADENTI ---
    for (final fallingStar in _fallingStars) {
      children.add(Positioned(
        left: fallingStar.start.dx,
        top: fallingStar.start.dy,
        child: CustomPaint(
          size: Size(fallingStar.end.dx - fallingStar.start.dx, fallingStar.end.dy - fallingStar.start.dy),
          painter: _FallingStarPainter(fallingStar: fallingStar),
        ),
      ));
    }

    // Visualizza i tre prati solo se il counter è almeno 450
    if (widget.counter >= 450) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenHeight = MediaQuery.of(context).size.height;

      // Prato 3 (dietro)
      children.add(Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Image.asset(
          'assets/images/prato3.png',
          width: screenWidth,
          fit: BoxFit.fitWidth,
        ),
      ));

      // Prato 2 (in mezzo)
      children.add(Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Image.asset(
          'assets/images/prato2.png',
          width: screenWidth,
          fit: BoxFit.fitWidth,
        ),
      ));

      // Prato 1 (davanti)
      children.add(Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Image.asset(
          'assets/images/prato1.png',
          width: screenWidth,
          fit: BoxFit.fitWidth,
        ),
      ));

      // FIORI: usa _flowers generati solo se counter >= 600
      if (_flowers.isNotEmpty) {
        // Ordina per zIndex per il corretto stacking (0 dietro, 1 in mezzo, 2 davanti)
        final sortedFlowers = List<_FlowerData>.from(_flowers)
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        for (final flower in sortedFlowers) {
          int insertIndex;
          if (flower.zIndex == 0) {
            insertIndex = children.indexWhere((w) =>
                w is Positioned &&
                (w.child is Image &&
                    (w.child as Image).image is AssetImage &&
                    ((w.child as Image).image as AssetImage).assetName == 'assets/images/prato3.png'));
          } else if (flower.zIndex == 1) {
            insertIndex = children.indexWhere((w) =>
                w is Positioned &&
                (w.child is Image &&
                    (w.child as Image).image is AssetImage &&
                    ((w.child as Image).image as AssetImage).assetName == 'assets/images/prato3.png')) + 1;
          } else {
            insertIndex = children.indexWhere((w) =>
                w is Positioned &&
                (w.child is Image &&
                    (w.child as Image).image is AssetImage &&
                    ((w.child as Image).image as AssetImage).assetName == 'assets/images/prato2.png')) + 1;
          }
          children.insert(
            insertIndex,
            Positioned(
              left: flower.left,
              bottom: flower.bottom,
              child: Transform.scale(
                scale: flower.scale,
                child: Image.asset(
                  flower.asset,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }
      }
    }

    return Stack(
      children: children,
    );
  }
}

class _StarData {
  final double left;
  final double top;
  final double size;
  final int points;
  final double angle;
  _StarData({
    required this.left,
    required this.top,
    required this.size,
    required this.points,
    required this.angle,
  });
}

// Aggiorna la classe _FlowerData per includere l'asset
class _FlowerData {
  final double left;
  final double bottom;
  final int zIndex;
  final double scale;
  final String asset;
  _FlowerData({
    required this.left,
    required this.bottom,
    required this.zIndex,
    required this.scale,
    required this.asset,
  });
}

class _CloudData {
  final double left;
  final double top;
  final double width;
  final double height;
  final String asset;
  final int zIndex;
  final double opacity;
  final double speed;
  final bool leftToRight;
  final int id;
  _CloudData({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.asset,
    required this.zIndex,
    required this.opacity,
    required this.speed,
    required this.leftToRight,
    required this.id,
  });

  _CloudData copyWith({double? left}) => _CloudData(
        left: left ?? this.left,
        top: top,
        width: width,
        height: height,
        asset: asset,
        zIndex: zIndex,
        opacity: opacity,
        speed: speed,
        leftToRight: leftToRight,
        id: id,
      );
}

// Dati per la stella cadente
class _FallingStarData {
  final Offset start;
  final Offset end;
  final DateTime startTime;
  final double duration;
  final double size;
  final double angle;
  _FallingStarData({
    required this.start,
    required this.end,
    required this.startTime,
    required this.duration,
    required this.size,
    required this.angle,
  });
}

// Painter per la stella cadente e la scia
class _FallingStarPainter extends CustomPainter {
  final _FallingStarData fallingStar;
  _FallingStarPainter({required this.fallingStar});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final elapsed = now.difference(fallingStar.startTime).inMilliseconds / 1000.0;
    final t = (elapsed / fallingStar.duration).clamp(0.0, 1.0);

    final Offset pos = Offset(
      fallingStar.start.dx + (fallingStar.end.dx - fallingStar.start.dx) * t,
      fallingStar.start.dy + (fallingStar.end.dy - fallingStar.start.dy) * t,
    );
    final Offset tail = Offset(
      fallingStar.start.dx + (fallingStar.end.dx - fallingStar.start.dx) * (t - 0.25).clamp(0.0, 1.0),
      fallingStar.start.dy + (fallingStar.end.dy - fallingStar.start.dy) * (t - 0.25).clamp(0.0, 1.0),
    );

    final Paint trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.7),
        ],
      ).createShader(Rect.fromPoints(tail, pos))
      ..strokeWidth = fallingStar.size * 0.28 // scia più sottile
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(tail, pos, trailPaint);

    final Paint starPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); // meno glow

    canvas.drawCircle(pos, fallingStar.size * 0.28, starPaint); // stella più piccola
  }

  @override
  bool shouldRepaint(covariant _FallingStarPainter oldDelegate) => true;
}

class _SharpMultiPointStarPainter extends CustomPainter {
  final int points;
  _SharpMultiPointStarPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double rLong = size.width / 2;
    double rShort = rLong;

    if (points == 6) {
      rShort = rLong * 0.7;
    } else if (points == 8) {
      rShort = rLong * 0.5;
    }

    if (points == 4) {
      // 4 punte appuntite (tipo rosa dei venti)
      for (int i = 0; i < 4; i++) {
        final double angle = (pi / 2) * i;
        final double tipX = cx + rLong * cos(angle);
        final double tipY = cy + rLong * sin(angle);
        final double baseLeftX = cx + rLong * 0.25 * cos(angle - pi / 12);
        final double baseLeftY = cy + rLong * 0.25 * sin(angle - pi / 12);
        final double baseRightX = cx + rLong * 0.25 * cos(angle + pi / 12);
        final double baseRightY = cy + rLong * 0.25 * sin(angle + pi / 12);

        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(baseLeftX, baseLeftY)
          ..lineTo(tipX, tipY)
          ..lineTo(baseRightX, baseRightY)
          ..close();
        canvas.drawPath(path, paint);
      }
    } else if (points == 6) {
      for (int i = 0; i < 4; i++) {
        final double angle = (pi / 4) * (i * 2 + 1);
        final double tipX = cx + rLong * cos(angle);
        final double tipY = cy + rLong * sin(angle);
        final double baseLeftX = cx + rLong * 0.23 * cos(angle - pi / 16);
        final double baseLeftY = cy + rLong * 0.23 * sin(angle - pi / 16);
        final double baseRightX = cx + rLong * 0.23 * cos(angle + pi / 16);
        final double baseRightY = cy + rLong * 0.23 * sin(angle + pi / 16);

        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(baseLeftX, baseLeftY)
          ..lineTo(tipX, tipY)
          ..lineTo(baseRightX, baseRightY)
          ..close();
        canvas.drawPath(path, paint);
      }

      for (int i = 0; i < 2; i++) {
        final double angle = pi * i;
        final double tipX = cx + rShort * cos(angle);
        final double tipY = cy + rShort * sin(angle);
        final double baseLeftX = cx + rShort * 0.23 * cos(angle - pi / 16);
        final double baseLeftY = cy + rShort * 0.23 * sin(angle - pi / 16);
        final double baseRightX = cx + rShort * 0.23 * cos(angle + pi / 16);
        final double baseRightY = cy + rShort * 0.23 * sin(angle + pi / 16);

        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(baseLeftX, baseLeftY)
          ..lineTo(tipX, tipY)
          ..lineTo(baseRightX, baseRightY)
          ..close();
        canvas.drawPath(path, paint);
      }
    } else if (points == 8) {

      for (int i = 0; i < 8; i++) {
        final double angle = (pi / 4) * i;
        final bool isDiagonal = i % 2 == 1;
        final double len = isDiagonal ? rShort : rLong;
        final double tipX = cx + len * cos(angle);
        final double tipY = cy + len * sin(angle);
        final double baseLeftX = cx + len * 0.23 * cos(angle - pi / 20);
        final double baseLeftY = cy + len * 0.23 * sin(angle - pi / 20);
        final double baseRightX = cx + len * 0.23 * cos(angle + pi / 20);
        final double baseRightY = cy + len * 0.23 * sin(angle + pi / 20);

        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(baseLeftX, baseLeftY)
          ..lineTo(tipX, tipY)
          ..lineTo(baseRightX, baseRightY)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
