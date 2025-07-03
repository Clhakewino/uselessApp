import 'package:flutter/material.dart';
import 'Login.dart';

/// Tutte le costanti per il confronto con counter per spawnare la prima volta gli elementi a schermo.
class ControlCounters {
  static const int minCounterStar = 150;           // Stelle nel cielo
  static const int minCounterPrato = 250;          // Prati
  static const int minCounterFiori = 400;          // Fiori
  static const int minCounterAlbero = 600;         // Albero animato
  static const int minCounterCastello = 850;      // Castello
  static const int minCounterLuna = 1050;          // Luna
  static const int minCounterNuvole = 1300;        // Nuvole
  static const int minCounterStellaCadente = 1500; // Stelle cadenti

  static void onLoginTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: LoginDialog(),
      ),
    );
  }
}