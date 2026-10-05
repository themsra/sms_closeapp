import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';

class TelegramFileService {
  Future<bool> sendFile(
    File file, {
    String? caption,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('bot_token') ?? Config.botToken).trim();
    final chatId = (prefs.getString('chat_id') ?? Config.chatId).trim();

    if (token.isEmpty || chatId.isEmpty) return false;
    if (!await file.exists()) return false;

    final uri = Uri.parse(
      'https://api.telegram.org/bot$token/sendDocument',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['chat_id'] = chatId
      ..files.add(
        await http.MultipartFile.fromPath(
          'document',
          file.path,
        ),
      );

    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }

    try {
      final response = await request.send();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
