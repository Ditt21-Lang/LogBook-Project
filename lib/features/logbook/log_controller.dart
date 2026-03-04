import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/services/mongo_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'models/log_model.dart';
import '../../helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<List<LogModel>> filteredLogs =
      ValueNotifier<List<LogModel>>([]);

  static const String _storageKey = 'user_logs_data';

  List<LogModel> get logs => logsNotifier.value;

  LogController() {
    loadFromCloud();
  }

  // ===============================
  //  ADD LOG (Cloud + Local)
  // ===============================
  Future<void> addLog(
      String title, String desc, LogCategory category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category,
    );

    try {
      await MongoService().insertLog(newLog);

      final updatedList = [...logsNotifier.value, newLog];
      logsNotifier.value = updatedList;
      filteredLogs.value = updatedList;

      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Tambah Log '${title}'",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal Add - $e",
        level: 1,
      );
    }
  }

  // ===============================
  //  UPDATE LOG
  // ===============================
  Future<void> updateLog(
      LogModel oldLog,
      String newTitle,
      String newDesc,
      LogCategory newCategory) async {

    final updatedLog = oldLog.copyWith(
      title: newTitle,
      description: newDesc,
      category: newCategory,
      date: DateTime.now(),
    );

    try {
      await MongoService().updateLog(updatedLog);

      final updatedList = logsNotifier.value.map((log) {
        return log.id == oldLog.id ? updatedLog : log;
      }).toList();

      logsNotifier.value = updatedList;
      filteredLogs.value = updatedList;

      await saveToDisk();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal Update - $e",
        level: 1,
      );
    }
  }

  // ===============================
  //  DELETE LOG
  // ===============================
  Future<void> removeLog(LogModel log) async {
    try {
      if (log.id == null) {
        throw Exception("ID tidak ditemukan");
      }

      await MongoService().deleteLog(log.id!);

      final updatedList =
          logsNotifier.value.where((l) => l.id != log.id).toList();

      logsNotifier.value = updatedList;
      filteredLogs.value = updatedList;

      await saveToDisk();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal Delete - $e",
        level: 1,
      );
    }
  }

  // ===============================
  //  SEARCH
  // ===============================
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value.where((log) {
        return log.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // ===============================
  //  SAVE TO LOCAL CACHE
  // ===============================
  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );

    await prefs.setString(_storageKey, encodedData);
  }

  // ===============================
  //  LOAD FROM CLOUD
  // ===============================
  Future<void> loadFromCloud() async {
    try {
      final cloudData = await MongoService().getLogs();

      logsNotifier.value = cloudData;
      filteredLogs.value = cloudData;

      await saveToDisk();
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Cloud gagal, load local cache",
        level: 2,
      );

      await loadFromDisk();
    }
  }

  // ===============================
  //  LOAD FROM LOCAL CACHE
  // ===============================
  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final decoded = jsonDecode(data);
      final loadedLogs =
          decoded.map<LogModel>((e) => LogModel.fromMap(e)).toList();

      logsNotifier.value = loadedLogs;
      filteredLogs.value = loadedLogs;
    }
  }
}