import 'dart:convert';
import 'dart:ui' as ui;
import 'package:drawiloo/pages/profile_page.dart';
import 'package:drawiloo/widgets/dialogs/game_dialog.dart';
import 'package:drawiloo/widgets/game/timer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:drawiloo/services/api/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MultiplayerGameScreenWatcherView extends StatefulWidget {
  final int gameId;
  final String prompt;

  const MultiplayerGameScreenWatcherView({
    required this.gameId,
    required this.prompt,
    Key? key,
  }) : super(key: key);

  @override
  State<MultiplayerGameScreenWatcherView> createState() =>
      _MultiplayerGameScreenWatcherViewState();
}

class _MultiplayerGameScreenWatcherViewState
    extends State<MultiplayerGameScreenWatcherView> {
  List<DrawingPoint?> drawingPoints = [];
  Color selectedColor = Colors.black;
  final GlobalKey canvasKey = GlobalKey();
  double strokeWidth = 5;
  int timeLeft = 60; // 60 seconds timer
  Timer? _captureTimer;
  int currPoints = 0;
  bool _isSending = false;
  int _elapsedSeconds = 0;
  bool _gameEnded = false;
  final SupabaseClient supabase = Supabase.instance.client;
  StreamSubscription? watcherGameStream;
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    startTimer();

    _startPeriodicCapture();

    watchDrawer();
    _promptController = TextEditingController(text: '');

    fetchUserPoints();
  }

  void fetchUserPoints() async {
    final user = supabase.auth.currentUser;
    final userProfile = await supabase
        .from('user_info')
        .select('points')
        .eq('user_id', user?.id as String)
        .select('*')
        .single();

    if (userProfile.isEmpty) {
      return;
    }
    int userPoints = userProfile['points'] as int;

    setState(() {
      currPoints = userPoints;
    });
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    watcherGameStream?.cancel();

    _promptController.dispose();

    super.dispose();
  }

  void _startPeriodicCapture() {
    _captureTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _captureAndProcessCanvas(),
    );
  }

  void watchDrawer() {
    watcherGameStream = supabase
        .from('multiplayer_game')
        .stream(primaryKey: ['id'])
        .eq('id', widget.gameId)
        .listen((data) {
          setState(() {
            if (data[0]['drawing_points'] == null) return;

            List<dynamic> pointsJson = data[0]['drawing_points'];

            drawingPoints = pointsJson.map((point) {
              return DrawingPoint(
                Offset(point['x'], point['y']),
                Paint()
                  ..color = selectedColor
                  ..isAntiAlias = true
                  ..strokeWidth = strokeWidth
                  ..strokeCap = StrokeCap.round,
              );
            }).toList();
          });
        });
  }

  Future<void> _broadcastDrawing() async {
    List<Map<String, dynamic>> serializedPoints = drawingPoints
        .where((point) => point != null)
        .map((point) => {
              'x': point!.offset.dx,
              'y': point.offset.dy,
            })
        .toList();

    await supabase.from('multiplayer_game').update({
      'drawing_points': jsonEncode(serializedPoints),
    }).eq('id', widget.gameId);
  }

  Future<void> _captureAndProcessCanvas() async {
    if (_isSending) return; // Prevent multiple concurrent captures

    setState(() {
      _isSending = true;
    });

    try {
      await _broadcastDrawing();
    } catch (e) {
      _showError('Failed to process drawing: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> updateProficiency() async {
    final proficiencyResponse =
        await ApiService.getProficiencyPointForMulitPlayerSetting(
      _elapsedSeconds,
      currPoints,
    );

    await Supabase.instance.client.from('user_info').update({
      'points': proficiencyResponse,
    }).eq('user_id', Supabase.instance.client.auth.currentUser?.id as Object);
  }

  Future<void> _handleSuccess() async {
    await updateProficiency();

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
              child: CustomPaint(
                painter: _DrawingPainter(drawingPoints),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          ),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              hintText: 'Enter prompt',
            ),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            onChanged: (value) {
              setState(() {
                // Update the prompt value if needed

                if (value.trim().toLowerCase() ==
                    widget.prompt.trim().toLowerCase()) {
                  _handleSuccess();
                }
              });
            },
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
