import 'package:flutter/material.dart';
import 'dart:async';

class HeartProgressBar extends StatefulWidget {
  final int duration;

  const HeartProgressBar({Key? key, required this.duration}) : super(key: key);

  @override
  State<HeartProgressBar> createState() => _HeartProgressBarState();
}

class _HeartProgressBarState extends State<HeartProgressBar> {
  late double progress;
  late int timeLeft;
  late int duration;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startCountdown(widget.duration);
  }

  void startCountdown(int newDuration) {
    setState(() {
      duration = newDuration;
      timeLeft = duration;
      progress = 1.0;
    });

    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && timeLeft > 0) {
        setState(() {
          timeLeft--;
          progress = timeLeft / duration;
        });
      } else {
        timer.cancel();
        if (duration == 15) {
          startCountdown(10);
        } else if (duration == 10) {
          startCountdown(5);
        }
      }
    });
  }

  Color getProgressColor() {
    double ratio = timeLeft / duration;

    if (ratio > 2 / 3) {
      return Colors.yellow; // Same as in the provided image
    } else if (ratio > 1 / 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'image/srdce.png',
              width: 32,
              height: 32,
              filterQuality: FilterQuality.none, // Keeps pixelated look
            ),
            const SizedBox(width: 5),
            Stack(
              children: [
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                        color: Colors.white,
                        width: 3), // Thick pixelated border
                  ),
                ),
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    width: (144 * progress)
                        .clamp(0, 144), // Ensuring progress stays inside
                    height: 10,
                    decoration: BoxDecoration(
                      color: getProgressColor(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$timeLeft s',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
