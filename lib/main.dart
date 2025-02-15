
import 'package:drawiloo/pages/login_page.dart';
import 'package:drawiloo/pages/offline_mode.dart';
import 'package:drawiloo/pages/online_mode.dart';
import 'package:drawiloo/pages/profile_page.dart';
import 'package:drawiloo/pages/room_mode.dart';
import 'package:drawiloo/pages/splashScreen.dart';
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

/*class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return user == null ? LoginPage() : MainMenu();
  }
}*/
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return  AnimatedSplashScreen();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drawiloo Challenge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
    );
  }
}

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Drawiloo Challenge')),
        backgroundColor: Colors.white,
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'April 21, Friday',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Row(
                        children: [
                         
                       Image.asset(
    'assets/image/1.png', // Path to your trophy image
    width: 24,
    height: 24,
    fit: BoxFit.contain, // Ensures the image fits properly
  ),
                          SizedBox(width: 4),
                          Text('12'),
                          SizedBox(width: 8),
                           Image.asset(
    'assets/image/2.png', // Path to your trophy image
    width: 24,
    height: 24,
    fit: BoxFit.contain, // Ensures the image fits properly
  ),
                          SizedBox(width: 4),
                          Text('6'),
                          SizedBox(width: 8),
                         Image.asset(
    'assets/image/3.png', // Path to your trophy image
    width: 24,
    height: 24,
    fit: BoxFit.contain, // Ensures the image fits properly
  ),
                          SizedBox(width: 4),
                          Text('2'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Welcome Text Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                      Text(
                        'Welcome to the game!\nChoose a mode and start\n skating.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                     
                      
                    
                  Image.asset(
                    'assets/image/triangle.png', // Path to your image
                    width: 150, // Adjust the width
                    height: 150, // Adjust the height
                  ),
                  
                ],
              ),
            ),
            // Mode Buttons
           
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
                  _buildCustomButton(
                      context, 'Room Mode', RoomMode(), 'assets/image/cle.png'),
                ],
              ),
            

            // Bottom Navigation

            Expanded(
              child: Container(
              
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                padding: EdgeInsets.all(8), // Padding inside the container
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Blue border
                  borderRadius: BorderRadius.circular(16), // Rounded corners
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Wrap content size
                  children: [
                    ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white, // White button background
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Rounded button corners
      side: BorderSide(color: Colors.transparent), // Transparent border
    ),
    elevation: 2,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  onPressed: () {
    // Play button action
  },
  icon: Image.asset(
    'assets/image/play.png', // Replace with your image path
    width: 24,
    height: 24,
    fit: BoxFit.contain, // Ensures the image fits well
  ),
  label: Text(
    "Play",
    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
  ),
),

                    SizedBox(width: 8), // Spacing between buttons
                    ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white, // White button background
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Rounded button corners
      side: BorderSide(color: Colors.amber), // Amber border
    ),
    elevation: 2,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  onPressed: () {
    // Lead button action
  },
  icon: Image.asset(
    'assets/image/cup.png', // Replace with your image path
    width: 24,
    height: 24,
    fit: BoxFit.contain, // Ensures the image fits well
  ),
  label: Text(
    "Lead",
    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
  ),
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
             Image.asset(
            imagePath,
            width: 24, // Set the desired width
            height: 24, // Set the desired height
          ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(width: 12),
            Image.asset(
            imagePath,
            width: 24, // Set the desired width
            height: 24, // Set the desired height
          ),
          ],
        ),
      ),
    );
  }

  
}
