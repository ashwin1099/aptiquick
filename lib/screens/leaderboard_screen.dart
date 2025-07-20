import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  final List<Map<String, dynamic>> players = const [
    {'name': 'Alice', 'score': 120},
    {'name': 'Bob', 'score': 115},
    {'name': 'Charlie', 'score': 110},
    {'name': 'David', 'score': 105},
    {'name': 'Eve', 'score': 100},
  ];

  @override
  Widget build(BuildContext context) {
    // Sort players descending by score (just to be safe)
    final sortedPlayers = List<Map<String, dynamic>>.from(players)
      ..sort((a, b) => b['score'].compareTo(a['score']));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sortedPlayers.length,
        itemBuilder: (context, index) {
          final player = sortedPlayers[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(player['name'] ?? 'Unknown'),
              trailing: Text('Score: ${player['score']}'),
            ),
          );
        },
      ),
    );
  }
}
