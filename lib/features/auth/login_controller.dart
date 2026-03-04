class LoginController {
  final Map<String, String> users = {
    "atmint": "123",
    "gilang": "ohh",
    "Biji": "Kocak",
  };

  // Fungsi ini mengembalikan nilai true jika login valid, false jika tidak
  bool login(String username, String password) {
    if (users.containsKey(username)) {
      return users[username] == password;
    }
    return false;
  }
}
