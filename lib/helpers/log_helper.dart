import 'dart:developer' as dev;

import 'package:intl/intl.dart'; // Tetap kita gunakan untuk presisi waktu
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
   String message, {
   String source = "Unknown", // Menandakan file/proses asal
   int level = 2,
   }) async {
     // 1. Filter Konfigurasi (ENV)
     final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
   final String muteList = dotenv.env['LOG_MUTE'] ?? '';

   if (level > configLevel) return;
   if (muteList.split(',').contains(source)) return;

 try {
  // 2. Format Waktu untuk Konsol
  String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
  String label = _getLabel(level);
  String color = _getColor(level);

  // 3. Output ke VS Code Debug Console (Non-blocking)
  dev.log(message, name: source, time: DateTime.now(), level: level * 100);

  // 4. Output ke Terminal (Agar Bapak bisa lihat di PC saat flutter run)
  // Format: [14:30:05] [INFO] [log_view.dart] -> Database Terhubung
  } catch (e) {
    dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
  }

  }

 static String _getLabel(int level) {
  switch (level) {
  case 1:
    return "ERROR";
  case 2:
    return "INFO";
  case 3:
    return "VERBOSE";
  default:
    return "LOG";
  }
 }

 static String _getColor(int level) {
  switch (level) {
  case 1:
    return '\x1B[31m'; // Merah
  case 2:
    return '\x1B[32m'; // Hijau
  case 3:
    return '\x1B[34m'; // Biru
  default:
    return '\x1B[0m';
  }
 }

  static String formatRelativeTime(DateTime dateTime){
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60){
      return "${difference.inSeconds} detik yang lalu";
    } else if (difference.inMinutes < 60){
      return "${difference.inMinutes} menit yang lalu";
    } else if (difference.inHours < 24){
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inDays < 7){
      return "${difference.inDays} haris yang lalu";
    } else {
      return DateFormat("dd MM yyyy", "id_ID").format(dateTime);
    }
  }
}