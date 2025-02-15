import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:drawiloo/pages/profile_page.dart';
import 'package:drawiloo/services/capture_canvas.dart';
import 'package:drawiloo/widgets/dialogs/game_dialog.dart';
import 'package:drawiloo/widgets/game/timer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:drawiloo/services/api/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameScreen extends StatefulWidget {
  final int gameId;
  final String opponentId;
  final String prompt;

  const GameScreen({
    required this.gameId,
    required this.opponentId,
    required this.prompt,
    Key? key,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<DrawingPoint?> drawingPoints = [];
  Color selectedColor = Colors.black;
  final GlobalKey canvasKey = GlobalKey();
  double strokeWidth = 5;
  String prompt = "Draw a cat"; // This will come from database
  int timeLeft = 60; // 60 seconds timer
  Timer? _captureTimer;
  bool _isSending = false;
  String? _lastPrediction;
  String? _confidence;
  int _elapsedSeconds = 0;
  bool _gameEnded = false;
  String? _winnerId;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _startPeriodicCapture();
    startTimer();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicCapture() {
    _captureTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _captureAndProcessCanvas(),
    );
  }

  Future<void> _captureAndProcessCanvas() async {
    if (_isSending) return; // Prevent multiple concurrent captures

    setState(() {
      _isSending = true;
    });

    try {
      ui.Image? image = await CanvasCapture.captureCanvas(canvasKey);

      if (image != null) {
        ByteData? byteData = await CanvasCapture.imageToByteData(image);

        if (byteData != null) {
          List<int> pngBytes = byteData.buffer.asUint8List();
          await _sendDrawingToApi(pngBytes);
        }
      }
    } catch (e) {
      _showError('Failed to process drawing: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendDrawingToApi(List<int> imageBytes) async {
    if (_gameEnded) return;

    try {
      final response = await ApiService.sendDrawing(imageBytes, widget.prompt);
      setState(() {
        _lastPrediction = response['correct_label'];
        _confidence = response['confidence'];
      });

      // Assuming API returns something like {'success': true, 'confidence': 0.95, correct_label}
      bool isCorrect = response['success'] == true;

      if (isCorrect) {
        setState(() {
          _gameEnded = true;
        });
        await updateProficiency();
        await _handleGameEnd();
      }
    } catch (e) {
      _showError('Error sending to API: $e');
    }
  }

  Future<void> updateProficiency() async {
    final proficiencyResponse = await ApiService.getProficiencyPoint(
        _elapsedSeconds, _confidence ?? "0.5");

    final response = await Supabase.instance.client.from('user_info').update({
      'points': proficiencyResponse,
    }).eq('user_id', Supabase.instance.client.auth.currentUser?.id as Object);
  }

  Future<void> _handleGameEnd() async {
    final user = supabase.auth.currentUser;
    final response = await supabase
        .from('matchmaking')
        .select('winner_id')
        .eq('id', widget.gameId)
        .single();

    if (response.isNotEmpty && response['winner_id'] != null) {
      setState(() {
        _winnerId = response['winner_id'];
        _gameEnded = true;
      });
      if (_winnerId == Supabase.instance.client.auth.currentUser?.id) {
        await _handleSuccess();
      } else {
        await _handleLostGame();
      }
    } else {
      await supabase
          .from('matchmaking')
          .update({'winner_id': user?.id}).eq('id', widget.gameId);

      setState(() {
        _gameEnded = true;
        _winnerId = user?.id;
      });
      await _handleSuccess();
    }
  }

  Future<void> _handleSuccess() async {
    // Cancel the capture timer since game is over
    _captureTimer?.cancel();

    await GameDialogs.showSuccessDialog(
      context,
      secondsTaken: _elapsedSeconds,
    );
  }

  Future<void> _handleTimeOut() async {
    await updateProficiency();

    setState(() {
      _gameEnded = true;
    });

    // Cancel the capture timer
    _captureTimer?.cancel();

    await GameDialogs.showTimeOutDialog(context);
  }

  Future<void> _handleLostGame() async {
    setState(() {
      _gameEnded = true;
    });

    // Cancel the capture timer
    _captureTimer?.cancel();

    await GameDialogs.showLostDialog(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
        startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GameTimer(
          totalSeconds: 60,
          size: 60,
          onTimerUpdate: (seconds) {
            _elapsedSeconds = 60 - seconds;
          },
          onTimerComplete: () {
            if (!_gameEnded) {
              _handleTimeOut();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                drawingPoints.clear();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: canvasKey,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  drawingPoints.add(
                    DrawingPoint(
                      details.localPosition,
                      Paint()
                        ..color = selectedColor
                        ..isAntiAlias = true
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  drawingPoints.add(
                    DrawingPoint(
                      details.localPosition,
                      Paint()
                        ..color = selectedColor
                        ..isAntiAlias = true
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  drawingPoints.add(null);
                });
              },
              child: CustomPaint(
                painter: _DrawingPainter(drawingPoints),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Draw a ${widget.prompt}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorButton(Colors.black),
                IconButton(
                  icon: const Icon(Icons.brush),
                  onPressed: () {
                    // TODO: Add brush size selector
                  },
                ),
              ],
            ),
          ),
          if (_lastPrediction != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Model thinks it\'s: $_lastPrediction',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.blue : Colors.grey,
            width: 3,
          ),
        ),
      ),
    );
  }
}

class DrawingPoint {
  Offset offset;
  Paint paint;

  DrawingPoint(this.offset, this.paint);
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;

  _DrawingPainter(this.drawingPoints);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        canvas.drawLine(drawingPoints[i]!.offset, drawingPoints[i + 1]!.offset,
            drawingPoints[i]!.paint);
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [drawingPoints[i]!.offset],
            drawingPoints[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
