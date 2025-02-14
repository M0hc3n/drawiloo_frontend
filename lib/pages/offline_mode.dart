// offline_drawing_page.dart
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

class OfflineMode extends StatefulWidget {
  const OfflineMode({super.key});

  @override
  State<OfflineMode> createState() => _OfflineModeState();
}

class _OfflineModeState extends State<OfflineMode> {
  List<DrawingPoint?> drawingPoints = [];
  Color selectedColor = Colors.black;
  final GlobalKey canvasKey = GlobalKey();
  double strokeWidth = 5;
  String prompt = "Draw a cat"; // This will come from database
  int timeLeft = 20; // 20 seconds timer
  Timer? _captureTimer;
  bool _isSending = false;
  String? _lastPrediction;
  String? _confidence;
  double? _points;
  int _elapsedSeconds = 0;
  bool _gameEnded = false;
  String recommendedLabel = '';

  @override
  void initState() {
    super.initState();
    _startPeriodicCapture();
    startTimer();
    fetchLabel();
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

  void fetchLabel() async {
    String label = await ApiService.fetchRecommendedLabel();
    setState(() {
      recommendedLabel = label;
    });
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
      final response = await ApiService.sendDrawing(
        imageBytes,
        recommendedLabel,
      );

      setState(() {
        _lastPrediction = response['correct_label'];
        _confidence = response['confidence'];
      });

      bool isCorrect = response['success'] == true;

      if (isCorrect) {
        setState(() {
          _gameEnded = true;
        });
        await updateProficiency();
        await _handleSuccess();
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
          totalSeconds: 20,
          size: 20,
          onTimerUpdate: (seconds) {
            _elapsedSeconds = 20 - seconds;
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
                  'Draw a $recommendedLabel',
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
