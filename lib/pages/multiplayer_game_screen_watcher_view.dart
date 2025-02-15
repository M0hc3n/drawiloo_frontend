import 'dart:convert';
import 'dart:ui' as ui;
import 'package:drawiloo/widgets/HeartProgressBar/Heart_Progress_Bar.dart';
import 'package:drawiloo/widgets/dialogs/game_dialog.dart';
import 'package:drawiloo/widgets/top_bar/Custom_appbar.dart';
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
  bool _isEraser = false; // New state variable for eraser mode

  Color _playButtonBorderColor = Colors.black; // Default border color
  Color _leadButtonBorderColor = Colors.black;

  @override
  void initState() {
    super.initState();
    startTimer();

    _startPeriodicCapture();

    watchDrawer();
    _promptController = TextEditingController(text: '');

    fetchUserPoints();
  }

  // Function to handle button presses
  void _handleButtonPress(String buttonType) {
    setState(() {
      if (buttonType == 'play') {
        // Set Play button border to #72CB25 and reset Lead button border to #000000
        _playButtonBorderColor = Color(0xFF72CB25); // Hex color #72CB25
        _leadButtonBorderColor = Colors.black; // Hex color #000000
      } else if (buttonType == 'lead') {
        // Set Lead button border to #72CB25 and reset Play button border to #000000
        _leadButtonBorderColor = Color(0xFF72CB25); // Hex color #72CB25
        _playButtonBorderColor = Colors.black; // Hex color #000000
      }
    });
  }

  void _toggleEraser() {
    setState(() {
      _isEraser = !_isEraser;
      selectedColor = _isEraser ? Colors.white : Colors.black;
    });
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
      // Replace the existing AppBar with CustomAppBar
      appBar: CustomAppBar(
        goldCount: 12,
        silverCount: 6,
        purpleCount: 2,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 150),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 350,
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          border: Border.all(
                            color: Colors.black, // Border color
                            width: 3, // Border width
                          ),
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        child: ClipRect(
                          child: RepaintBoundary(
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
                        ),
                      ),
                      // Pen and Eraser Icons
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Column(
                          children: [
                            // Pen Icon
                            IconButton(
                              icon: Icon(
                                Icons.brush,
                                color: _isEraser ? Colors.grey : Colors.black,
                              ),
                              onPressed: () {
                                if (_isEraser) _toggleEraser();
                              },
                            ),
                            // Eraser Icon (using eraser.png)
                            IconButton(
                              icon: Image.asset(
                                'image/eraser.png', // Path to your eraser image
                                width: 24, // Adjust the width
                                height: 24, // Adjust the height
                                color: _isEraser
                                    ? Colors.black
                                    : Colors.grey, // Apply color filter
                              ),
                              onPressed: () {
                                if (!_isEraser) _toggleEraser();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/image/triangle.png', // Path to your image
                        width: 150, // Adjust the width
                        height: 150, // Adjust the height
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.all(8), // Padding inside the container
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.black), // Blue border
                          borderRadius:
                              BorderRadius.circular(16), // Rounded corners
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Wrap content size
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white, // White button background
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded button corners
                                  side: BorderSide(
                                      color:
                                          _playButtonBorderColor, // Dynamic border color
                                      width: 2), // Border width
                                ),
                                elevation: 2,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                // Handle Play button press
                                _handleButtonPress('play');
                              },
                              icon: Image.asset(
                                'assets/image/play.png', // Replace with your image path
                                width: 24,
                                height: 24,
                                fit: BoxFit
                                    .contain, // Ensures the image fits well
                              ),
                              label: Text(
                                "Play",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),

                            SizedBox(width: 8), // Spacing between buttons
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white, // White button background
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded button corners
                                  side: BorderSide(
                                      color:
                                          _leadButtonBorderColor, // Dynamic border color
                                      width: 2), // Border width
                                ),
                                elevation: 2,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                // Handle Lead button press
                                _handleButtonPress('lead');
                              },
                              icon: Image.asset(
                                'assets/image/cup.png', // Replace with your image path
                                width: 24,
                                height: 24,
                                fit: BoxFit
                                    .contain, // Ensures the image fits well
                              ),
                              label: Text(
                                "Lead",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter prompt',
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    onChanged: (value) {
                      if (value.trim().toLowerCase() ==
                          widget.prompt.toLowerCase()) {
                        _handleSuccess();
                      }
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: HeartProgressBar(
                  duration: timeLeft,
                  onTimerComplete: () {
                    _handleTimeOut();
                  },
                ),
              ),
            ),
          ],
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
