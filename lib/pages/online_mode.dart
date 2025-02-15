import 'dart:async';

import 'package:drawiloo/pages/game_screen.dart';
import 'package:drawiloo/services/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineModeMatchMakingScreen extends StatefulWidget {
  @override
  _OnlineModeMatchMakingScreenState createState() =>
      _OnlineModeMatchMakingScreenState();
}

class _OnlineModeMatchMakingScreenState
    extends State<OnlineModeMatchMakingScreen> {
  String status = "Looking for an opponent...";
  final SupabaseClient supabase = Supabase.instance.client;
  StreamSubscription? matchSubscription;

  @override
  void initState() {
    super.initState();
    findOpponent();
  }

  @override
  void dispose() {
    matchSubscription?.cancel();
    super.dispose();
  }

  void findOpponent() async {
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

    final availableMatch = await supabase
        .from('matchmaking')
        .select('*')
        .gte('points', userPoints - 1)
        .lte('points', userPoints + 1)
        .isFilter('opponent_id', null)
        .order('points')
        .limit(1)
        .maybeSingle();

    if (availableMatch != null && availableMatch.isNotEmpty) {
      String randomPrompt = await ApiService.fetchRecommendedLabel();
      final res = await supabase.from('matchmaking').update({
        'opponent_id': user?.id,
        'opponent_points': userPoints,
        'prompt': randomPrompt
      }).eq('id', availableMatch['id']);

      print(res);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            opponentId: availableMatch['user_id'] as String,
            prompt: randomPrompt,
            gameId: availableMatch['id'],
          ),
        ),
      );
    } else {
      final scdRes = await supabase
          .from('matchmaking')
          .insert({
            'user_id': user?.id,
            'points': userPoints,
            'opponent_id': null,
            'opponent_points': null,
            'prompt': null
          })
          .select('id')
          .single();

      print(scdRes);

      matchSubscription = supabase
          .from('matchmaking')
          .stream(primaryKey: ['id'])
          .eq('id', scdRes['id'])
          .listen((data) {
            if (data.isNotEmpty && data[0]['opponent_id'] != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    opponentId: data[0]['opponent_id'] as String,
                    prompt: data[0]['prompt'],
                    gameId: data[0]['id'],
                  ),
                ),
              );
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matchmaking')),
      body: Center(child: Text(status, style: TextStyle(fontSize: 20))),
    );
  }
}
