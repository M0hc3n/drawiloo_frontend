import 'dart:async';

import 'package:drawiloo/pages/multiplayer_game_main_screen.dart';
import 'package:drawiloo/pages/multiplayer_list_games_screen.dart';
import 'package:drawiloo/services/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MultiplayerModeScreen extends StatefulWidget {
  final bool isAdmin;

  MultiplayerModeScreen({required this.isAdmin});

  @override
  _MultiplayerModeScreenState createState() => _MultiplayerModeScreenState();
}

class _MultiplayerModeScreenState extends State<MultiplayerModeScreen> {
  String status = "Looking for waiters...";
  final SupabaseClient supabase = Supabase.instance.client;
  StreamSubscription? waitersInfoStream;
  int gameId = 0;
  int waiters = 0;

  @override
  void initState() {
    super.initState();

    if (widget.isAdmin) {
      createMatch();
    } else {
      findMatch();
    }
  }

  @override
  void dispose() {
    waitersInfoStream?.cancel();
    super.dispose();
  }

  void createMatch() async {
    final user = supabase.auth.currentUser;
    String prompt = await ApiService.fetchRecommendedLabel();

    final userProfile = await supabase
        .from('user_info')
        .select('points')
        .eq('user_id', user?.id as String)
        .select('*')
        .single();

    if (userProfile.isEmpty) {
      setState(() {
        status = "Error fetching profile";
      });
      return;
    }
    int userPoints = userProfile['points'] as int;

    final gameRes = await supabase
        .from('multiplayer_game')
        .insert({
          'drawer_id': user?.id,
          'drawer_points': userPoints,
          'prompt': prompt,
          'status': 'waiting',
        })
        .select('*')
        .single();

    setState(() {
      gameId = gameRes['id'] as int;
    });

    waitersInfoStream = supabase
        .from('multiplayer_game_watcher')
        .stream(primaryKey: ['id'])
        .eq('game', gameRes['id'])
        .listen((data) {
          setState(() {
            status = "Current Waiters: ${data.length} waiters...";
            waiters = data.length;
          });
        });
  }

  void findMatch() async {
    final user = supabase.auth.currentUser;

    final userProfile = await supabase
        .from('user_info')
        .select('points')
        .eq('user_id', user?.id as String)
        .single();

    if (userProfile.isEmpty) {
      setState(() {
        status = "Error fetching profile";
      });
      return;
    }
    // Fix: Correctly access points from the map
    int userPoints = userProfile['points'] as int;

    final availableRooms = await supabase
        .from('multiplayer_game')
        .select('*')
        .gte('drawer_points', userPoints - 1)
        .lte('drawer_points', userPoints + 1)
        .eq('status', 'waiting')
        .order('drawer_points');

    if (availableRooms.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerListGamesScreen(
            items: availableRooms,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Matchmaking')),
        body: Center(
            child: Column(
          children: [
            Text(status, style: TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: () async {
                if (waiters > 0) {
                  final gameSettings = await supabase
                      .from('multiplayer_game')
                      .update({
                        'status': 'started',
                      })
                      .eq('id', gameId)
                      .select()
                      .single();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiplayerGameMainScreen(
                        prompt: gameSettings['prompt'],
                        gameId: gameId,
                      ),
                    ),
                  );
                } else {
                  print('cannot start with a single drawer');
                }
              },
              child: Text('Start Game', style: TextStyle(fontSize: 20)),
            ),
          ],
        )),
      );
    } else
      return Scaffold(
        appBar: AppBar(title: Text('Matchmaking')),
        body: Center(
            child: Text('Listing the rooms', style: TextStyle(fontSize: 20))),
      );
  }
}
