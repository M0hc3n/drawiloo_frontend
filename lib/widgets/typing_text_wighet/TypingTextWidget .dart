import 'dart:async';
import 'package:flutter/material.dart';

class TypingTextWidget extends StatefulWidget {
  final String text;
  final Duration speed;

  const TypingTextWidget({
    Key? key,
    required this.text,
    this.speed = const Duration(milliseconds: 100), // Adjust speed as needed
  }) : super(key: key);

  @override
  _TypingTextWidgetState createState() => _TypingTextWidgetState();
}

class _TypingTextWidgetState extends State<TypingTextWidget> {
  String displayedText = "";
  int currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTypingEffect();
  }

  void _startTypingEffect() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (currentIndex < widget.text.length) {
        setState(() {
          displayedText += widget.text[currentIndex];
          currentIndex++;
        });
      } else {
        _timer.cancel(); // Stop when finished
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayedText,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}
