import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:drawiloo/services/capture_canvas.dart';
import 'package:drawiloo/widgets/HeartProgressBar/Heart_Progress_Bar.dart';
import 'package:drawiloo/widgets/dialogs/game_dialog.dart';
import 'package:drawiloo/widgets/top_bar/Custom_appbar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:drawiloo/services/api/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineMode extends StatefulWidget {
  final int timeLeft;

  const OfflineMode({
    super.key,
    required this.timeLeft,
  });

  @override
  State<OfflineMode> createState() => _OfflineModeState();
}

class _OfflineModeState extends State<OfflineMode> {
  List<DrawingPoint?> drawingPoints = [];
  Color selectedColor = Colors.black;
  final GlobalKey canvasKey = GlobalKey();
  double strokeWidth = 5;

  int timeLeft = 20; // 20 seconds timer
  Timer? _captureTimer;
  bool _isSending = false;
  // String? _lastPrediction;
  // String? _confidence;
  // int currPoints = 0;
  // int _elapsedSeconds = 0;
  bool _gameEnded = false;
  // String recommendedLabel = '';
  bool _isEraser = false; // New state variable for eraser mode

  // New state variable for button border colors
  Color _playButtonBorderColor = Colors.black; // Default border color
  Color _leadButtonBorderColor = Colors.black; // Default border color
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _startPeriodicCapture();
    startTimer();
    // fetchLabel();

    // fetchUserPoints();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    super.dispose();
  }

  // void fetchUserPoints() async {
  //   final user = supabase.auth.currentUser;
  //   final userProfile = await supabase
  //       .from('user_info')
  //       .select('points')
  //       .eq('user_id', user?.id as String)
  //       .select('*')
  //       .single();

  //   if (userProfile.isEmpty) {
  //     return;
  //   }
  //   int userPoints = userProfile['points'] as int;

  //   setState(() {
  //     currPoints = userPoints;
  //   });
  // }

  void _startPeriodicCapture() {
    _captureTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _captureAndProcessCanvas(),
    );
  }

  // void fetchLabel() async {
  //   final user = supabase.auth.currentUser;

  //   final userProfile = await supabase
  //       .from('user_info')
  //       .select('points')
  //       .eq('user_id', user?.id as String)
  //       .select('*')
  //       .single();

  //   int userPoints = userProfile['points'] as int;

  //   String label = await ApiService.fetchRecommendedLabel(userPoints);
  //   setState(() {
  //     recommendedLabel = label;
  //   });
  // }

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

  // Future<void> updateProficiency() async {
  //   final proficiencyResponse = await ApiService.getProficiencyPoint(
  //     _elapsedSeconds,
  //     _confidence ?? "0.5",
  //     currPoints,
  //   );

  //   await Supabase.instance.client.from('user_info').update({
  //     'points': proficiencyResponse,
  //   }).eq('user_id', Supabase.instance.client.auth.currentUser?.id as Object);

  //   // Call the callback with the new proficiency value
  //   widget.onProficiencyUpdate?.call(proficiencyResponse);
  // }

  Future<void> _handleSuccess() async {
    // Cancel the capture timer since game is over
    _captureTimer?.cancel();

    await GameDialogs.showSuccessDialog(
      context,
      secondsTaken: _elapsedSeconds,
    );
  }

  Future<void> _handleTimeOut() async {
    // await updateProficiency();

    // setState(() {
    //   _gameEnded = true;
    // });

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
                      Text(
                        'I guess its a \n ${_lastPrediction ?? '...'}.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
