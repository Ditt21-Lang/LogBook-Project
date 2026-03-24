import 'package:logbook_app_001/features/auth/models/app_user.dart';

class LoginController {
  final Map<String, Map<String, String>> users = {
    "atmint": {
      "password": "123",
      "role": "Ketua",
      "teamId": "team_alpha",
    },
    "gilang": {
      "password": "ohh",
      "role": "Asisten",
      "teamId": "team_alpha",
    },
    "Biji": {
      "password": "kocak",
      "role": "Anggota",
      "teamId": "team_alpha",
    },
    "bujang": {
      "password": "123", 
      "role": "Ketua", 
      "teamId": "team_beta",
    },
    "rani": {
      "password": "123", 
      "role": "Anggota", 
      "teamId": "team_beta"
    },
  };

  AppUser? login(String username, String password){
    username.trim();

    final data = users[username];
    if (data == null) return null;
    if (data["password"] != password) return null;

    return AppUser(
      username: username, 
      role: data["role"] ?? "Anggota", 
      teamId: data["teamId"] ?? "no_team"
    );
  }
}
