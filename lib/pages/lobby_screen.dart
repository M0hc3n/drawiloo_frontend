import 'dart:async';

import 'package:drawiloo/pages/multiplayer_game_screen_watcher_view.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LobbyScreen extends StatefulWidget {
  final Map<String, dynamic> availableRoom;

  LobbyScreen({required this.availableRoom});

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  StreamSubscription? watcherRoomStream;
  StreamSubscription? watcherGameStream;
  String status = "Looking for waiters...";

  @override
  void initState() {
    super.initState();

    joinAsWatcher();
  }

  void joinAsWatcher() async {
    await supabase
        .from('multiplayer_game_watcher')
        .insert({
          'watcher_id': supabase.auth.currentUser?.id,
          'game': widget.availableRoom['id'],
        })
        .select('*')
        .single();

    watcherRoomStream = supabase
        .from('multiplayer_game_watcher')
        .stream(primaryKey: ['id'])
        .eq('game', widget.availableRoom['id'])
        .listen((data) {
          setState(() {
            status =
                'Waiting in the lobby, currently There are other ${data.length} users';
          });
        });

    watcherGameStream = supabase
        .from('multiplayer_game')
        .stream(primaryKey: ['id'])
        .eq('id', widget.availableRoom['id'])
        .listen((data) {
          if (data[0]['status'] == 'started') {
            setState(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiplayerGameScreenWatcherView(
                    prompt: data[0]['prompt'],
                    gameId: data[0]['id'],
                  ),
                ),
              );
            });
          }
        });
  }

  @override
  void dispose() {
    watcherRoomStream?.cancel();
    watcherGameStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lobby')),
      body: Center(
        child: Column(
          children: [
            Text(
              status,
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
