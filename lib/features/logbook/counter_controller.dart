import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum HistoryType { increment, decrement, reset }

class HistoryItem {
  final String username;
  final HistoryType type;
  final int value;
  final DateTime time;

  HistoryItem({
    required this.username,
    required this.type,
    required this.value,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'type': type.index,
      'value': value,
      'time': time.toIso8601String(),
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      username: json['username'],
      type: HistoryType.values[json['type']],
      value: json['value'],
      time: DateTime.parse(json['time']),
    );
  }
}

class CounterController {
  int _counter = 0; //variabel private
  final List<HistoryItem> _history = [];

  int get value => _counter; // Getter untuk akses data
  List<HistoryItem> get history => _history;
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  void incrementBy(String currentUsername, int value) {
    _counter += value;
    _history.add(
      HistoryItem(
        username: currentUsername,
        type: HistoryType.increment,
        value: value,
        time: DateTime.now(),
      ),
    );
    saveCounter();
    saveHistory();
  }

  void decrementBy(String currentUsername, int value) {
    _counter -= value;
    _history.add(
      HistoryItem(
        username: currentUsername,
        type: HistoryType.decrement,
        value: value,
        time: DateTime.now(),
      ),
    );
    saveCounter();
    saveHistory();
  }

  void reset(String currentUsername) {
    _counter = 0;
    _history.add(
      HistoryItem(
        username: currentUsername,
        type: HistoryType.reset,
        value: value,
        time: DateTime.now(),
      ),
    );
    saveCounter();
    saveHistory();
  }

  Future<void> saveCounter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("counter_value", _counter);
  }

  Future<void> loadCounter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt("counter_value") ?? 0;
  }

  Future<void> saveLastInput(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_input", value);
  }

  Future<String> loadLastInput() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("last_input") ?? "";
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final historyJson = _history
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList('history_list', historyJson);
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final historyJson = prefs.getStringList('history_list');

    if (historyJson != null) {
      _history.clear();
      _history.addAll(
        historyJson.map((item) => HistoryItem.fromJson(jsonDecode(item))),
      );
    }
  }
}
