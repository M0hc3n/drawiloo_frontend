import 'package:drawiloo/pages/leader_board.dart';
import 'package:drawiloo/pages/login_page.dart';
import 'package:drawiloo/pages/multiplayer_selection_mode.dart';
import 'package:drawiloo/pages/offline_mode.dart';
import 'package:drawiloo/pages/online_mode.dart';
import 'package:drawiloo/pages/profile_page.dart';
import 'package:drawiloo/pages/room_mode.dart';
import 'package:drawiloo/pages/splashScreen.dart';
import 'package:drawiloo/widgets/top_bar/Custom_appbar.dart';
import 'package:drawiloo/widgets/typing_text_wighet/TypingTextWidget%20.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kmnrtirsjumujwebkiun.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttbnJ0aXJzanVtdWp3ZWJraXVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk0ODI0NzcsImV4cCI6MjA1NTA1ODQ3N30.jqilgY9Uxzq2e5mjl9z-afUZDnma7Z0egvxTwhOuimU',
  );
  runApp(MyApp());
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return MainMenu();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Color _playButtonBorderColor = Color(0xFF72CB25);
  Color _leadButtonBorderColor = Colors.black;

  void _handleButtonPress(String buttonType) {
    setState(() {
      if (buttonType == 'play') {
        _playButtonBorderColor = Color(0xFF72CB25);
        _leadButtonBorderColor = Colors.black;
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MainMenu()));
      } else if (buttonType == 'lead') {
        _leadButtonBorderColor = Color(0xFF72CB25);
        _playButtonBorderColor = Colors.black;
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => LeaderboardScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        goldCount: 12,
        silverCount: 6,
        purpleCount: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TypingTextWidget(
                    text:
                        'Welcome to the game!\nChoose a mode and start\nskating.',
                  ),
                  Image.asset(
                    'assets/image/triangle.png',
                    width: 150,
                    height: 150,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                _buildCustomButton(context, 'Offline Mode', OfflineMode(),
                    'assets/image/circle.png'),
                SizedBox(height: 35),
                _buildCustomButton(context, 'Online Mode',
                    OnlineModeMatchMakingScreen(), 'assets/image/bomba.png'),
                SizedBox(height: 35),
                _buildCustomButton(context, 'Room Mode',
                    MultiplayerSelectionMode(), 'assets/image/cle.png'),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: _playButtonBorderColor, width: 2),
                              ),
                              elevation: 2,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _handleButtonPress('play'),
                            icon: Image.asset('assets/image/play.png',
                                width: 24, height: 24, fit: BoxFit.contain),
                            label: Text("Play",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: _leadButtonBorderColor, width: 2),
                              ),
                              elevation: 2,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _handleButtonPress('lead'),
                            icon: Image.asset('assets/image/cup.png',
                                width: 24, height: 24, fit: BoxFit.contain),
                            label: Text("Lead",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomButton(
      BuildContext context, String title, Widget page, String imagePath) {
    return Container(
      height: 60,
      width: 300,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          backgroundColor: Color(0xFF7A1FA0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 24, height: 24),
            SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
            SizedBox(width: 12),
            Image.asset(imagePath, width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
