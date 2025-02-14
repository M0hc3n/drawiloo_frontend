import 'package:drawiloo/pages/login_page.dart';
import 'package:drawiloo/pages/offline_mode.dart';
import 'package:drawiloo/pages/online_mode.dart';
import 'package:drawiloo/pages/profile_page.dart';
import 'package:drawiloo/pages/room_mode.dart';
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
    return user == null ? LoginPage() : MainMenu();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        title: Text('Drawiloo Challenge'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(context, 'Offline Mode', OfflineMode()),
            _buildMenuButton(
                context, 'Online Mode', OnlineModeMatchMakingScreen()),
            _buildMenuButton(context, 'Room Mode', RoomMode()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
