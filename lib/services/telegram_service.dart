import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class TelegramService {
  static Future<bool> sendMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();

    final savedToken = (prefs.getString('bot_token') ?? '').trim();
    final savedChatId = (prefs.getString('chat_id') ?? '').trim();

    final botToken = savedToken.isNotEmpty ? savedToken : Config.botToken.trim();
    final chatId = savedChatId.isNotEmpty ? savedChatId : Config.chatId.trim();

    if (botToken.isEmpty || chatId.isEmpty) return false;

    final uri = Uri.parse(
      'https://api.telegram.org/bot$botToken/sendMessage',
    );

    try {
      final response = await http.post(
        uri,
        body: <String, String>{
          'chat_id': chatId,
          'text': message,
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
