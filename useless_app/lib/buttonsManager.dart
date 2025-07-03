import 'package:flutter/material.dart';
import 'ControlCounters.dart';
import 'Login.dart';


class ButtonsManager {
  static void onLeaderboardTap(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    showDialog(
      context: context,
      builder: (context) {
        final List<Map<String, dynamic>> leaderboard = [
          {'name': 'Gino', 'score': 1200},
          {'name': 'Paolo', 'score': 1150},
          {'name': 'Anna', 'score': 1100},
          {'name': 'Luca', 'score': 1050},
          {'name': 'Sara', 'score': 990},
          {'name': 'Marta', 'score': 950},
          {'name': 'Gianni', 'score': 900},
          {'name': 'Elena', 'score': 870},
          {'name': 'Marco', 'score': 850},
          {'name': 'Piero', 'score': 800},
          {'name': 'Franco', 'score': 780},
          {'name': 'Simone', 'score': 760},
          {'name': 'Valeria', 'score': 740},
          {'name': 'Davide', 'score': 720},
          {'name': 'Alessia', 'score': 700},
          {'name': 'Roberto', 'score': 680},
          {'name': 'Chiara', 'score': 660},
          {'name': 'Stefano', 'score': 640},
          {'name': 'Irene', 'score': 620},
          {'name': 'Fabio', 'score': 600},
          {'name': 'Laura', 'score': 580},
          {'name': 'Matteo', 'score': 560},
          {'name': 'Silvia', 'score': 540},
          {'name': 'Antonio', 'score': 520},
          {'name': 'Giulia', 'score': 500},
          {'name': 'Federico', 'score': 480},
          {'name': 'Martina', 'score': 460},
          {'name': 'Nicola', 'score': 440},
          {'name': 'Alberto', 'score': 420},
          {'name': 'Veronica', 'score': 400},
        ];
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
          insetPadding: EdgeInsets.only(
            left: mediaQuery.size.width * 0.05,
            right: mediaQuery.size.width * 0.05,
            top: 0,
            bottom: 0,
          ),
          child: Column(
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