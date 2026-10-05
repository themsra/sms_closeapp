import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entry.dart';

class LogService {
  static const String _logsKey = 'sms_logs';
  static const int _maxLogs = 20;

  Future<List<LogEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_logsKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map(
            (item) => LogEntry.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addLog({
    required String sender,
    required String message,
  }) async {
    final logs = await getLogs();

    logs.insert(
      0,
      LogEntry(
        sender: sender,
        message: message,
        time: DateTime.now(),
      ),
    );

    if (logs.length > _maxLogs) {
      logs.removeRange(_maxLogs, logs.length);
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _logsKey,
      jsonEncode(
        logs.map((log) => log.toJson()).toList(),
      ),
    );
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsKey);
  }
}