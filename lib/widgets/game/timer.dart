// game_timer.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GameTimer extends StatefulWidget {
  final int totalSeconds;
  final double size;
  final Function(int)? onTimerUpdate;
  final VoidCallback? onTimerComplete;

  const GameTimer({
    super.key,
    required this.totalSeconds,
    this.size = 80,
    this.onTimerUpdate,
    this.onTimerComplete,
  });

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.totalSeconds;

    _controller = AnimationController(
      duration: Duration(seconds: widget.totalSeconds),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _controller.addListener(() {
      setState(() {
        _timeLeft = widget.totalSeconds -
            (_controller.value * widget.totalSeconds).floor();
        widget.onTimerUpdate?.call(_timeLeft);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTimerComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: TimerPainter(
                  animation: _animation,
                  backgroundColor: Colors.grey.shade200,
                  color: _getTimerColor(_timeLeft),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    fontSize: widget.size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: _getTimerColor(_timeLeft),
                  ),
                ),
                Text(
                  'seconds',
                  style: TextStyle(
                    fontSize: widget.size * 0.15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor(int timeLeft) {
    if (timeLeft > widget.totalSeconds * 0.6) {
      return Colors.green;
    } else if (timeLeft > widget.totalSeconds * 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

class TimerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor;
  final Color color;

  TimerPainter({
    required this.animation,
    required this.backgroundColor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * math.pi;
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter old) {
    return animation.value != old.animation.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}
