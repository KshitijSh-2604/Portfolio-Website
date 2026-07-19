import 'dart:math';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherOverlay extends StatefulWidget {
  final WeatherCondition condition;
  final Offset mousePosition;
  const WeatherOverlay({super.key, required this.condition, required this.mousePosition});

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  late AnimationController _flashController;
  late AnimationController _nebulaController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _nebulaController = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _scheduleFlash();
  }

  void _scheduleFlash() {
    if (widget.condition == WeatherCondition.thunderstorm || widget.condition == WeatherCondition.rainThunder) {
      Future.delayed(Duration(seconds: 2 + Random().nextInt(6)), () {
        if (mounted) {
          _flashController.forward().then((_) {
            _flashController.reverse();
            _scheduleFlash();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(WeatherOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition != widget.condition) {
      if (widget.condition == WeatherCondition.thunderstorm || widget.condition == WeatherCondition.rainThunder) _scheduleFlash();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    _flashController.dispose();
    _nebulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _glowController, _flashController, _nebulaController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _WeatherPainter(
            condition: widget.condition,
            mousePosition: widget.mousePosition,
            progress: _controller.value,
            glowProgress: _glowController.value,
            flashProgress: _flashController.value,
            nebulaProgress: _nebulaController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, speed, size, opacity;
  double? angle;
  _Particle({required this.x, required this.y, required this.speed, required this.size, required this.opacity, this.angle});
}

class _WeatherPainter extends CustomPainter {
  final WeatherCondition condition;
  final Offset mousePosition;
  final double progress;
  final double glowProgress;
  final double flashProgress;
  final double nebulaProgress;

  static final List<_Particle> _rainParticles = List.generate(150, (i) {
    final rand = Random(i * 17 + 3);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      speed: 0.6 + rand.nextDouble() * 0.8,
      size: 1.0 + rand.nextDouble() * 1.5,
      opacity: 0.2 + rand.nextDouble() * 0.4,
    );
  });

  static final List<_Particle> _snowParticles = List.generate(100, (i) {
    final rand = Random(i * 31 + 7);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      speed: 0.08 + rand.nextDouble() * 0.12,
      size: 2 + rand.nextDouble() * 5,
      opacity: 0.3 + rand.nextDouble() * 0.5,
      angle: rand.nextDouble() * pi * 2,
    );
  });

  static final List<_Particle> _stars = List.generate(80, (i) {
    final rand = Random(i * 43);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      speed: 0.02 + rand.nextDouble() * 0.05,
      size: 0.5 + rand.nextDouble() * 1.5,
      opacity: 0.1 + rand.nextDouble() * 0.6,
    );
  });

  static final List<_Particle> _mistParticles = List.generate(200, (i) {
    final rand = Random(i * 47);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      speed: 0.01 + rand.nextDouble() * 0.03,
      size: 0.5 + rand.nextDouble() * 1.5,
      opacity: 0.1 + rand.nextDouble() * 0.3,
    );
  });

  static final List<_Particle> _hazeParticles = List.generate(100, (i) {
    final rand = Random(i * 53);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      speed: 0.005 + rand.nextDouble() * 0.015,
      size: 1.0 + rand.nextDouble() * 2.5,
      opacity: 0.1 + rand.nextDouble() * 0.4,
    );
  });

  // Layered Cloud System (Higher density and opacity for better visibility)
  static final List<_Particle> _foregroundClouds = List.generate(5, (i) {
    final rand = Random(i * 101 + 1);
    return _Particle(
      x: rand.nextDouble(),
      y: 0.05 + rand.nextDouble() * 0.25,
      speed: 0.002 + rand.nextDouble() * 0.004,
      size: 400 + rand.nextDouble() * 500,
      opacity: 0.25 + rand.nextDouble() * 0.15,
    );
  });

  static final List<_Particle> _midgroundClouds = List.generate(8, (i) {
    final rand = Random(i * 202 + 2);
    return _Particle(
      x: rand.nextDouble(),
      y: 0.1 + rand.nextDouble() * 0.35,
      speed: 0.005 + rand.nextDouble() * 0.007,
      size: 250 + rand.nextDouble() * 350,
      opacity: 0.18 + rand.nextDouble() * 0.1,
    );
  });

  static final List<_Particle> _backgroundClouds = List.generate(12, (i) {
    final rand = Random(i * 303 + 3);
    return _Particle(
      x: rand.nextDouble(),
      y: 0.0 + rand.nextDouble() * 0.5,
      speed: 0.01 + rand.nextDouble() * 0.012,
      size: 150 + rand.nextDouble() * 200,
      opacity: 0.12 + rand.nextDouble() * 0.08,
    );
  });

  static final List<_Particle> _birds = List.generate(6, (i) {
    final rand = Random(i * 404 + 4);
    return _Particle(
      x: -0.2 - rand.nextDouble() * 2.0,
      y: 0.1 + rand.nextDouble() * 0.4,
      speed: 0.007 + rand.nextDouble() * 0.01,
      size: 14 + rand.nextDouble() * 10,
      opacity: 0.5,
    );
  });

  _WeatherPainter({
    required this.condition,
    required this.mousePosition,
    required this.progress,
    required this.glowProgress,
    required this.flashProgress,
    required this.nebulaProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (condition) {
      case WeatherCondition.sunny:
        _paintSunny(canvas, size);
        break;
      case WeatherCondition.clear:
        _paintGalactic(canvas, size);
        break;
      case WeatherCondition.rain:
        _paintStormyRain(canvas, size, heavy: true);
        _drawBirds(canvas, size);
        break;
      case WeatherCondition.drizzle:
        _paintGentleDrizzle(canvas, size);
        _drawBirds(canvas, size);
        break;
      case WeatherCondition.heavyRain:
      case WeatherCondition.rainThunder:
        _paintDeepStorm(canvas, size, withThunder: condition == WeatherCondition.rainThunder);
        break;
      case WeatherCondition.thunderstorm:
        _paintDeepThunderstorm(canvas, size);
        break;
      case WeatherCondition.clouds:
      case WeatherCondition.sunnyClouds:
        _paintAtmosphericClouds(canvas, size, sunny: condition == WeatherCondition.sunnyClouds);
        break;
      case WeatherCondition.snow:
        _paintArcticSnow(canvas, size);
        _drawBirds(canvas, size);
        break;
      case WeatherCondition.mist:
        _paintEtherealMist(canvas, size);
        _drawBirds(canvas, size);
        break;
      case WeatherCondition.haze:
        _paintWarmHaze(canvas, size);
        _drawBirds(canvas, size);
        break;
      case WeatherCondition.fog:
        _paintDenseFog(canvas, size);
        _drawBirds(canvas, size);
        break;
      default:
        _paintGalactic(canvas, size);
    }
    _paintMouseEffect(canvas, size);
  }

  void _paintSunny(Canvas canvas, Size size) {
    final cx = size.width * 0.9;
    final cy = size.height * 0.1;
    
    for (int i = 1; i <= 3; i++) {
      final sunPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD600).withOpacity(0.15 / i * glowProgress),
            const Color(0xFFFF8C00).withOpacity(0.02),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * (0.3 * i)));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sunPaint);
    }

    final flarePaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFD600).withOpacity(0.2 * glowProgress), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 120));
    canvas.drawCircle(Offset(cx, cy), 120, flarePaint);
  }

  void _paintGentleDrizzle(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 40; i++) {
      final p = _rainParticles[i % _rainParticles.length];
      final y = (p.y + progress * p.speed * 0.4) % 1.05;
      final x = p.x;
      
      final start = Offset(x * size.width, y * size.height);
      final end = Offset(x * size.width, y * size.height + 6 * p.speed);
      
      rainPaint.color = const Color(0xFF90A4AE).withOpacity(p.opacity * 0.6);
      canvas.drawLine(start, end, rainPaint);
    }

    final hazePaint = Paint()
      ..color = const Color(0xFF606C88).withOpacity(0.08);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), hazePaint);
  }

  void _paintGalactic(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white;
    for (final star in _stars) {
      final pulse = (0.5 + 0.5 * sin(progress * 2 * pi + star.x * 100));
      starPaint.color = Colors.white.withOpacity(star.opacity * pulse);
      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.size, starPaint);
    }

    final cx = size.width * 0.8;
    final cy = size.height * 0.2;
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C4DFF).withOpacity(0.15 * nebulaProgress),
          const Color(0xFFFF9500).withOpacity(0.05 * glowProgress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebulaPaint);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD600).withOpacity(0.12 * glowProgress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 150));
    canvas.drawCircle(Offset(cx, cy), 150, sunPaint);
  }

  void _paintStormyRain(Canvas canvas, Size size, {bool heavy = false}) {
    final rainPaint = Paint()
      ..strokeWidth = heavy ? 1.5 : 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < (heavy ? 150 : 80); i++) {
      final p = _rainParticles[i % _rainParticles.length];
      final y = (p.y + progress * p.speed) % 1.1;
      final x = (p.x + y * 0.1) % 1.0;
      
      final start = Offset(x * size.width, y * size.height);
      final end = Offset(x * size.width + 5, y * size.height + 15 * p.speed);
      
      rainPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.0),
          const Color(0xFF00E5FF).withOpacity(p.opacity),
        ],
      ).createShader(Rect.fromPoints(start, end));
      
      canvas.drawLine(start, end, rainPaint);
    }
  }

  void _paintDeepStorm(Canvas canvas, Size size, {bool withThunder = false}) {
    _paintStormyRain(canvas, size, heavy: true);
    if (withThunder) _paintDeepThunderstorm(canvas, size, onlyLightning: true);
    
    final darkTint = Paint()..color = const Color(0xFF000A1A).withOpacity(0.2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkTint);
  }

  void _paintDeepThunderstorm(Canvas canvas, Size size, {bool onlyLightning = false}) {
    if (!onlyLightning) _paintStormyRain(canvas, size, heavy: true);

    if (flashProgress > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFE040FB).withOpacity(0.15 * flashProgress),
      );

      final boltPaint = Paint()
        ..color = Colors.white.withOpacity(0.8 * flashProgress)
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      final rand = Random((flashProgress * 100).toInt());
      double curX = size.width * (0.3 + rand.nextDouble() * 0.4);
      double curY = 0;
      
      for (int i = 0; i < 8; i++) {
        double nextX = curX + (rand.nextDouble() - 0.5) * 80;
        double nextY = curY + size.height * 0.12;
        canvas.drawLine(Offset(curX, curY), Offset(nextX, nextY), boltPaint);
        curX = nextX;
        curY = nextY;
      }
    }
  }

  void _paintAtmosphericClouds(Canvas canvas, Size size, {bool sunny = false}) {
    if (sunny) {
      // Background "Breaking Light" effect
      final lightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD194).withOpacity(0.2 * glowProgress),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(size.width * 0.7, size.height * 0.2), radius: size.width * 0.5));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);
    }

    // 1. Background Clouds (Fast, Small)
    _drawCloudLayer(canvas, size, _backgroundClouds, sunny);
    
    // 2. Midground Clouds (Medium, Medium)
    _drawCloudLayer(canvas, size, _midgroundClouds, sunny);

    // 3. Foreground Clouds (Slow, Large)
    _drawCloudLayer(canvas, size, _foregroundClouds, sunny);

    // 4. Birds (Rare)
    _drawBirds(canvas, size);
  }

  void _drawCloudLayer(Canvas canvas, Size size, List<_Particle> clouds, bool sunny) {
    for (int i = 0; i < clouds.length; i++) {
      final c = clouds[i];
      // Parallax positioning with wrapping
      final x = ((c.x + progress * c.speed) % 1.8 - 0.4) * size.width;
      final y = c.y * size.height;
      
      final cloudColor = sunny ? Colors.white : const Color(0xFFCFD8DC);
      final cloudPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            cloudColor.withOpacity(c.opacity + 0.05 * glowProgress),
            cloudColor.withOpacity((c.opacity * 0.5) + 0.02 * glowProgress),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: c.size));
      
      canvas.drawCircle(Offset(x, y), c.size, cloudPaint);
      // Add a smaller sub-mass for a more organic "puffy" shape
      canvas.drawCircle(Offset(x + c.size * 0.3, y + c.size * 0.05), c.size * 0.7, cloudPaint);
    }
  }

  void _drawBirds(Canvas canvas, Size size) {
    final birdPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final b in _birds) {
      final x = ((b.x + progress * b.speed) % 2.0 - 0.5) * size.width;
      final y = b.y * size.height;
      
      if (x < -50 || x > size.width + 50) continue;

      // More pronounced wing flapping
      final flap = sin(progress * 35 + b.x * 100) * (b.size * 0.4);
      final wingSpan = b.size;
      
      final path = Path()
        ..moveTo(x - wingSpan, y - flap)
        ..quadraticBezierTo(x, y + (flap * 0.2), x + wingSpan, y - flap);
      
      canvas.drawPath(path, birdPaint);
    }
  }

  void _paintArcticSnow(Canvas canvas, Size size) {
    final snowPaint = Paint()..color = Colors.white;
    for (int i = 0; i < _snowParticles.length; i++) {
      final p = _snowParticles[i];
      final y = (p.y + progress * p.speed) % 1.05;
      final drift = sin(progress * 2 * pi + p.x * 10) * 0.05;
      final x = (p.x + drift) % 1.0;
      
      snowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      snowPaint.color = Colors.white.withOpacity(p.opacity * (0.8 + 0.2 * sin(progress * 4 * pi + p.x * 100)));
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, snowPaint);
    }
  }

  void _paintEtherealMist(Canvas canvas, Size size) {
    final mistPaint = Paint()..color = const Color(0xFFB0BEC5);
    for (final p in _mistParticles) {
      final x = (p.x + progress * p.speed) % 1.0;
      final y = (p.y + sin(progress * pi + p.x * 10) * 0.05) % 1.0;
      mistPaint.color = const Color(0xFFB0BEC5).withOpacity(p.opacity * (0.6 + 0.4 * sin(progress * 2 * pi + p.x * 50)));
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, mistPaint);
    }
    
    for (int i = 0; i < 4; i++) {
      final y = (i / 4.0 + progress * 0.02) % 1.0;
      final opacity = 0.08 + 0.04 * glowProgress;
      final layerPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, const Color(0xFFB0BEC5).withOpacity(opacity), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, y * size.height, size.width, size.height * 0.1));
      canvas.drawRect(Rect.fromLTWH(0, (y - 0.05) * size.height, size.width, size.height * 0.2), layerPaint);
    }
  }

  void _paintWarmHaze(Canvas canvas, Size size) {
    final hazePaint = Paint()..color = const Color(0xFFDECBA4);
    for (final p in _hazeParticles) {
      final x = (p.x + progress * p.speed) % 1.0;
      final y = (p.y + progress * p.speed * 0.5) % 1.0;
      hazePaint.color = const Color(0xFFDECBA4).withOpacity(p.opacity * (0.5 + 0.5 * sin(progress * pi + p.x * 30)));
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, hazePaint);
    }
    
    final sepiaPaint = Paint()
      ..color = const Color(0xFFDECBA4).withOpacity(0.08);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sepiaPaint);
  }

  void _paintDenseFog(Canvas canvas, Size size) {
    _drawCloudLayer(canvas, size, _foregroundClouds, false);
    
    final densePaint = Paint()..color = const Color(0xFF232526).withOpacity(0.1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), densePaint);
  }

  void _paintMouseEffect(Canvas canvas, Size size) {
    if (mousePosition == Offset.zero) return;

    final double effectSize = 100.0;
    Color effectColor;
    
    switch (condition) {
      case WeatherCondition.sunny:
      case WeatherCondition.sunnyClouds:
        effectColor = const Color(0xFFFFD600).withOpacity(0.2);
        break;
      case WeatherCondition.clear:
        effectColor = const Color(0xFF7C4DFF).withOpacity(0.2);
        break;
      case WeatherCondition.rain:
      case WeatherCondition.heavyRain:
      case WeatherCondition.rainThunder:
        effectColor = const Color(0xFF00E5FF).withOpacity(0.15);
        _drawRipples(canvas);
        break;
      case WeatherCondition.thunderstorm:
        effectColor = const Color(0xFFE040FB).withOpacity(0.2);
        break;
      default:
        effectColor = Colors.white.withOpacity(0.1);
    }

    final mousePaint = Paint()
      ..shader = RadialGradient(
        colors: [effectColor, Colors.transparent],
      ).createShader(Rect.fromCircle(center: mousePosition, radius: effectSize));
    
    canvas.drawCircle(mousePosition, effectSize, mousePaint);
  }

  void _drawRipples(Canvas canvas) {
    final ripplePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final radius = (progress * 50 * i) % 60.0;
      final opacity = (1.0 - (radius / 60.0)).clamp(0.0, 0.1);
      ripplePaint.color = const Color(0xFF00E5FF).withOpacity(opacity);
      canvas.drawCircle(mousePosition, radius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter old) => true;
}
