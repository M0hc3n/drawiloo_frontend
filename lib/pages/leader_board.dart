import 'package:drawiloo/main.dart';
import 'package:flutter/material.dart';
import 'package:drawiloo/widgets/top_bar/Custom_appbar.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardData = [
      {'rank': 1, 'name': 'Imad', 'xp': '195 XP'},
      {'rank': 2, 'name': 'Karim', 'xp': '165 XP'},
      {'rank': 3, 'name': 'Zaki', 'xp': '144 XP'},
      {'rank': 4, 'name': 'Dahmane', 'xp': '127 XP'},
      {'rank': 5, 'name': 'Boubaltou', 'xp': '120 XP'},
    ];

    return Scaffold(
      appBar: const CustomAppBar(
        goldCount: 12,
        silverCount: 6,
        purpleCount: 2,
      ),
      body: Column(
        children: [
          // Date Header
          Padding(
            padding: const EdgeInsets.all(16.0),
          ),
          // Trophy Icon
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
          ),
          // Podium Section (Replaced with PNG image)
          SizedBox(
            height: 280, // Increased height for a larger image
            child: Image.asset(
              'image/Podium.png', // Path to your PNG image
              fit: BoxFit
                  .contain, // Adjusts the image while maintaining aspect ratio
            ),
          ),

          // List of other players
          Expanded(
            child: ListView.builder(
              itemCount: 2, // Only showing 4th and 5th place
              itemBuilder: (context, index) {
                final player =
                    leaderboardData[index + 3]; // Starting from 4th place
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${player['rank']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.deepPurple[100],
                        child: Text(
                          (player['name'] != null &&
                                  player['name'].toString().isNotEmpty)
                              ? player['name'].toString().substring(0, 1)
                              : '?', // Default to '?' if name is null or empty
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        player['name']?.toString() ??
                            'Unknown', // Ensure it's a string
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        player['xp']?.toString() ??
                            '0 XP', // Ensure it's a string
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavButton(
                  icon: 'assets/image/play.png',
                  label: 'Play',
                  onPressed: () {
                    // Navigate to MainMenu
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainMenu()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildNavButton(
                  icon: 'assets/image/cup.png',
                  label: 'Lead',
                  onPressed: () {
                    // Stay on the Leaderboard screen (no navigation needed)
                  },
                  isSelected: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFF72CB25) : Colors.black,
            width: 2,
          ),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      icon: Image.asset(
        icon,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
