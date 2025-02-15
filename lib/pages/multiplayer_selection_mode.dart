import 'package:drawiloo/pages/multiplayer_mode.dart';
import 'package:drawiloo/pages/profile_page.dart';
import 'package:flutter/material.dart';

class MultiplyaerSelectionMode extends StatelessWidget {
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
