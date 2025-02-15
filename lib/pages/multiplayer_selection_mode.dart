import 'package:drawiloo/pages/multiplayer_mode.dart';
import 'package:drawiloo/pages/profile_page.dart';
import 'package:flutter/material.dart';

class MultiplayerSelectionMode extends StatelessWidget {
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
            _buildMenuButton(
              context,
              'Join Room',
              MultiplayerModeScreen(
                isAdmin: false,
              ),
            ),
            _buildMenuButton(
              context,
              'Create Room',
              MultiplayerModeScreen(
                isAdmin: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
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
          child: Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
