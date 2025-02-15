import 'package:drawiloo/pages/lobby_screen.dart';
import 'package:flutter/material.dart';

class MultiplayerListGamesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  MultiplayerListGamesScreen({required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby Screen'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final room = items[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text("Prompt: *************"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status: ${room['status']}"),
                  Text("Drawer Points: ${room['drawer_points']}"),
                  Text("Created At: ${room['created_at']}"),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LobbyScreen(
                      availableRoom: room,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
