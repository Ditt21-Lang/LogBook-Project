import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart' as hive;

import 'package:logbook_app_001/services/access_control_services.dart';
import 'package:logbook_app_001/services/mongo_services.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<List<LogModel>> filteredLogs =
      ValueNotifier<List<LogModel>>([]);

  List<LogModel> get logs => logsNotifier.value;

  final hive.Box<LogModel> _myBox = hive.Hive.box<LogModel>('offline_logs');
  final hive.Box _opsBox = hive.Hive.box('pending_ops');

  LogController();

  List<Map<String, dynamic>> _getPendingOps() {
    final raw = (_opsBox.get('items', defaultValue: <dynamic>[]) as List);
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _setPendingOps(List<Map<String, dynamic>> ops) async {
    await _opsBox.put('items', ops);
  }

  Future<void> _enqueueOp(Map<String, dynamic> op) async {
    final ops = _getPendingOps();
    ops.add(op);
    await _setPendingOps(ops);
  }

  Map<String, dynamic> _toQueueData(LogModel log) {
    return {
      'id': log.id,
      'title': log.title,
      'description': log.description,
      'date': log.date.toIso8601String(),
      'category': log.category.name,
      'authorId': log.authorId,
      'teamId': log.teamId,
    };
  }

  LogModel _fromQueueData(Map<String, dynamic> data) {
    return LogModel(
      id: data['id']?.toString(),
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      category: LogCategory.values.firstWhere(
        (e) => e.name == data['category']?.toString(),
        orElse: () => LogCategory.pribadi,
      ),
      authorId: data['authorId']?.toString() ?? 'unknown_user',
      teamId: data['teamId']?.toString() ?? 'no_team',
    );
  }

  Future<void> _processPendingOps() async {
    final ops = _getPendingOps();
    int i = 0;

    while (i < ops.length) {
      final op = ops[i];
      try {
        bool handled = true;
        switch (op['type']) {
          case 'insert':
            await MongoService().insertLog(
              _fromQueueData(Map<String, dynamic>.from(op['data'] as Map)),
            );
            break;
          case 'update':
            await MongoService().updateLog(
              _fromQueueData(Map<String, dynamic>.from(op['data'] as Map)),
            );
            break;
          case 'delete':
            await MongoService().deleteLog(
              ObjectId.fromHexString(op['id'].toString()),
            );
            break;
          default:
            handled = false;
            break;
        }
        if (handled) {
          ops.removeAt(i);
        } else {
          i++;
        }
      } catch (_) {
        i++; 
      }
    }

    await _setPendingOps(ops);
  }

  // ===============================
  // LOAD DATA (OFFLINE FIRST)
  // ===============================
  Future<bool> loadLogs() async {
    // 1. Load dari Hive (instan)
    final localData = _myBox.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;
    try {

      await _processPendingOps();

      if (_getPendingOps().isNotEmpty) {
        await LogHelper.writeLog(
          "SYNC: Pending ops masih ada, tunda overwrite dari cloud",
          level: 2,
        );
        return false;
      }

      // 2. Sync dari MongoDB
      final cloudData = await MongoService().getLogs();

      // 3. Reconcile: hapus data lokal yang sudah tidak ada di cloud
      final cloudIds = cloudData
          .map((log) => log.id)
          .whereType<String>()
          .toSet();
      final localKeys = _myBox.keys.map((key) => key.toString()).toList();
      for (final key in localKeys) {
        if (!cloudIds.contains(key)) {
          await _myBox.delete(key);
        }
      }

      // 4. Upsert data cloud ke Hive
      for (final log in cloudData) {
        await _myBox.put(log.id, log);
      }

      logsNotifier.value = cloudData;
      filteredLogs.value = cloudData;

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal ($e)",
        level: 2,
      );
      return false;
    }
  }

  // ===============================
  // ADD LOG
  // ===============================
  Future<void> addLog(
    String title,
    String desc,
    LogCategory category, {
    required String authorId,
    required String teamId,
  }) async {
    final newLog = LogModel(
      id: ObjectId().toHexString(),
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category,
      authorId: authorId,
      teamId: teamId,
    );

    try {
      // 1. Simpan ke Hive (Local First) - Gunakan id sebagai key
      await _myBox.put(newLog.id, newLog);

      // 2. Update UI (Instant)
      final updatedList = [...logsNotifier.value, newLog];
      logsNotifier.value = updatedList;
      filteredLogs.value = updatedList;

      await LogHelper.writeLog(
        "LOCAL SUCCESS: Tambah Log '$title' di Hive",
        source: "log_controller.dart",
      );

      // 3. Simpan ke Mongo (Sync ke Cloud)
      try {
        await MongoService().insertLog(newLog);
        await LogHelper.writeLog("CLOUD SUCCESS: Data Sync to Atlas", source: "log_controller.dart");
      } catch (e) {
        await _enqueueOp({
          'type': 'insert',
          'data': _toQueueData(newLog),
          'ts': DateTime.now().toIso8601String(),
        });
        await LogHelper.writeLog("CLOUD ERROR: Sync failed, saved locally: $e", level: 1);
      }
    } catch (e) {
      await LogHelper.writeLog(
        "FATAL ERROR: Gagal Add - $e",
        level: 1,
      );
      rethrow;
    }
  }

  // ===============================
  // UPDATE LOG
  // ===============================
  Future<bool> updateLog(
    LogModel oldLog,
    String newTitle,
    String newDesc,
    LogCategory newCategory,
    int index,
    String userRole,
    String userId,
  ) async {
    // Check perizinan
    if (!AccessControlServices.canPerform(
      userRole,
      'update',
      isOwner: oldLog.authorId == userId,
    )) {
      await LogHelper.writeLog(
        "Security Breach: Unauthorized update attempt",
        level: 1,
      );
      return false;
    }

    final updatedLog = oldLog.copyWith(
      title: newTitle,
      description: newDesc,
      category: newCategory,
      date: DateTime.now(),
    );

    try {
      // 1. Update Hive (Gunakan id sebagai key)
      await _myBox.put(updatedLog.id, updatedLog);

      // 2. Update UI
      final updatedList = logsNotifier.value.map((log) {
        return log.id == oldLog.id ? updatedLog : log;
      }).toList();

      logsNotifier.value = updatedList;
      
      // Update filtered list juga jika sedang mencari
      final updatedFilteredList = filteredLogs.value.map((log) {
        return log.id == oldLog.id ? updatedLog : log;
      }).toList();
      filteredLogs.value = updatedFilteredList;

      // 3. Sync ke Mongo
      try {
        await MongoService().updateLog(updatedLog);
      } catch (e) {
        await _enqueueOp({
          'type': 'update',
          'data': _toQueueData(updatedLog),
          'ts': DateTime.now().toIso8601String(),
        });
        await LogHelper.writeLog("CLOUD ERROR: Update sync failed: $e", level: 1);
      }
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal Update - $e",
        level: 1,
      );
      return false;
    }
  }

  // ===============================
  // DELETE LOG
  // ===============================
  Future<void> removeLog(
    LogModel log,
    int index,
    String userRole,
    String userId,
  ) async {
    if (!AccessControlServices.canPerform(
      userRole,
      'delete',
      isOwner: log.authorId == userId,
    )) {
      await LogHelper.writeLog(
        "Security Breach: Unauthorized delete attempt",
        level: 1,
      );
      return;
    }

    try {
      // Try hapus di cloud jika memungkinkan (online permanent delete)
      if (log.id != null) {
        await MongoService().deleteLog(ObjectId.fromHexString(log.id!));
      }
    } catch (e) {
      await LogHelper.writeLog(
        "DELETE OFFLINE FALLBACK (local only): $e",
        level: 2,
      );
    }

    // Offline/online sama-sama hapus lokal agar item langsung hilang dari UI.
    // Jika delete cloud gagal (offline), item akan muncul lagi saat sync online dari cloud.
    await _myBox.delete(log.id);

    final updatedList = logsNotifier.value.where((l) => l.id != log.id).toList();
    logsNotifier.value = updatedList;

    final updatedFilteredList = filteredLogs.value.where((l) => l.id != log.id).toList();
    filteredLogs.value = updatedFilteredList;
  }

  // ===============================
  // SEARCH
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
}
