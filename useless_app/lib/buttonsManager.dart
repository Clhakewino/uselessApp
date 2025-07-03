import 'package:flutter/material.dart';
import 'ControlCounters.dart';
import 'Login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ButtonsManager {
  static Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('counter', descending: true)
        .limit(30)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? doc.id.substring(0, 8), // fallback se manca il nome
        'score': data['counter'] ?? 0,
      };
    }).toList();
  }

  static void onLeaderboardTap(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
          insetPadding: EdgeInsets.only(
            left: mediaQuery.size.width * 0.05,
            right: mediaQuery.size.width * 0.05,
            top: 0,
            bottom: 0,
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchLeaderboard(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                );
              }
              final leaderboard = snapshot.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700), // oro
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white54),
                  SizedBox(
                    width: mediaQuery.size.width * 0.85,
                    height: mediaQuery.size.height * 0.7,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: leaderboard.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white24),
                      itemBuilder: (context, index) {
                        final entry = leaderboard[index];
                        Color? leadingColor;
                        if (index == 0) {
                          leadingColor = const Color(0xFFFFD700); // oro
                        } else if (index == 1) {
                          leadingColor = const Color(0xFFC0C0C0); // argento
                        } else if (index == 2) {
                          leadingColor = const Color(0xFFCD7F32); // bronzo
                        } else {
                          leadingColor = Colors.white;
                        }
                        return ListTile(
                          leading: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: leadingColor,
                            ),
                          ),
                          title: Text(
                            entry['name'],
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          trailing: Text(
                            entry['score'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static void onLoginTap(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permette di chiudere tappando fuori
      builder: (context) => LoginDialog(),
    );
  }
}