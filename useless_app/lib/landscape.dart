import 'dart:math';
import 'package:flutter/material.dart';

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

class _LandscapeBackgroundState extends State<LandscapeBackground> {
  List<_StarData> _stars = [];
  Size? _lastSize;
  int _lastStarCount = 0;
  late int _sessionSeed;

  @override
  void initState() {
    super.initState();

    _sessionSeed = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeGenerateStars(force: true);
    });
  }

  @override
  void didUpdateWidget(LandscapeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeGenerateStars();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeGenerateStars(force: true);
  }

  void _maybeGenerateStars({bool force = false}) {
    final int starCount = widget.counter ~/ widget.starsPerStep;
    final Size size = widget.screenSize ?? MediaQuery.of(context).size;
    if (force || _stars.length != starCount || _lastSize != size) {
      _generateStars(starCount, size);
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

  @override
  Widget build(BuildContext context) {
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
